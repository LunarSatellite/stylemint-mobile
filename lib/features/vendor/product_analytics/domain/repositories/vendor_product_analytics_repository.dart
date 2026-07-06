import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/domain/entities/vendor_product_analytics.dart';

abstract class VendorProductAnalyticsRepository {
  Future<Either<NetworkExceptions, VendorProductAnalytics>> getProductAnalytics({
    required String productId,
    DateTime? fromUtc,
    DateTime? toUtc,
  });
}
