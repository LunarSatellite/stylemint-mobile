import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/repositories/reviews_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

// ponytail: static mock — swap with ReviewsRepositoryImpl when API is ready
class MockReviewsRepository implements ReviewsRepository {
  static final _reviews = <Review>[
    Review(
      id: 'r1',
      userId: 'u1',
      userName: 'Sailesh Aryal',
      userAvatarUrl: '',
      rating: 5,
      comment: 'Absolutely love this! The quality exceeded my expectations. Will definitely buy again.',
      createdAt: DateTime(2026, 6, 20),
      images: [],
      helpfulCount: 12,
    ),
    Review(
      id: 'r2',
      userId: 'u2',
      userName: 'Priya Sharma',
      userAvatarUrl: '',
      rating: 4,
      comment: 'Great product overall. Delivery was fast and packaging was solid. Minor issue with sizing.',
      createdAt: DateTime(2026, 6, 18),
      images: [],
      helpfulCount: 7,
    ),
    Review(
      id: 'r3',
      userId: 'u3',
      userName: 'Aarav Thapa',
      userAvatarUrl: '',
      rating: 5,
      comment: 'Exactly as described. The finish is premium and it looks even better in person.',
      createdAt: DateTime(2026, 6, 15),
      images: [],
      helpfulCount: 4,
    ),
    Review(
      id: 'r4',
      userId: 'u4',
      userName: 'Sita Rai',
      userAvatarUrl: '',
      rating: 3,
      comment: 'Decent quality for the price. Could be better but gets the job done.',
      createdAt: DateTime(2026, 6, 10),
      images: [],
      helpfulCount: 2,
    ),
    Review(
      id: 'r5',
      userId: 'u5',
      userName: 'Bikash Gurung',
      userAvatarUrl: '',
      rating: 5,
      comment: 'Highly recommend! Bought two of these and both are perfect.',
      createdAt: DateTime(2026, 6, 5),
      images: [],
      helpfulCount: 9,
    ),
  ];

  @override
  Future<Either<NetworkExceptions, PagedResult<Review>>> getProductReviews(
    String productId, {
    int limit = 10,
    String? cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return right(PagedResult(
      items: _reviews,
      totalCount: _reviews.length,
      pageSize: limit,
      hasMore: false,
    ));
  }

  @override
  Future<Either<NetworkExceptions, ReviewSummary>> getReviewSummary(
    String productId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return right(ReviewSummary(
      averageRating: 4.4,
      totalReviews: 1275,
      ratingDistribution: {5: 820, 4: 310, 3: 95, 2: 30, 1: 20},
    ));
  }

  @override
  Future<Either<NetworkExceptions, Review>> submitReview(
    String productId,
    int rating,
    String comment, {
    List<String>? imagePaths,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return right(Review(
      id: 'r_new',
      userId: 'u_me',
      userName: 'Sailesh Aryal',
      userAvatarUrl: '',
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
      images: [],
      helpfulCount: 0,
    ));
  }
}
