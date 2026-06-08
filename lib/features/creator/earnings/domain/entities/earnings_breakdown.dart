import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Per-reel earnings breakdown derived from the creator analytics dashboard
/// (GET /v1/creator/analytics/dashboard). Distinct from the balance summary:
/// the balance endpoint has no per-reel metrics, so these come from the
/// dashboard's TotalSales + TopReels.
class EarningsBreakdown {
  const EarningsBreakdown({
    required this.salesCount,
    required this.reelCount,
    required this.avgPerSale,
    required this.highestReelEarnings,
  });

  /// Total sales in the window (dashboard TotalSales.current).
  final int salesCount;

  /// Number of top-performing reels returned by the dashboard. The dashboard
  /// exposes no total-reel count, so this reflects TopReels.length.
  final int reelCount;

  /// Total earnings / sales count (0 when no sales).
  final Money avgPerSale;

  /// Highest single-reel earnings among TopReels.
  final Money highestReelEarnings;
}
