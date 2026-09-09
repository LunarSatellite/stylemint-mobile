import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/data/datasources/reviews_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/repositories/reviews_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  ReviewsRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  final ReviewsRemoteDataSource remoteDataSource;
  final NetworkInfoConnectivity networkInfo;

  static const _uuid = Uuid();

  @override
  Future<Either<NetworkExceptions, PagedResult<Review>>> getProductReviews(
    String productId, {
    int limit = 20,
    String? cursor,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final data = await remoteDataSource.getProductReviews(
          productId,
          limit: limit,
          cursor: cursor,
        );
        final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => _reviewFromApi(e as Map<String, dynamic>))
            .toList(growable: false);
        return right(PagedResult<Review>(
          items: items,
          totalCount: data['totalCount'] as int? ?? 0,
          pageSize: data['pageSize'] as int? ?? limit,
          nextCursor: data['nextCursor'] as String?,
          previousCursor: data['previousCursor'] as String?,
          hasMore: data['hasMore'] as bool? ?? false,
        ));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, ReviewSummary>> getReviewSummary(
    String productId,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final dto = await remoteDataSource.getReviewSummary(productId);
        return right(dto.toDomain());
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  @override
  Future<Either<NetworkExceptions, Review>> submitReview(
    String productId,
    String orderId,
    int rating,
    String comment, {
    List<String>? imagePaths,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final json = await remoteDataSource.submitReview(
          productId,
          orderId,
          rating,
          comment,
          _uuid.v4(),
          imagePaths: imagePaths,
        );
        return right(_reviewFromApi(json));
      } catch (e) {
        if (e is DioException) {
          return left(NetworkExceptions.server(e.message.toString()));
        } else if (e is NetworkExceptions) {
          return left(e);
        } else {
          return left(NetworkExceptions.unexpectedError());
        }
      }
    } else {
      return left(NetworkExceptions.noInternetConnection());
    }
  }

  // Backend's ProductReviewDto shape doesn't match ReviewDto's field names
  // (`text`/`createdUtc` vs `comment`/`createdAt`) and adds reviewer
  // identity as `reviewerDisplayName`/`reviewerAvatarUrl`, not
  // `userName`/`userAvatarUrl`. `helpfulCount` has no backend support at
  // all (no review-likes feature) — defaults to 0.
  Review _reviewFromApi(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map((i) => i['cdnUrl'] as String? ?? '')
        .toList(growable: false);
    final kindValue = json['kind'];
    final isReel = kindValue == 1 || kindValue == 'reel' || kindValue == 'Reel';
    return Review(
      id: json['id'] as String,
      userId: json['customerAccountId'] as String? ?? '',
      userName: json['reviewerDisplayName'] as String? ?? 'Anonymous',
      userAvatarUrl: json['reviewerAvatarUrl'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['createdUtc'] as String),
      images: images,
      helpfulCount: 0,
      kind: isReel ? ReviewKind.reel : ReviewKind.written,
      reelPlatform: json['reelPlatform']?.toString(),
      reelSourceUrl: json['reelSourceUrl'] as String?,
    );
  }
}
