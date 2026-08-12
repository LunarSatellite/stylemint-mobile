import 'package:stylemint_mobile_frontend/core/utils/media_urls.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/domain/entities/vendor_product_analytics.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Matches `GET /v1/vendor/products/{productId}/analytics` (Vendor §9H):
/// `{ window, header, revenue: {current,previous,deltaPercent}, unitsSold:
/// {...}, revenueTrend: [{date,amount}], topCreators: [...], locations:
/// [...], reviews: {reviewCount,averageRating,starDistribution} }`.
class MoneyDto {
  const MoneyDto({required this.amount, this.currency = 'NPR'});

  factory MoneyDto.fromJson(Map<String, dynamic>? json) => MoneyDto(
    amount: (json?['amount'] as num?)?.toDouble() ?? 0,
    currency: json?['currency'] as String? ?? 'NPR',
  );

  final double amount;
  final String currency;

  Money toDomain() => Money(amount: amount, currency: currency);
}

class ProductAnalyticsHeaderDto {
  const ProductAnalyticsHeaderDto({
    required this.productId,
    this.title,
    this.thumbnailUrl,
    required this.inStockUnits,
    required this.isActive,
  });

  factory ProductAnalyticsHeaderDto.fromJson(Map<String, dynamic> json) =>
      ProductAnalyticsHeaderDto(
        productId: json['productId'] as String? ?? '',
        title: json['title'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        inStockUnits: (json['inStockUnits'] as num?)?.toInt() ?? 0,
        isActive: json['isActive'] as bool? ?? false,
      );

  final String productId;
  final String? title;
  final String? thumbnailUrl;
  final int inStockUnits;
  final bool isActive;

  ProductAnalyticsHeader toDomain() => ProductAnalyticsHeader(
    productId: productId,
    title: title,
    thumbnailUrl: absoluteMediaUrl(thumbnailUrl),
    inStockUnits: inStockUnits,
    isActive: isActive,
  );
}

class RevenueTrendPointDto {
  const RevenueTrendPointDto({required this.date, required this.amount});

  factory RevenueTrendPointDto.fromJson(Map<String, dynamic> json) =>
      RevenueTrendPointDto(
        date: DateTime.parse(json['date'] as String),
        amount: MoneyDto.fromJson(json['amount'] as Map<String, dynamic>?),
      );

  final DateTime date;
  final MoneyDto amount;

  ProductRevenueTrendPoint toDomain() =>
      ProductRevenueTrendPoint(date: date, amount: amount.toDomain());
}

class ProductTopCreatorDto {
  const ProductTopCreatorDto({
    required this.creatorAccountId,
    required this.unitsSold,
    required this.attributedRevenue,
    required this.commissionPaid,
    required this.distinctReelCount,
  });

  factory ProductTopCreatorDto.fromJson(Map<String, dynamic> json) =>
      ProductTopCreatorDto(
        creatorAccountId: json['creatorAccountId'] as String? ?? '',
        unitsSold: (json['unitsSold'] as num?)?.toInt() ?? 0,
        attributedRevenue: MoneyDto.fromJson(
          json['attributedRevenue'] as Map<String, dynamic>?,
        ),
        commissionPaid: MoneyDto.fromJson(
          json['commissionPaid'] as Map<String, dynamic>?,
        ),
        distinctReelCount: (json['distinctReelCount'] as num?)?.toInt() ?? 0,
      );

  final String creatorAccountId;
  final int unitsSold;
  final MoneyDto attributedRevenue;
  final MoneyDto commissionPaid;
  final int distinctReelCount;

  ProductTopCreator toDomain() => ProductTopCreator(
    creatorAccountId: creatorAccountId,
    unitsSold: unitsSold,
    attributedRevenue: attributedRevenue.toDomain(),
    commissionPaid: commissionPaid.toDomain(),
    distinctReelCount: distinctReelCount,
  );
}

class ProductLocationBucketDto {
  const ProductLocationBucketDto({
    required this.region,
    required this.orderCount,
    required this.revenue,
  });

