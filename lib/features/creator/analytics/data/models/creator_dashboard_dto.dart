import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/analytics_window_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/kpi_tile_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/money_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/top_product_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/data/models/top_reel_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_dashboard.dart';

part 'creator_dashboard_dto.freezed.dart';
part 'creator_dashboard_dto.g.dart';

@freezed
abstract class CreatorDashboardDto with _$CreatorDashboardDto {
  const factory CreatorDashboardDto({
    required AnalyticsWindowDto window,
    required MoneyKpiTileDto totalEarnings,
    required MoneyDto pendingBalance,
    required IntKpiTileDto totalSales,
    required IntKpiTileDto totalViews,
    required DoubleKpiTileDto conversionRate,
    @Default(<TopReelSummaryDto>[]) List<TopReelSummaryDto> topReels,
    @Default(<TopProductSummaryDto>[]) List<TopProductSummaryDto> topProducts,
  }) = _CreatorDashboardDto;

  const CreatorDashboardDto._();

  factory CreatorDashboardDto.fromJson(Map<String, dynamic> json) =>
      _$CreatorDashboardDtoFromJson(json);

  CreatorDashboard toDomain() => CreatorDashboard(
    window: window.toDomain(),
    totalEarnings: totalEarnings.toDomain(),
    pendingBalance: pendingBalance.toDomain(),
    totalSales: totalSales.toDomain(),
    totalViews: totalViews.toDomain(),
    conversionRate: conversionRate.toDomain(),
    topReels: topReels.map((e) => e.toDomain()).toList(growable: false),
    topProducts: topProducts.map((e) => e.toDomain()).toList(growable: false),
  );
}
