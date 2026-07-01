import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_analytics_overview.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_dashboard.dart';

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
}
