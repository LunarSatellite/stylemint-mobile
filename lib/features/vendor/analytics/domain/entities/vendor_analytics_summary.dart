class RevenueOverview {
  const RevenueOverview({
    required this.grossSales,
    required this.grossSalesBadge,
    required this.netRevenue,
    required this.netRevenueBadge,
    required this.conversionRate,
    required this.conversionRateBadge,
    required this.totalOrders,
    required this.totalOrdersBadge,
    required this.currency,
  });

  final double grossSales;
  final String grossSalesBadge;
  final double netRevenue;
  final String netRevenueBadge;
  final double conversionRate;
  final String conversionRateBadge;
  final int totalOrders;
  final String totalOrdersBadge;
  final String currency;
}

class EarningsPoint {
  const EarningsPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class TopProduct {
  const TopProduct({
    required this.rank,
    required this.productId,
    required this.name,
    required this.price,
    required this.currency,
    required this.unitsSold,
    this.imageUrl,
  });

  final int rank;
  final String productId;
  final String name;

  /// This window's total revenue for the product — the backend doesn't
  /// return a per-unit price.
  final double price;
  final String currency;
  final int unitsSold;
  final String? imageUrl;
}

class TopCreatorSummary {
  const TopCreatorSummary({
    required this.rank,
    required this.creatorAccountId,
    required this.attributedRevenue,
    required this.currency,
    required this.distinctReelCount,
    this.handle,
    this.displayName,
  });

  final int rank;
  final String creatorAccountId;
  final String? handle;
  final String? displayName;
  final double attributedRevenue;
  final String currency;
  final int distinctReelCount;

  String get formattedHandle {
    final h = handle;
    if (h != null && h.isNotEmpty) return '@$h';
    final d = displayName;
    if (d != null && d.isNotEmpty) return d;
    return creatorAccountId.substring(0, 8);
  }

  String get avatarInitial {
    final h = handle;
    if (h != null && h.isNotEmpty) return h[0].toUpperCase();
    final d = displayName;
    if (d != null && d.isNotEmpty) return d[0].toUpperCase();
    return '?';
  }
}

class TrafficSource {
  const TrafficSource({required this.platform, required this.percentage});

  final String platform;
  final double percentage;
}

class VendorAnalyticsSummary {
  const VendorAnalyticsSummary({
    required this.revenueOverview,
    required this.earningsPoints,
    required this.topProducts,
    required this.topCreators,
    required this.trafficSources,
  });

  final RevenueOverview revenueOverview;
  final List<EarningsPoint> earningsPoints;
  final List<TopProduct> topProducts;
  final List<TopCreatorSummary> topCreators;
  final List<TrafficSource> trafficSources;
}
