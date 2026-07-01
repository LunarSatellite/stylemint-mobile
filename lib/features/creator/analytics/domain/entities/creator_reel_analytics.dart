import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/analytics_window.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_age_bucket.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_location.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/earnings_trend_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/gender_distribution.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_header.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_product_earnings_slice.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_statistics.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class CreatorReelAnalytics {
  const CreatorReelAnalytics({
    required this.window,
    required this.reel,
    required this.totalEarnings,
    required this.earningsDistribution,
    required this.statistics,
    required this.watchTimeMinutes,
    required this.earningsTrend,
    required this.audienceDemographic,
    required this.genderDistribution,
    required this.topLocations,
  });

  final AnalyticsWindow window;
  final ReelHeader reel;
  final Money totalEarnings;
  final List<ReelProductEarningsSlice> earningsDistribution;
  final ReelStatistics statistics;
  final int watchTimeMinutes;
  final List<EarningsTrendPoint> earningsTrend;
  final List<AudienceAgeBucket> audienceDemographic;
  final GenderDistribution genderDistribution;
  final List<AudienceLocation> topLocations;
}
