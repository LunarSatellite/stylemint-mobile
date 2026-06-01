/// Pure Dart domain entities for reviews — no JSON, no Dio.
class Review {
  const Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.images,
    required this.helpfulCount,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;
  final List<String> images;
  final int helpfulCount;

  Review copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    int? rating,
    String? comment,
    DateTime? createdAt,
    List<String>? images,
    int? helpfulCount,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      images: images ?? this.images,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }
}

class ReviewSummary {
  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  final double averageRating;
  final int totalReviews;
  /// Key = star count (1-5), value = number of reviews with that rating.
  final Map<int, int> ratingDistribution;

  ReviewSummary copyWith({
    double? averageRating,
    int? totalReviews,
    Map<int, int>? ratingDistribution,
  }) {
    return ReviewSummary(
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
    );
  }
}
