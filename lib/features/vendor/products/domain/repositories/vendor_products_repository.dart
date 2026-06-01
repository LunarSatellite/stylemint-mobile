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

  Future<Either<NetworkExceptions, VendorProduct>> getProduct(String productId);
  Future<Either<NetworkExceptions, Unit>> updateProductStatus(
    String productId,
    VendorProductStatus status,
  );
  Future<Either<NetworkExceptions, Unit>> deleteProduct(String productId);
}
