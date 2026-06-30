import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/entities/vendor_analytics_summary.dart';

abstract class AnalyticsRepository {
  Future<Either<NetworkExceptions, VendorAnalyticsSummary>> getSummary({
    String? window,
  });
}
