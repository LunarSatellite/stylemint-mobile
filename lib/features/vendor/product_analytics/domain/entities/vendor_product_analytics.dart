import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// `GET /v1/vendor/products/{productId}/analytics` (Vendor §9H). Mirrors the
/// screen sections the backend actually supports: header, revenue/units KPIs
/// (window vs. prior window), daily revenue trend, top creators driving sales
/// of this product, geographic distribution, and the review aggregate.
/// There is no age/gender demographic breakdown, conversion rate, cart-add
/// count, or view-to-purchase ratio anywhere in this endpoint.
class ProductAnalyticsHeader {
  const ProductAnalyticsHeader({
    required this.productId,
    this.title,
    this.thumbnailUrl,
    required this.inStockUnits,
    required this.isActive,
  });

  final String productId;
  final String? title;
  final String? thumbnailUrl;
  final int inStockUnits;
  final bool isActive;
}

class ProductRevenueTrendPoint {
  const ProductRevenueTrendPoint({required this.date, required this.amount});

  final DateTime date;
  final Money amount;
}

class ProductTopCreator {
  const ProductTopCreator({
    required this.creatorAccountId,
    required this.unitsSold,
    required this.attributedRevenue,
    required this.commissionPaid,
    required this.distinctReelCount,
  });

  final String creatorAccountId;
  final int unitsSold;
  final Money attributedRevenue;
  final Money commissionPaid;
  final int distinctReelCount;
}

class ProductLocationBucket {
  const ProductLocationBucket({
    required this.region,
    required this.orderCount,
    required this.revenue,
  });

  final String region;
  final int orderCount;
  final Money revenue;
}

class ProductReviewSummary {
  const ProductReviewSummary({
    required this.reviewCount,
    required this.averageRating,
    required this.starDistribution,
  });

  final int reviewCount;
  final double averageRating;

  /// Star value (1-5) -> count of reviews at that star level.
  final Map<int, int> starDistribution;
}

class VendorProductAnalytics {
  const VendorProductAnalytics({
    this.header,
    required this.revenue,
    this.revenueDeltaPercent,
    required this.unitsSold,
    this.unitsSoldDeltaPercent,
    required this.revenueTrend,
    required this.topCreators,
    required this.locations,
    this.reviews,
  });

  final ProductAnalyticsHeader? header;
  final Money revenue;
  final double? revenueDeltaPercent;
  final int unitsSold;
  final double? unitsSoldDeltaPercent;
  final List<ProductRevenueTrendPoint> revenueTrend;
  final List<ProductTopCreator> topCreators;
  final List<ProductLocationBucket> locations;
  final ProductReviewSummary? reviews;
}
