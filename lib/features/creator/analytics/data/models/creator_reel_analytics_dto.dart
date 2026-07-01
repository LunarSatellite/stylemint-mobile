import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/analytics_window_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/earnings_trend_point_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/full_analytics_report_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/money_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_reel_analytics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_header.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_product_earnings_slice.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_statistics.dart';

part 'creator_reel_analytics_dto.freezed.dart';
part 'creator_reel_analytics_dto.g.dart';

@freezed
abstract class ReelHeaderDto with _$ReelHeaderDto {
  const factory ReelHeaderDto({
    required String reelId,
    String? title,
    String? thumbnailUrl,
    String? sourcePlatform,
    String? sourceUrl,
    @Default(0) int durationSeconds,
    DateTime? publishedAtUtc,
    @Default(0) int views,
    @Default(0) int likes,
    @Default(0) int comments,
  }) = _ReelHeaderDto;

  const ReelHeaderDto._();

  factory ReelHeaderDto.fromJson(Map<String, dynamic> json) =>
      _$ReelHeaderDtoFromJson(json);

  ReelHeader toDomain() => ReelHeader(
        reelId: reelId,
        title: title,
        thumbnailUrl: thumbnailUrl,
        sourcePlatform: sourcePlatform,
        sourceUrl: sourceUrl,
        durationSeconds: durationSeconds,
        publishedAtUtc: publishedAtUtc,
        views: views,
        likes: likes,
        comments: comments,
      );
}

@freezed
abstract class ReelProductEarningsSliceDto
    with _$ReelProductEarningsSliceDto {
  const factory ReelProductEarningsSliceDto({
    required String productId,
    String? name,
    String? thumbnailUrl,
    required MoneyDto amount,
    @Default(0) int quantity,
    @Default(0.0) double percentOfTotal,
  }) = _ReelProductEarningsSliceDto;

  const ReelProductEarningsSliceDto._();

  factory ReelProductEarningsSliceDto.fromJson(Map<String, dynamic> json) =>
      _$ReelProductEarningsSliceDtoFromJson(json);

  ReelProductEarningsSlice toDomain() => ReelProductEarningsSlice(
        productId: productId,
        name: name,
        thumbnailUrl: thumbnailUrl,
        amount: amount.toDomain(),
        quantity: quantity,
        percentOfTotal: percentOfTotal,
      );
}

@freezed
abstract class ReelStatisticsDto with _$ReelStatisticsDto {
  const factory ReelStatisticsDto({
    @Default(0.0) double conversionRate,
    @Default(0.0) double clickThroughRate,
    @Default(0.0) double completionRate,
    @Default(0) int uniqueViewersEstimate,
  }) = _ReelStatisticsDto;

  const ReelStatisticsDto._();

  factory ReelStatisticsDto.fromJson(Map<String, dynamic> json) =>
      _$ReelStatisticsDtoFromJson(json);

  ReelStatistics toDomain() => ReelStatistics(
        conversionRate: conversionRate,
        clickThroughRate: clickThroughRate,
        completionRate: completionRate,
        uniqueViewersEstimate: uniqueViewersEstimate,
      );
}

@freezed
abstract class CreatorReelAnalyticsDto with _$CreatorReelAnalyticsDto {
  const factory CreatorReelAnalyticsDto({
    required AnalyticsWindowDto window,
    required ReelHeaderDto reel,
    required MoneyDto totalEarnings,
    @Default(<ReelProductEarningsSliceDto>[])
    List<ReelProductEarningsSliceDto> earningsDistribution,
    required ReelStatisticsDto statistics,
    @Default(0) int watchTimeMinutes,
    @Default(<EarningsTrendPointDto>[])
    List<EarningsTrendPointDto> earningsTrend,
    @Default(<AudienceAgeBucketDto>[])
    List<AudienceAgeBucketDto> audienceDemographic,
    required GenderDistributionDto genderDistribution,
    @Default(<AudienceLocationDto>[]) List<AudienceLocationDto> topLocations,
  }) = _CreatorReelAnalyticsDto;

  const CreatorReelAnalyticsDto._();

  factory CreatorReelAnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorReelAnalyticsDtoFromJson(json);

  CreatorReelAnalytics toDomain() => CreatorReelAnalytics(
        window: window.toDomain(),
        reel: reel.toDomain(),
        totalEarnings: totalEarnings.toDomain(),
        earningsDistribution: earningsDistribution
            .map((e) => e.toDomain())
            .toList(growable: false),
        statistics: statistics.toDomain(),
        watchTimeMinutes: watchTimeMinutes,
        earningsTrend:
            earningsTrend.map((e) => e.toDomain()).toList(growable: false),
        audienceDemographic: audienceDemographic
            .map((e) => e.toDomain())
            .toList(growable: false),
        genderDistribution: genderDistribution.toDomain(),
        topLocations:
            topLocations.map((e) => e.toDomain()).toList(growable: false),
      );
}
