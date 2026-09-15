import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_review_summary.dart';

/// `GET /v1/public/products/{id}/reviews/summary`:
/// `{ productId, averageRating, ratingCount, reviewCount, withPhotosCount,
/// distribution: [{ stars, count }] }` (catalog-contract.md §3). Missing
/// star rows read as 0, so the distribution always has 5 → 1.
abstract final class ProductReviewSummaryDto {
  static ProductReviewSummary fromJson(Map<String, dynamic> json) {
    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final rows = json['distribution'];
    if (rows is List) {
      for (final row in rows) {
        if (row is! Map) continue;
        final stars = readInt(row['stars']);
        final count = readInt(row['count']);
        if (stars >= 1 && stars <= 5) {
          distribution[stars] = count < 0 ? 0 : count;
        }
      }
    }
    final average = readOptionalDouble(json['averageRating']) ?? 0;
    return ProductReviewSummary(
      productId: readString(json['productId']),
      averageRating: average.clamp(0, 5).toDouble(),
      ratingCount: readInt(json['ratingCount']),
      reviewCount: readInt(json['reviewCount']),
      withPhotosCount: readInt(json['withPhotosCount']),
      distribution: distribution,
    );
  }
}
