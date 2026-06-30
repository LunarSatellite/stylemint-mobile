import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/analytics_window.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/earnings_trend_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/kpi_tile.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_product_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class CreatorAnalyticsOverview {
  const CreatorAnalyticsOverview({
    required this.window,
    required this.totalEarnings,
    required this.totalSales,
    required this.conversionRate,
    required this.totalViews,
    required this.pendingBalance,
    required this.earningsTrend,
    required this.topReels,
    required this.topProducts,
  });

  final AnalyticsWindow window;
  final KpiTile<Money> totalEarnings;
  final KpiTile<int> totalSales;
  final KpiTile<double> conversionRate;
  final KpiTile<int> totalViews;
  final Money pendingBalance;
  final List<EarningsTrendPoint> earningsTrend;
  final List<TopReelSummary> topReels;
  final List<TopProductSummary> topProducts;
}
