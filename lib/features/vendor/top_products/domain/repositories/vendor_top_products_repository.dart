import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/domain/entities/vendor_top_product.dart';

abstract class VendorTopProductsRepository {
  Future<Either<NetworkExceptions, List<VendorTopProduct>>> getTopProducts({
    DateTime? fromUtc,
    DateTime? toUtc,
    int? limit,
  });
}
