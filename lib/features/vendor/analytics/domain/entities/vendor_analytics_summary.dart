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

/// A KPI tile with a current value plus period-over-period comparison —
/// mirrors the backend's generic `KpiTileDto<T>`.
class KpiTile<T> {
  const KpiTile({required this.current, this.previous, this.deltaPercent});

  final T current;
  final T? previous;
  final double? deltaPercent;
}

class DeepDiveRevenuePoint {
  const DeepDiveRevenuePoint({required this.date, required this.amount});

  final DateTime date;
  final double amount;
}

class DeepDiveTopProduct {
  const DeepDiveTopProduct({
    required this.productId,
    required this.name,
    required this.unitsSold,
    required this.totalRevenue,
    required this.distinctCreatorCount,
    this.thumbnailUrl,
  });

  final String productId;
  final String name;
  final String? thumbnailUrl;
  final int unitsSold;
  final double totalRevenue;
  final int distinctCreatorCount;
}

class DeepDiveTopReel {
  const DeepDiveTopReel({
    required this.reelId,
    required this.sourcePlatform,
    required this.externalUrl,
    required this.viewCount,
    required this.unitsSold,
    required this.attributedRevenue,
    this.caption,
  });

  final String reelId;
  final String sourcePlatform;
  final String externalUrl;
  final String? caption;
  final int viewCount;
  final int unitsSold;
  final double attributedRevenue;
}

/// Mirrors the response of
/// `GET /v1/vendor/partnerships/{partnershipId}/creator-analytics`.
class CreatorAnalyticsDeepDive {
  const CreatorAnalyticsDeepDive({
    required this.partnershipId,
    required this.creatorAccountId,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    required this.attributedRevenue,
    required this.unitsSold,
    required this.commissionPaid,
    required this.distinctReelCount,
    required this.revenueTrend,
    required this.topProducts,
    required this.topReels,
    required this.currency,
    this.displayName,
    this.avatarUrl,
  });

  final String partnershipId;
  final String creatorAccountId;
  final String? displayName;
  final String? avatarUrl;

  /// Fractions (0..1), not whole percents.
  final double commissionMinPercent;
  final double commissionMaxPercent;

  final KpiTile<double> attributedRevenue;
  final KpiTile<int> unitsSold;
  final KpiTile<double> commissionPaid;
  final KpiTile<int> distinctReelCount;
  final List<DeepDiveRevenuePoint> revenueTrend;
  final List<DeepDiveTopProduct> topProducts;
  final List<DeepDiveTopReel> topReels;
  final String currency;

  String get creatorLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return creatorAccountId.length >= 8
        ? 'Creator ••${creatorAccountId.substring(creatorAccountId.length - 4)}'
        : 'Creator';
  }
}
