import 'package:dio/dio.dart' show FormData, MultipartFile, Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/data/models/story_dto.dart';

class StoriesRemoteDataSource {
  StoriesRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/v1/stories` — all story groups.
  Future<List<StoryGroupDto>> getStoryGroups() async {
    final response = await apiClient.get('/v1/stories');
    final list = response as List<dynamic>;
    return list
        .map((e) => StoryGroupDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// GET `/v1/stories/by-author/{authorAccountId}` — stories for a specific user.
  Future<List<StoryDto>> getStories(String userId) async {
    final response = await apiClient.get('/v1/stories/by-author/$userId');
    final list = response as List<dynamic>;
    return list
        .map((e) => StoryDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// POST `/v1/stories` — create story (multipart).
  Future<StoryDto> createStory({
    required String mediaFile,
    String? caption,
    List<String>? taggedProductIds,
    required String idempotencyKey,
  }) async {
    final formData = FormData.fromMap({
      'media': await MultipartFile.fromFile(mediaFile),
      if (caption != null) 'caption': caption,
      if (taggedProductIds != null && taggedProductIds.isNotEmpty)
        'taggedProductIds': taggedProductIds,
    });
    final response = await apiClient.post(
      '/v1/stories',
      data: formData,
      options: _idempotent(idempotencyKey),
    );
    return StoryDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/stories/{storyId}/view`
  Future<void> viewStory(String storyId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/stories/$storyId/view',
      options: _idempotent(idempotencyKey),
    );
  }

  /// TODO(swagger): No DELETE /v1/stories endpoint found — use POST /v1/posts/{postId}/archive instead or keep as-is.
  Future<void> deleteStory(String storyId, String idempotencyKey) async {
    await apiClient.authDelete(
      '/v1/stories/$storyId',
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
