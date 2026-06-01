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
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// POST `/v1/posts` — create a new post.
  Future<FeedPostDto> createPost({
    required String content,
    List<String>? imagePaths,
    List<String>? taggedProductIds,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/posts',
      data: {
        'content': content,
        if (imagePaths != null && imagePaths.isNotEmpty)
          'imagePaths': imagePaths,
        if (taggedProductIds != null && taggedProductIds.isNotEmpty)
          'taggedProductIds': taggedProductIds,
      },
      options: _idempotent(idempotencyKey),
    );
    return FeedPostDto.fromJson(response as Map<String, dynamic>);
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
      data: {'content': content},
      options: _idempotent(idempotencyKey),
    );
    return FeedCommentDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET `/v1/posts/{postId}/comments` — cursor-paginated.
  Future<Map<String, dynamic>> getComments(
    String postId, {
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/posts/$postId/comments',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// TODO(swagger): No share-post endpoint found — possible future `/v1/posts/{postId}/share`
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
