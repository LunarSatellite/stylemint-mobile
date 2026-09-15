import 'package:flutter/foundation.dart' show immutable;

/// Visible reviews of one product, summarised for the product page.
@immutable
class ProductReviewSummary {
  const ProductReviewSummary({
    required this.productId,
    this.averageRating = 0,
    this.ratingCount = 0,
    this.reviewCount = 0,
    this.withPhotosCount = 0,
    this.distribution = const {},
  });

  final String productId;

  /// Out of 5; 0 when nothing is rated.
  final double averageRating;

  /// Written reviews with stars. Reel reviews carry no rating.
  final int ratingCount;

  /// Every visible review, rated or not.
  final int reviewCount;
  final int withPhotosCount;

  /// Stars (1–5) → number of ratings.
  final Map<int, int> distribution;

  int countFor(int stars) => distribution[stars] ?? 0;

  /// Share of ratings that gave [stars], from 0 to 1.
  double shareFor(int stars) {
    final total = distribution.values.fold<int>(0, (sum, count) => sum + count);
    return total <= 0 ? 0 : countFor(stars) / total;
  }
}
