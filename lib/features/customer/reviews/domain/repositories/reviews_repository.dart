import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class ReviewsRepository {
  Future<Either<NetworkExceptions, PagedResult<Review>>> getProductReviews(
    String productId, {
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, ReviewSummary>> getReviewSummary(String productId);

  Future<Either<NetworkExceptions, Review>> submitReview(
    String productId,
    int rating,
    String comment, {
    List<String>? imagePaths,
  });
}
