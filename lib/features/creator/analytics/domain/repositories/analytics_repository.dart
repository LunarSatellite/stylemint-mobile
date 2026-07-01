import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_analytics_overview.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/full_analytics_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_reel_analytics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reels_sort.dart';

abstract interface class AnalyticsRepository {
  Future<Either<NetworkExceptions, CreatorAnalyticsOverview>> getOverview({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit,
    int topProductsLimit,
  });

  Future<Either<NetworkExceptions, CreatorDashboard>> getDashboard({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit,
    int topProductsLimit,
  });

  Future<Either<NetworkExceptions, FullAnalyticsReport>> getReport({
    DateTime? fromUtc,
    DateTime? toUtc,
    int contentPerformanceLimit,
    int topProductsLimit,
    int topLocationsLimit,
  });

  Future<Either<NetworkExceptions, List<TopReelSummary>>> getTopReels({
    DateTime? fromUtc,
    DateTime? toUtc,
    TopReelsSort sortBy,
    int limit,
  });

  Future<Either<NetworkExceptions, CreatorReelAnalytics>> getReelAnalytics({
    required String reelId,
    DateTime? fromUtc,
    DateTime? toUtc,
    int topLocationsLimit,
  });
}
