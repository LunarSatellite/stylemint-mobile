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
    final skip = int.tryParse(cursor ?? '') ?? 0;
    final response = await apiClient.get(
      '/v1/recommendation-requests/community',
      queryParameters: {'take': limit, 'skip': skip},
    );

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) => RecommendationRequestDto.fromBackendJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
    final hasMore = data['hasNext'] as bool? ?? false;
    return PagedResult(
      items: items,
      totalCount: data['totalCount'] as int? ?? items.length,
      pageSize: data['pageSize'] as int? ?? limit,
      nextCursor: hasMore ? '${skip + items.length}' : null,
      previousCursor: null,
      hasMore: hasMore,
    );
  }

  /// GET /v1/recommendation-requests/{requestId}/replies
  Future<List<RecommendationReplyDto>> getThread(String requestId) async {
    final response = await apiClient.get(
      '/v1/recommendation-requests/$requestId/replies',
      queryParameters: const {'take': 100},
    );

    final data = response as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map(
          (e) => RecommendationReplyDto.fromBackendJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList(growable: false);
  }

  /// POST /v1/recommendation-requests
  Future<RecommendationRequestDto> createRequest({
    required String question,
    String? context,
    List<String>? taggedProducts,
    List<String>? categories,
    required String idempotencyKey,
  }) async {
    final bodyParts = <String>[
      if (context?.trim().isNotEmpty == true) context!.trim(),
      if (categories?.isNotEmpty == true) 'Topic: ${categories!.join(', ')}',
    ];
    final response = await apiClient.post(
      '/v1/recommendation-requests',
      data: {
        'title': question,
        'body': bodyParts.join('\n\n'),
        'visibility': 3,
        'urgency': 1,
      },
      options: _idempotent(idempotencyKey),
    );
    return RecommendationRequestDto.fromBackendJson(
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
    final suggestion = suggestedProduct?.trim();
    final suggestionUri = suggestion == null ? null : Uri.tryParse(suggestion);
    final isExternalLink =
        suggestionUri != null &&
        (suggestionUri.scheme == 'http' || suggestionUri.scheme == 'https');
    final response = await apiClient.post(
      '/v1/recommendation-replies',
      data: {
        'requestId': requestId,
        'body': [
          content,
          if (suggestion?.isNotEmpty == true && !isExternalLink)
            'Suggested product: $suggestion',
        ].join('\n\n'),
        if (isExternalLink)
          'externalLinks': [
            {'url': suggestion, 'title': suggestion},
          ],
      },
      options: _idempotent(idempotencyKey),
    );
    return RecommendationReplyDto.fromBackendJson(
      response as Map<String, dynamic>,
    );
  }

  /// POST /v1/recommendation-votes
  Future<void> likeReply(String replyId, String idempotencyKey) async {
    await apiClient.post(
      '/v1/recommendation-votes',
      data: {'replyId': replyId, 'type': 1},
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
