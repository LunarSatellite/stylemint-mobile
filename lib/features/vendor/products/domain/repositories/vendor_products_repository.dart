import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/pagination.dart';

abstract interface class VendorProductsRepository {
  Future<Either<NetworkExceptions, PagedResult<VendorProduct>>> getProducts({
    int limit,
    String? cursor,
    String? status,
  });

  /// One listing the vendor owns, variants included. Screens that were
  /// handed the product on the route do not need this; screens that were
  /// not — a deep link, or a route restored after the process died — do,
  /// because without it they have no variant to act on.
  Future<Either<NetworkExceptions, VendorProduct>> getProduct(
    String productId,
  );

  Future<Either<NetworkExceptions, Unit>> updateProductStatus(
    String productId,
    VendorProductStatus status,
  );

  Future<Either<NetworkExceptions, VendorProduct>> updateStock({
    required String productId,
    required String variantId,
    required int newQuantity,
    DateTime? restockUtc,
    required bool alertCustomersOnRestock,
  });
}
