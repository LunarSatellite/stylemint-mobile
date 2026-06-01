import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/social/recommendations/data/models/recommendation_dto.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class RecommendationsRemoteDataSource {
  RecommendationsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET /v1/recommendation-requests/community
  Future<PagedResult<RecommendationRequestDto>> getRequests({
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/recommendation-requests/community',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => RecommendationRequestDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return PagedResult(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
      pageSize: data['pageSize'] as int? ?? limit,
      nextCursor: data['nextCursor'] as String?,
      previousCursor: data['previousCursor'] as String?,
      hasMore: data['hasMore'] as bool? ?? false,
    );
  }

  /// GET /v1/recommendation-requests/{requestId}/replies
  Future<List<RecommendationReplyDto>> getThread(String requestId) async {
    final response = await apiClient.get(
      '/v1/recommendation-requests/$requestId/replies',
    );

    final data = response as Map<String, dynamic>;
    final replies = (data['replies'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => RecommendationReplyDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return replies;
  }

  /// POST /v1/recommendation-requests
  Future<RecommendationRequestDto> createRequest({
    required String question,
    String? context,
    List<String>? taggedProducts,
    List<String>? categories,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/recommendation-requests',
      data: {
        'question': question,
        if (context != null) 'context': context,
        if (taggedProducts != null) 'taggedProducts': taggedProducts,
        if (categories != null) 'categories': categories,
      },
      options: _idempotent(idempotencyKey),
    );
    return RecommendationRequestDto.fromJson(
      response as Map<String, dynamic>,
    );
  }

  /// POST /v1/recommendation-replies
  Future<RecommendationReplyDto> replyToRequest({
    required String requestId,
    required String content,
    String? suggestedProduct,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/recommendation-replies',
      data: {
        'requestId': requestId,
        'content': content,
        if (suggestedProduct != null) 'suggestedProduct': suggestedProduct,
      },
      options: _idempotent(idempotencyKey),
    );
    return RecommendationReplyDto.fromJson(
      response as Map<String, dynamic>,
    );
  }

  /// POST /v1/recommendation-votes
  Future<void> likeReply(String replyId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/recommendation-votes',
      data: {'replyId': replyId},
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
