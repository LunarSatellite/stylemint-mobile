import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/data/models/review_dto.dart';

class ReviewsRemoteDataSource {
  ReviewsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/v1/customer/products/{productId}/reviews`
  Future<Map<String, dynamic>> getProductReviews(
    String productId, {
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/customer/products/$productId/reviews',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  // TODO: No review-summary endpoint in Swagger — aggregate from `/v1/customer/products/{productId}/reviews`
  Future<ReviewSummaryDto> getReviewSummary(String productId) async {
    final response = await apiClient.get(
      '/v1/customer/products/$productId/reviews',
    );
    return ReviewSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/customer/products/{productId}/reviews`
  Future<ReviewDto> submitReview(
    String productId,
    int rating,
    String comment,
    String idempotencyKey, {
    List<String>? imagePaths,
  }) async {
    final response = await apiClient.post(
      '/v1/customer/products/$productId/reviews',
      data: {
        'rating': rating,
        'comment': comment,
        if (imagePaths != null && imagePaths.isNotEmpty)
          'imagePaths': imagePaths,
      },
      options: _idempotent(idempotencyKey),
    );
    return ReviewDto.fromJson(response as Map<String, dynamic>);
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
