import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';

abstract interface class InStoreRepository {
  /// Published reels that tag [productId], newest first. Works signed out.
  Future<Either<NetworkExceptions, List<ProductReel>>> getProductReels(
    String productId,
  );

  /// One page of the products [vendorAccountId] lists publicly, newest
  /// first; pass the previous page's `nextCursor` as [cursor] for the next
  /// one. An unknown vendor is an empty page. Works signed out.
  Future<Either<NetworkExceptions, StoreProductsPage>> getVendorProducts(
    String vendorAccountId, {
    String? cursor,
  });
}
