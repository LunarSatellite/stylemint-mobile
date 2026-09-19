import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/codes/domain/entities/code_kind.dart';
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
  /// Adds an already-resolved active product tag to the signed-in shopper's
  /// shared cart while preserving code/store/channel origin.
  Future<Either<NetworkExceptions, Unit>> addScannedProductToCart(
    String code,
    CodeScanVia via,
  );

  Future<Either<NetworkExceptions, StoreProductsPage>> getVendorProducts(
    String vendorAccountId, {
    String? cursor,
  });
}
