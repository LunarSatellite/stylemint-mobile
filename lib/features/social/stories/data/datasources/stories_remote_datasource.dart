import 'dart:io';

import 'package:dio/dio.dart'
    show DioMediaType, FormData, MultipartFile, Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/data/models/story_dto.dart';
import 'package:uuid/uuid.dart';

class StoriesRemoteDataSource {
  StoriesRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// The image staging endpoint's own limit (`AvatarUploadService`).
  static const int maxPhotoBytes = 5 * 1024 * 1024;

  static const _videoExtensions = {'mp4', 'mov', 'm4v', '3gp', 'webm', 'mkv'};

  /// Whether [path] is a video, judged by its extension. The repository
  /// contract only carries a file path, and the picker keeps the extension.
  static bool isVideoPath(String path) =>
      _videoExtensions.contains(_extensionOf(path));

  /// GET `/v1/stories` — every active story, newest first, as a cursor page
  /// (`{ items, nextCursor, pageSize, totalCount }`). Includes the caller's own
  /// stories (`hasWatched` is always true for those). Grouped here by author;
  /// group order follows the newest story, and each group plays oldest first.
  Future<List<StoryGroupDto>> getStoryGroups() async {
    final response = await apiClient.get(
      '/v1/stories',
      queryParameters: const {'pageSize': 100},
    );
    final data = response as Map<String, dynamic>;
    final stories = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (item) => StoryDto.fromStoryJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
    final storiesByUser = <String, List<StoryDto>>{};
    for (final story in stories) {
      storiesByUser.putIfAbsent(story.userId, () => <StoryDto>[]).add(story);
    }

    return storiesByUser.values
        .map((userStories) {
          final ordered = [...userStories]
            ..sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
          final first = ordered.first;
          return StoryGroupDto(
            userId: first.userId,
            userName: first.userName,
            userAvatarUrl: first.userAvatarUrl,
            stories: ordered,
            hasUnwatched: ordered.any((story) => !story.hasWatched),
          );
        })
        .toList(growable: false);
  }

  /// GET `/v1/stories/by-author/{authorAccountId}` — stories for a specific user.
  Future<List<StoryDto>> getStories(String userId) async {
    final response = await apiClient.get('/v1/stories/by-author/$userId');
    final list = response as List<dynamic>;
    final stories = list
        .map((e) => StoryDto.fromStoryJson(e as Map<String, dynamic>))
        .toList();
    stories.sort((a, b) => a.expiresAt.compareTo(b.expiresAt));
    return stories;
  }

  /// Posts a story in two calls, because `POST /v1/stories` takes a JSON body
  /// (`CreateStoryVm { mediaType, mediaUrl, thumbnailUrl?, caption?,
  /// durationSeconds? }`), not the file itself:
  ///
  /// 1. the picked file is staged and its CDN URL comes back;
  /// 2. the story is created pointing at that URL.
  ///
  /// The backend has no tagged products on stories, so [taggedProductIds] is
  /// accepted for the repository contract and not sent.
  Future<StoryDto> createStory({
    required String mediaFile,
    String? caption,
    List<String>? taggedProductIds,
    required String idempotencyKey,
  }) async {
    final isVideo = isVideoPath(mediaFile);
    final mediaUrl = await _uploadMedia(mediaFile, isVideo: isVideo);
    final trimmedCaption = caption?.trim();
    final response = await apiClient.post(
      '/v1/stories',
      data: {
        // StoryMediaType: Image = 1, Video = 2 (serialized as numbers).
        'mediaType': isVideo ? 2 : 1,
        'mediaUrl': mediaUrl,
        if (trimmedCaption != null && trimmedCaption.isNotEmpty)
          'caption': trimmedCaption,
      },
      options: _idempotent(idempotencyKey),
    );
    return StoryDto.fromStoryJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/stories/{storyId}/view`
  Future<void> viewStory(String storyId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/stories/$storyId/view',
      options: _idempotent(idempotencyKey),
    );
  }

  Future<void> deleteStory(String storyId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/stories/$storyId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// Stages the story file and returns its public URL.
  ///
  /// The SocialFeed module has no media endpoint of its own, so photos go
  /// through Identity's image staging upload (`POST /v1/customer/me/avatar`):
  /// it only stores the bytes and answers `{ url }` — the profile is not
  /// touched until a separate profile patch, which this never sends. It takes
  /// JPG or PNG up to 5 MB in a part named `file`. Nothing on the backend takes
  /// video bytes, so a video is refused here before anything is sent.
  Future<String> _uploadMedia(String path, {required bool isVideo}) async {
    if (isVideo) {
      // ignore: only_throw_errors
      throw const NetworkExceptions.validation(
        code: 'stories.video_unsupported',
        message: 'Video stories are not available yet. Share a photo instead.',
      );
    }

    // Checked first: a picked photo lives in a temp directory the OS may
    // reclaim, and `MultipartFile.fromFile` would otherwise fail with a
    // FileSystemException the repository can only call "unexpected".
    final file = File(path);
    if (!await file.exists()) {
      // ignore: only_throw_errors
      throw const NetworkExceptions.validation(
        code: 'stories.media_missing',
        message: 'That photo is no longer on this device. Pick it again.',
      );
    }
    if (await file.length() > maxPhotoBytes) {
      // ignore: only_throw_errors
      throw const NetworkExceptions.validation(
        code: 'stories.media_too_large',
        message: 'That photo is larger than 5 MB. Pick a smaller one.',
      );
    }

    final extension = _extensionOf(path);
    final isPng = extension == 'png';
    final upload = await apiClient.post(
      '/v1/customer/me/avatar',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          path,
          filename: 'story.${isPng ? 'png' : 'jpg'}',
          contentType: DioMediaType('image', isPng ? 'png' : 'jpeg'),
        ),
      }),
      options: _idempotent(const Uuid().v4()),
    );
    final url = upload is Map<String, dynamic> ? upload['url'] as String? : null;
    if (url == null || url.isEmpty) {
      // ignore: only_throw_errors
      throw const NetworkExceptions.unexpectedError();
    }
    return url;
  }

  static String _extensionOf(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