  factory ProductLocationBucketDto.fromJson(Map<String, dynamic> json) =>
      ProductLocationBucketDto(
        region: json['region'] as String? ?? 'Unknown',
        orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
        revenue: MoneyDto.fromJson(json['revenue'] as Map<String, dynamic>?),
      );

  final String region;
  final int orderCount;
  final MoneyDto revenue;

  ProductLocationBucket toDomain() => ProductLocationBucket(
    region: region,
    orderCount: orderCount,
    revenue: revenue.toDomain(),
  );
}

class ProductReviewSummaryDto {
  const ProductReviewSummaryDto({
    required this.reviewCount,
    required this.averageRating,
    required this.starDistribution,
  });

  factory ProductReviewSummaryDto.fromJson(Map<String, dynamic> json) =>
      ProductReviewSummaryDto(
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
        starDistribution: (json['starDistribution'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(int.tryParse(k) ?? 0, (v as num).toInt())) ??
            const {},
      );

  final int reviewCount;
  final double averageRating;
  final Map<int, int> starDistribution;

  ProductReviewSummary toDomain() => ProductReviewSummary(
    reviewCount: reviewCount,
    averageRating: averageRating,
    starDistribution: starDistribution,
  );
}

class VendorProductAnalyticsDto {
  const VendorProductAnalyticsDto({
    this.header,
    required this.revenueCurrent,
    this.revenueDeltaPercent,
    required this.unitsSoldCurrent,
    this.unitsSoldDeltaPercent,
    required this.revenueTrend,
    required this.topCreators,
    required this.locations,
    this.reviews,
  });

  factory VendorProductAnalyticsDto.fromJson(Map<String, dynamic> json) {
    final revenue = json['revenue'] as Map<String, dynamic>?;
    final unitsSold = json['unitsSold'] as Map<String, dynamic>?;
    return VendorProductAnalyticsDto(
      header: json['header'] == null
          ? null
          : ProductAnalyticsHeaderDto.fromJson(
              json['header'] as Map<String, dynamic>,
            ),
      revenueCurrent: MoneyDto.fromJson(
        revenue?['current'] as Map<String, dynamic>?,
      ),
      revenueDeltaPercent: (revenue?['deltaPercent'] as num?)?.toDouble(),
      unitsSoldCurrent: (unitsSold?['current'] as num?)?.toInt() ?? 0,
      unitsSoldDeltaPercent: (unitsSold?['deltaPercent'] as num?)?.toDouble(),
      revenueTrend: (json['revenueTrend'] as List<dynamic>? ?? [])
          .map((e) => RevenueTrendPointDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      topCreators: (json['topCreators'] as List<dynamic>? ?? [])
          .map((e) => ProductTopCreatorDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      locations: (json['locations'] as List<dynamic>? ?? [])
          .map(
            (e) => ProductLocationBucketDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      reviews: json['reviews'] == null
          ? null
          : ProductReviewSummaryDto.fromJson(
              json['reviews'] as Map<String, dynamic>,
            ),
    );
  }

  final ProductAnalyticsHeaderDto? header;
  final MoneyDto revenueCurrent;
  final double? revenueDeltaPercent;
  final int unitsSoldCurrent;
  final double? unitsSoldDeltaPercent;
  final List<RevenueTrendPointDto> revenueTrend;
  final List<ProductTopCreatorDto> topCreators;
  final List<ProductLocationBucketDto> locations;
  final ProductReviewSummaryDto? reviews;

  VendorProductAnalytics toDomain() => VendorProductAnalytics(
    header: header?.toDomain(),
    revenue: revenueCurrent.toDomain(),
    revenueDeltaPercent: revenueDeltaPercent,
    unitsSold: unitsSoldCurrent,
    unitsSoldDeltaPercent: unitsSoldDeltaPercent,
    revenueTrend: revenueTrend.map((e) => e.toDomain()).toList(),
    topCreators: topCreators.map((e) => e.toDomain()).toList(),
    locations: locations.map((e) => e.toDomain()).toList(),
    reviews: reviews?.toDomain(),
  );
}
