import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/reviews/domain/entities/review.dart';

part 'review_dto.freezed.dart';
part 'review_dto.g.dart';

@freezed
abstract class ReviewDto with _$ReviewDto {
  const factory ReviewDto({
    required String id,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required int rating,
    required String comment,
    required DateTime createdAt,
    @Default(<String>[]) List<String> images,
    @Default(0) int helpfulCount,
  }) = _ReviewDto;

  const ReviewDto._();

  factory ReviewDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewDtoFromJson(json);

  Review toDomain() => Review(
    id: id,
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    rating: rating,
    comment: comment,
    createdAt: createdAt,
    images: images,
    helpfulCount: helpfulCount,
  );
}

@freezed
abstract class ReviewSummaryDto with _$ReviewSummaryDto {
  const factory ReviewSummaryDto({
    required double averageRating,
    required int totalReviews,
    @Default(<String, int>{}) Map<String, int> ratingDistribution,
  }) = _ReviewSummaryDto;

  const ReviewSummaryDto._();

  factory ReviewSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$ReviewSummaryDtoFromJson(json);

  ReviewSummary toDomain() => ReviewSummary(
    averageRating: averageRating,
    totalReviews: totalReviews,
    ratingDistribution: ratingDistribution.map(
      (k, v) => MapEntry(int.parse(k), v),
    ),
  );
}
