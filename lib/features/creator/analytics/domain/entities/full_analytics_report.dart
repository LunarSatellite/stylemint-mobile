import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/analytics_window.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_age_bucket.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_location.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/best_posting_window.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/content_performance_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/conversion_funnel.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/conversion_metrics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/earnings_trend_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/gender_distribution.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_product.dart';

class FullAnalyticsReport {
  const FullAnalyticsReport({
    required this.window,
    required this.earningsTrend,
    required this.contentPerformance,
    required this.conversionMetrics,
    required this.conversionFunnel,
    required this.audienceDemographic,
    required this.bestPostingTimes,
    required this.genderDistribution,
    required this.topProducts,
    required this.topLocations,
  });

  final AnalyticsWindow window;
  final List<EarningsTrendPoint> earningsTrend;
  final List<ContentPerformancePoint> contentPerformance;
  final ConversionMetrics conversionMetrics;
  final ConversionFunnel conversionFunnel;
  final List<AudienceAgeBucket> audienceDemographic;
  final List<BestPostingWindow> bestPostingTimes;
  final GenderDistribution genderDistribution;
  final List<TopProduct> topProducts;
  final List<AudienceLocation> topLocations;
}
