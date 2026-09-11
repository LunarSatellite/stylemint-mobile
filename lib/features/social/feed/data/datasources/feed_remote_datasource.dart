import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/models/feed_post_dto.dart';

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

  /// POST `/v1/posts` — create a new status post.
  Future<FeedPostDto> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/posts',
      data: {
        'type': 1,
        'visibility': 1,
        'body': content,
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

  /// POST `/v1/reactions/posts/{postId}`
  Future<void> likePost(String postId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/reactions/posts/$postId',
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
