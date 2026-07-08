import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Month-to-date earnings breakdown (SM-BG-4), from
/// GET /v1/earnings/summary. Distinct from the balance summary: the balance
/// endpoint has no per-sale/per-reel metrics.
class EarningsBreakdown {
  const EarningsBreakdown({
    required this.salesCount,
    required this.reelCount,
    required this.avgPerSale,
    required this.highestReelEarnings,
  });

  /// This calendar month's Settled sales count.
  final int salesCount;

  /// Distinct reels with attributed earnings this month.
  final int reelCount;

  /// Total earnings / sales count (0 when no sales).
  final Money avgPerSale;

  /// The single highest-earning reel's net commission this month.
  final Money highestReelEarnings;
}
