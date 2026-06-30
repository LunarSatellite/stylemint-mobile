import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/entities/vendor_analytics_summary.dart';

// ---------------------------------------------------------------------------
// Revenue overview
// ---------------------------------------------------------------------------

class AnalyticsOverviewDto {
  const AnalyticsOverviewDto({
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

  factory AnalyticsOverviewDto.fromJson(Map<String, dynamic> json) =>
      AnalyticsOverviewDto(
        grossSales: (json['grossSales'] as num).toDouble(),
        grossSalesBadge: json['grossSalesBadge'] as String? ?? '',
        netRevenue: (json['netRevenue'] as num).toDouble(),
        netRevenueBadge: json['netRevenueBadge'] as String? ?? '',
        conversionRate: (json['conversionRate'] as num).toDouble(),
        conversionRateBadge: json['conversionRateBadge'] as String? ?? '',
        totalOrders: json['totalOrders'] as int,
        totalOrdersBadge: json['totalOrdersBadge'] as String? ?? '',
        currency: json['currency'] as String? ?? 'NPR',
      );

  final double grossSales;
  final String grossSalesBadge;
  final double netRevenue;
  final String netRevenueBadge;
  final double conversionRate;
  final String conversionRateBadge;
  final int totalOrders;
  final String totalOrdersBadge;
  final String currency;

  RevenueOverview toDomain() => RevenueOverview(
        grossSales: grossSales,
        grossSalesBadge: grossSalesBadge,
        netRevenue: netRevenue,
        netRevenueBadge: netRevenueBadge,
        conversionRate: conversionRate,
        conversionRateBadge: conversionRateBadge,
        totalOrders: totalOrders,
        totalOrdersBadge: totalOrdersBadge,
        currency: currency,
      );
}

// ---------------------------------------------------------------------------
// Earnings chart point
// ---------------------------------------------------------------------------

class EarningsPointDto {
  const EarningsPointDto({required this.label, required this.value});

  factory EarningsPointDto.fromJson(Map<String, dynamic> json) =>
      EarningsPointDto(
        label: json['label'] as String,
        value: (json['value'] as num).toDouble(),
      );

  final String label;
  final double value;

  EarningsPoint toDomain() => EarningsPoint(label: label, value: value);
}

// ---------------------------------------------------------------------------
// Top product
// ---------------------------------------------------------------------------

class AnalyticsTopProductDto {
  const AnalyticsTopProductDto({
    required this.rank,
    required this.productId,
    required this.name,
    required this.price,
    required this.currency,
    required this.unitsSold,
    this.imageUrl,
  });

  factory AnalyticsTopProductDto.fromJson(Map<String, dynamic> json) =>
      AnalyticsTopProductDto(
        rank: json['rank'] as int,
        productId: json['productId'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'NPR',
        unitsSold: json['unitsSold'] as int,
        imageUrl: json['imageUrl'] as String?,
      );

  final int rank;
  final String productId;
  final String name;
  final double price;
  final String currency;
  final int unitsSold;
  final String? imageUrl;

  TopProduct toDomain() => TopProduct(
        rank: rank,
        productId: productId,
        name: name,
        price: price,
        currency: currency,
        unitsSold: unitsSold,
        imageUrl: imageUrl,
      );
}

// ---------------------------------------------------------------------------
// Top creator summary
// ---------------------------------------------------------------------------

class AnalyticsTopCreatorDto {
  const AnalyticsTopCreatorDto({
    required this.rank,
    required this.creatorAccountId,
    required this.attributedRevenue,
    required this.currency,
    required this.distinctReelCount,
    this.handle,
    this.displayName,
  });

  factory AnalyticsTopCreatorDto.fromJson(Map<String, dynamic> json) =>
      AnalyticsTopCreatorDto(
        rank: json['rank'] as int,
        creatorAccountId: json['creatorAccountId'] as String,
        attributedRevenue: (json['attributedRevenue'] as num).toDouble(),
        currency: json['currency'] as String? ?? 'NPR',
        distinctReelCount: json['distinctReelCount'] as int? ?? 0,
        handle: json['handle'] as String?,
        displayName: json['displayName'] as String?,
      );

  final int rank;
  final String creatorAccountId;
  final double attributedRevenue;
  final String currency;
  final int distinctReelCount;
  final String? handle;
  final String? displayName;

  TopCreatorSummary toDomain() => TopCreatorSummary(
        rank: rank,
        creatorAccountId: creatorAccountId,
        attributedRevenue: attributedRevenue,
        currency: currency,
        distinctReelCount: distinctReelCount,
        handle: handle,
        displayName: displayName,
      );
}

// ---------------------------------------------------------------------------
// Traffic source
// ---------------------------------------------------------------------------

class AnalyticsTrafficSourceDto {
  const AnalyticsTrafficSourceDto({
    required this.platform,
    required this.percentage,
  });

  factory AnalyticsTrafficSourceDto.fromJson(Map<String, dynamic> json) =>
      AnalyticsTrafficSourceDto(
        platform: json['platform'] as String,
        percentage: (json['percentage'] as num).toDouble(),
      );

  final String platform;
  final double percentage;

  TrafficSource toDomain() =>
      TrafficSource(platform: platform, percentage: percentage);
}

// ---------------------------------------------------------------------------
// Aggregate DTO — one toDomain() converts everything
// ---------------------------------------------------------------------------

class VendorAnalyticsSummaryDto {
  const VendorAnalyticsSummaryDto({
    required this.overview,
    required this.earningsPoints,
    required this.topProducts,
    required this.topCreators,
    required this.trafficSources,
  });

  final AnalyticsOverviewDto overview;
  final List<EarningsPointDto> earningsPoints;
  final List<AnalyticsTopProductDto> topProducts;
  final List<AnalyticsTopCreatorDto> topCreators;
  final List<AnalyticsTrafficSourceDto> trafficSources;

  VendorAnalyticsSummary toDomain() => VendorAnalyticsSummary(
        revenueOverview: overview.toDomain(),
        earningsPoints: earningsPoints.map((e) => e.toDomain()).toList(),
        topProducts: topProducts.map((e) => e.toDomain()).toList(),
        topCreators: topCreators.map((e) => e.toDomain()).toList(),
        trafficSources: trafficSources.map((e) => e.toDomain()).toList(),
      );
}
