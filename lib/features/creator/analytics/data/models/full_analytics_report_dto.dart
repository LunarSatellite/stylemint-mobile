import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/analytics_window_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/earnings_trend_point_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/money_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_age_bucket.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_location.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/best_posting_window.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/content_performance_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/conversion_funnel.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/conversion_metrics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/funnel_stage.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/full_analytics_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/gender_distribution.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_product.dart';

part 'full_analytics_report_dto.freezed.dart';
part 'full_analytics_report_dto.g.dart';

// ── Sub-DTOs ──────────────────────────────────────────────────────────────────

@freezed
abstract class ContentPerformancePointDto with _$ContentPerformancePointDto {
  const factory ContentPerformancePointDto({
    required String reelId,
    String? title,
    String? thumbnailUrl,
    required MoneyDto earnings,
    @Default(0) int sales,
  }) = _ContentPerformancePointDto;

  const ContentPerformancePointDto._();

  factory ContentPerformancePointDto.fromJson(Map<String, dynamic> json) =>
      _$ContentPerformancePointDtoFromJson(json);

  ContentPerformancePoint toDomain() => ContentPerformancePoint(
        reelId: reelId,
        title: title,
        thumbnailUrl: thumbnailUrl,
        earnings: earnings.toDomain(),
        sales: sales,
      );
}

@freezed
abstract class ConversionMetricsDto with _$ConversionMetricsDto {
  const factory ConversionMetricsDto({
    @Default(0) int totalClicks,
    @Default(0) int totalOrders,
    @Default(0.0) double conversionRate,
    required MoneyDto averageOrderValue,
  }) = _ConversionMetricsDto;

  const ConversionMetricsDto._();

  factory ConversionMetricsDto.fromJson(Map<String, dynamic> json) =>
      _$ConversionMetricsDtoFromJson(json);

  ConversionMetrics toDomain() => ConversionMetrics(
        totalClicks: totalClicks,
        totalOrders: totalOrders,
        conversionRate: conversionRate,
        averageOrderValue: averageOrderValue.toDomain(),
      );
}

@freezed
abstract class FunnelStageDto with _$FunnelStageDto {
  const factory FunnelStageDto({
    @Default(0) int count,
    @Default(0.0) double percentOfTop,
  }) = _FunnelStageDto;

  const FunnelStageDto._();

  factory FunnelStageDto.fromJson(Map<String, dynamic> json) =>
      _$FunnelStageDtoFromJson(json);

  FunnelStage toDomain() =>
      FunnelStage(count: count, percentOfTop: percentOfTop);
}

@freezed
abstract class ConversionFunnelDto with _$ConversionFunnelDto {
  const factory ConversionFunnelDto({
    required FunnelStageDto views,
    required FunnelStageDto clicks,
    required FunnelStageDto addedToCart,
    required FunnelStageDto orders,
  }) = _ConversionFunnelDto;

  const ConversionFunnelDto._();

  factory ConversionFunnelDto.fromJson(Map<String, dynamic> json) =>
      _$ConversionFunnelDtoFromJson(json);

  ConversionFunnel toDomain() => ConversionFunnel(
        views: views.toDomain(),
        clicks: clicks.toDomain(),
        addedToCart: addedToCart.toDomain(),
        orders: orders.toDomain(),
      );
}

@freezed
abstract class AudienceAgeBucketDto with _$AudienceAgeBucketDto {
  const factory AudienceAgeBucketDto({
    String? ageRange,
    @Default(0.0) double percent,
  }) = _AudienceAgeBucketDto;

  const AudienceAgeBucketDto._();

  factory AudienceAgeBucketDto.fromJson(Map<String, dynamic> json) =>
      _$AudienceAgeBucketDtoFromJson(json);

  AudienceAgeBucket toDomain() =>
      AudienceAgeBucket(ageRange: ageRange, percent: percent);
}

@freezed
abstract class GenderDistributionDto with _$GenderDistributionDto {
  const factory GenderDistributionDto({
    @Default(0.0) double femalePercent,
    @Default(0.0) double malePercent,
    @Default(0.0) double otherPercent,
  }) = _GenderDistributionDto;

  const GenderDistributionDto._();

  factory GenderDistributionDto.fromJson(Map<String, dynamic> json) =>
      _$GenderDistributionDtoFromJson(json);

