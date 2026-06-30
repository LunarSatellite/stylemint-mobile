import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/analytics_window.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/kpi_tile.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_product_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class CreatorDashboard {
  const CreatorDashboard({
    required this.window,
    required this.totalEarnings,
    required this.pendingBalance,
    required this.totalSales,
    required this.totalViews,
    required this.conversionRate,
    required this.topReels,
    required this.topProducts,
  });

  final AnalyticsWindow window;
  final KpiTile<Money> totalEarnings;
  final Money pendingBalance;
  final KpiTile<int> totalSales;
  final KpiTile<int> totalViews;
  final KpiTile<double> conversionRate;
  final List<TopReelSummary> topReels;
  final List<TopProductSummary> topProducts;
}
