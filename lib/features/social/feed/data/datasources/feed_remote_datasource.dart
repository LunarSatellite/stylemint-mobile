import 'dart:io';

import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/models/feed_post_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/models/post_media_upload_dto.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/entities/post_media.dart';

class FeedRemoteDataSource {
  FeedRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/v1/feed` — cursor-paginated feed.
  Future<Map<String, dynamic>> getFeed({
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/feed',
      queryParameters: {
        'pageSize': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// POST `/v1/posts` — create a post.
  ///
  /// Without [media] it is a Status post (`type: 1`), as before. With media
  /// it is a PhotoPost (`2`) or, for a single video, a VideoPost (`3`), and
  /// `media` carries `NewPostMediaInput` rows pointing at files already
  /// staged through [uploadPostMedia]. `widthPx`/`heightPx` must be positive
  /// (`PostMedia.Attach`), so an unknown size is sent as 1×1 rather than
  /// rejected — it only affects layout hints. [imagePaths] is a legacy
  /// parameter; local paths are never sent.
  Future<FeedPostDto> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
    List<UploadedPostMedia>? media,
    required String idempotencyKey,
  }) async {
    final attached = media ?? const <UploadedPostMedia>[];
    final isVideoPost = attached.length == 1 && attached.first.isVideo;
    final response = await apiClient.post(
      '/v1/posts',
      data: {
        'type': attached.isEmpty ? 1 : (isVideoPost ? 3 : 2),
        'visibility': 1,
        'body': content,
        if (attached.isNotEmpty)
          'media': [
            for (var i = 0; i < attached.length; i++)
              {
                'displayOrder': i,
                'mediaUrl': attached[i].url,
                'mediaContentType': attached[i].contentType,
                'widthPx': attached[i].width ?? 1,
                'heightPx': attached[i].height ?? 1,
                if (attached[i].isVideo && attached[i].durationSeconds != null)
                  'durationSeconds': attached[i].durationSeconds,
              },
          ],
        if (taggedProductIds != null && taggedProductIds.isNotEmpty)
          'attachments': [
            for (var i = 0; i < taggedProductIds.length; i++)
              {
                'kind': 1,
                'referenceId': taggedProductIds[i],
                'displayOrder': i,
              },
          ],
      },
      options: _idempotent(idempotencyKey),
    );
    return FeedPostDto.fromPostJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/social/media` — stages one photo or video for a post
  /// (multipart part `file`) and returns its public URL and size metadata.
  /// The server judges the type by the bytes; the file name only gives it a
  /// sensible extension. [onProgress] reports bytes sent (Dio
  /// `onSendProgress`).
  ///
  /// Size limits are checked here first so an oversized pick fails at once
  /// with a clear message instead of after a long upload (or at the proxy).
  Future<PostMediaUploadDto> uploadPostMedia({
    required String path,
    required PostMediaKind kind,
    required String idempotencyKey,
    void Function(int sent, int total)? onProgress,
  }) async {
    final isVideo = kind == PostMediaKind.video;
    final file = File(path);
    // A pick lives in a temp directory the OS may reclaim; say so plainly
    // rather than surfacing a FileSystemException as "unexpected".
    if (!await file.exists()) {
      // ignore: only_throw_errors
      throw NetworkExceptions.validation(
        code: 'social_media.missing',
        message:
            'That ${isVideo ? 'video' : 'photo'} is no longer on this '
            'device. Remove it and pick it again.',
      );
    }
    final bytes = await file.length();
    final limit = isVideo
        ? PostMediaLimits.maxVideoBytes
        : PostMediaLimits.maxPhotoBytes;
    if (bytes > limit) {
      // ignore: only_throw_errors
      throw NetworkExceptions.validation(
        code: 'social_media.too_large',
        message: isVideo
            ? 'That video is over ${PostMediaLimits.maxVideoMegabytes} MB. '
                'Pick a shorter clip.'
            : 'That photo is larger than 10 MB. Pick a smaller one.',
      );
    }

    final response = await apiClient.postFile(
      '/v1/social/media',
      file: file,
      filename: _uploadName(path, isVideo: isVideo),
      options: _idempotent(idempotencyKey),
      onSendProgress: onProgress,
    );
    if (response is! Map<String, dynamic>) {
      // ignore: only_throw_errors
      throw const NetworkExceptions.unexpectedError();
    }
    final dto = PostMediaUploadDto.fromJson(response);
    if (dto.url.isEmpty) {
      // ignore: only_throw_errors
      throw const NetworkExceptions.unexpectedError();
    }
    return dto;
  }

  static String _uploadName(String path, {required bool isVideo}) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dot = name.lastIndexOf('.');
    final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
    if (isVideo) return 'video.${extension == 'mov' ? 'mov' : 'mp4'}';
    return switch (extension) {
      'png' => 'photo.png',
      'webp' => 'photo.webp',
      _ => 'photo.jpg',
    };
  }

  /// Backend `ReactionType.Like`.
  static const _reactionLike = 1;

  /// POST `/v1/reactions/posts/{postId}` with `{type: Like}`. The API binds
  /// the reaction type from the body; a bare POST was rejected with a 400
  /// before it reached the service, so no like was ever stored.
  Future<void> likePost(String postId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/reactions/posts/$postId',
      data: const {'type': _reactionLike},
      options: _idempotent(idempotencyKey),
    );
  }

  /// DELETE `/v1/reactions/posts/{postId}`
  Future<void> unlikePost(String postId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/reactions/posts/$postId',
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST `/v1/posts/{postId}/comments`
  Future<FeedCommentDto> commentOnPost(
    String postId,
    String content,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/posts/$postId/comments',
      data: {'body': content},
      options: _idempotent(idempotencyKey),
    );
    return FeedCommentDto.fromCommentJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/posts/{postId}/comments` — cursor-paginated.
  Future<Map<String, dynamic>> getComments(
    String postId, {
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/posts/$postId/comments',
      queryParameters: {'take': limit},
    );
    if (response is List<dynamic>) {
      return <String, dynamic>{
        'items': response,
        'totalCount': response.length,
        'pageSize': limit,
        'hasMore': false,
      };
    }
    return response as Map<String, dynamic>;
  }

  Future<void> sharePost(String postId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/posts/$postId/share',
      options: _idempotent(idempotencyKey),
    );
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