  GenderDistribution toDomain() => GenderDistribution(
        femalePercent: femalePercent,
        malePercent: malePercent,
        otherPercent: otherPercent,
      );
}

@freezed
abstract class AudienceLocationDto with _$AudienceLocationDto {
  const factory AudienceLocationDto({
    String? city,
    @Default(0.0) double percent,
  }) = _AudienceLocationDto;

  const AudienceLocationDto._();

  factory AudienceLocationDto.fromJson(Map<String, dynamic> json) =>
      _$AudienceLocationDtoFromJson(json);

  AudienceLocation toDomain() =>
      AudienceLocation(city: city, percent: percent);
}

@freezed
abstract class BestPostingWindowDto with _$BestPostingWindowDto {
  const factory BestPostingWindowDto({
    String? dayOfWeekLabel,
    @Default(0) int startHourLocal,
    @Default(0) int endHourLocal,
    String? annotation,
  }) = _BestPostingWindowDto;

  const BestPostingWindowDto._();

  factory BestPostingWindowDto.fromJson(Map<String, dynamic> json) =>
      _$BestPostingWindowDtoFromJson(json);

  BestPostingWindow toDomain() => BestPostingWindow(
        dayOfWeekLabel: dayOfWeekLabel,
        startHourLocal: startHourLocal,
        endHourLocal: endHourLocal,
        annotation: annotation,
      );
}

@freezed
abstract class TopProductDto with _$TopProductDto {
  const factory TopProductDto({
    required String productId,
    String? name,
    String? thumbnailUrl,
    @Default(0) int totalSales,
    required MoneyDto totalCommission,
    @Default(0.0) double commissionRatePercent,
    required MoneyDto avgCommissionPerSale,
  }) = _TopProductDto;

  const TopProductDto._();

  factory TopProductDto.fromJson(Map<String, dynamic> json) =>
      _$TopProductDtoFromJson(json);

  TopProduct toDomain() => TopProduct(
        productId: productId,
        name: name,
        thumbnailUrl: thumbnailUrl,
        totalSales: totalSales,
        totalCommission: totalCommission.toDomain(),
        commissionRatePercent: commissionRatePercent,
        avgCommissionPerSale: avgCommissionPerSale.toDomain(),
      );
}

// ── Root DTO ──────────────────────────────────────────────────────────────────

@freezed
abstract class FullAnalyticsReportDto with _$FullAnalyticsReportDto {
  const factory FullAnalyticsReportDto({
    required AnalyticsWindowDto window,
    @Default(<EarningsTrendPointDto>[]) List<EarningsTrendPointDto> earningsTrend,
    @Default(<ContentPerformancePointDto>[])
    List<ContentPerformancePointDto> contentPerformance,
    required ConversionMetricsDto conversionMetrics,
    required ConversionFunnelDto conversionFunnel,
    @Default(<AudienceAgeBucketDto>[])
    List<AudienceAgeBucketDto> audienceDemographic,
    @Default(<BestPostingWindowDto>[])
    List<BestPostingWindowDto> bestPostingTimes,
    required GenderDistributionDto genderDistribution,
    @Default(<TopProductDto>[]) List<TopProductDto> topProducts,
    @Default(<AudienceLocationDto>[]) List<AudienceLocationDto> topLocations,
  }) = _FullAnalyticsReportDto;

  const FullAnalyticsReportDto._();

  factory FullAnalyticsReportDto.fromJson(Map<String, dynamic> json) =>
      _$FullAnalyticsReportDtoFromJson(json);

  FullAnalyticsReport toDomain() => FullAnalyticsReport(
        window: window.toDomain(),
        earningsTrend:
            earningsTrend.map((e) => e.toDomain()).toList(growable: false),
        contentPerformance:
            contentPerformance.map((e) => e.toDomain()).toList(growable: false),
        conversionMetrics: conversionMetrics.toDomain(),
        conversionFunnel: conversionFunnel.toDomain(),
        audienceDemographic:
            audienceDemographic.map((e) => e.toDomain()).toList(growable: false),
        bestPostingTimes:
            bestPostingTimes.map((e) => e.toDomain()).toList(growable: false),
        genderDistribution: genderDistribution.toDomain(),
        topProducts:
            topProducts.map((e) => e.toDomain()).toList(growable: false),
        topLocations:
            topLocations.map((e) => e.toDomain()).toList(growable: false),
      );
}
