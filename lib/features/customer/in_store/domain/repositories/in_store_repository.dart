import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';

abstract interface class InStoreRepository {
  /// Published reels that tag [productId], newest first. Works signed out.
  Future<Either<NetworkExceptions, List<ProductReel>>> getProductReels(
    String productId,
  );
}
