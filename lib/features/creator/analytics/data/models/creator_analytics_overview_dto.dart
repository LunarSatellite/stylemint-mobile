import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/analytics_window_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/earnings_trend_point_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/kpi_tile_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/money_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/top_product_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/top_reel_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_analytics_overview.dart';

part 'creator_analytics_overview_dto.freezed.dart';
part 'creator_analytics_overview_dto.g.dart';

@freezed
abstract class CreatorAnalyticsOverviewDto with _$CreatorAnalyticsOverviewDto {
  const factory CreatorAnalyticsOverviewDto({
    required AnalyticsWindowDto window,
    required MoneyKpiTileDto totalEarnings,
    required IntKpiTileDto totalSales,
    required DoubleKpiTileDto conversionRate,
    required IntKpiTileDto totalViews,
    required MoneyDto pendingBalance,
    @Default(<EarningsTrendPointDto>[])
    List<EarningsTrendPointDto> earningsTrend,
    @Default(<TopReelSummaryDto>[]) List<TopReelSummaryDto> topReels,
    @Default(<TopProductSummaryDto>[]) List<TopProductSummaryDto> topProducts,
  }) = _CreatorAnalyticsOverviewDto;

  const CreatorAnalyticsOverviewDto._();

  factory CreatorAnalyticsOverviewDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorAnalyticsOverviewDtoFromJson(json);

  CreatorAnalyticsOverview toDomain() => CreatorAnalyticsOverview(
    window: window.toDomain(),
    totalEarnings: totalEarnings.toDomain(),
    totalSales: totalSales.toDomain(),
    conversionRate: conversionRate.toDomain(),
    totalViews: totalViews.toDomain(),
    pendingBalance: pendingBalance.toDomain(),
    earningsTrend:
        earningsTrend.map((e) => e.toDomain()).toList(growable: false),
    topReels: topReels.map((e) => e.toDomain()).toList(growable: false),
    topProducts: topProducts.map((e) => e.toDomain()).toList(growable: false),
  );
}
