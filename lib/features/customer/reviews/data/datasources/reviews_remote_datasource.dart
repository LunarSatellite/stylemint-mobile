import 'package:dio/dio.dart' show FormData, MultipartFile, Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/upload_filename.dart';
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
        'pageSize': limit,
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
        await apiClient.get('/v1/public/products/$productId')
            as Map<String, dynamic>;
    return ReviewSummaryDto(
      averageRating: (response['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: response['reviewCount'] as int? ?? 0,
    );
  }

  /// POST `/v1/customer/reviews/images` — multipart upload, one call per
  /// photo, returning the CDN URL to submit as an entry of
  /// `imageCdnUrls`.
  ///
  /// The filename is fixed rather than taken from the picked path: dio derives
  /// the part's Content-Type from the name and never from the bytes, and the
  /// endpoint allows only image/jpeg and image/png. See [uploadFilename].
  Future<String> uploadReviewImage(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: uploadFilename(filePath),
      ),
    });
    final response = await apiClient.rawPost(
      '/v1/customer/reviews/images',
      data: formData,
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  /// POST `/v1/customer/products/{productId}/reviews`. `orderId` is
  /// required server-side as proof of purchase; `kind` is always Written
  /// (0) here — Reel-review submission is a separate, still-unbuilt path
  /// (see `RateReviewSheet`'s ponytail note).
  ///
  /// [imagePaths] are local files. Each is uploaded first and the resulting
  /// CDN URLs are sent as `imageCdnUrls`, which is what the server attaches to
  /// the review. Until 2026-10-07 they were picked, previewed and then
  /// dropped — the comment here said "there's no upload endpoint yet", which
  /// was true of the API and quietly meant a review submitted with photos
  /// saved its text and none of its images.
  ///
  /// An image that fails to upload is skipped rather than failing the whole
  /// submission: losing one photo is better than losing the written review
  /// with it, and the server requires none.
  Future<Map<String, dynamic>> submitReview(
    String productId,
    String orderId,
    int rating,
    String comment,
    String idempotencyKey, {
    List<String>? imagePaths,
  }) async {
    final imageUrls = <String>[];
    for (final path in imagePaths ?? const <String>[]) {
      try {
        imageUrls.add(await uploadReviewImage(path));
      } catch (_) {
        // Skipped on purpose — see the note above.
      }
    }

    final response = await apiClient.post(
      '/v1/customer/products/$productId/reviews',
      data: {
        'orderId': orderId,
        'kind': 0,
        'rating': rating,
        'text': comment,
        if (imageUrls.isNotEmpty) 'imageCdnUrls': imageUrls,
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
