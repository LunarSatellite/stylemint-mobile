import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/data/models/review_dto.dart';

class ReviewsRemoteDataSource {
  ReviewsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `/v1/customer/products/{id}/reviews` is POST-only (write); the real
  /// read endpoint is the public one.
  Future<Map<String, dynamic>> getProductReviews(
    String productId, {
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/public/products/$productId/reviews',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  // No dedicated summary endpoint exists, and there's no per-star
  // distribution anywhere in the backend — average/count already live on
  // the product itself (ProductDto.AverageRating/ReviewCount), so this
  // reads the product detail instead of a fabricated summary endpoint.
  // ratingDistribution stays empty until the backend adds real support.
  Future<ReviewSummaryDto> getReviewSummary(String productId) async {
    final response =
        await apiClient.get('/v1/public/products/$productId') as Map<String, dynamic>;
    return ReviewSummaryDto(
      averageRating: (response['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: response['reviewCount'] as int? ?? 0,
    );
  }

  /// POST `/v1/customer/products/{productId}/reviews`. `orderId` is
  /// required server-side as proof of purchase; `kind` is always Written
  /// (0) here — Reel-review submission is a separate, still-unbuilt path
  /// (see `RateReviewSheet`'s ponytail note). `imagePaths` are local file
  /// paths only — there's no upload endpoint yet (skipped, needs storage
  /// infra), so images are picked for local preview but not sent.
  Future<Map<String, dynamic>> submitReview(
    String productId,
    String orderId,
    int rating,
    String comment,
    String idempotencyKey, {
    List<String>? imagePaths,
  }) async {
    final response = await apiClient.post(
      '/v1/customer/products/$productId/reviews',
      data: {
        'orderId': orderId,
        'kind': 0,
        'rating': rating,
        'text': comment,
      },
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
