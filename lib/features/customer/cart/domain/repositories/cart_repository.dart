import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';

abstract interface class CartRepository {
  Future<Either<NetworkExceptions, Cart>> getCart();

  Future<Either<NetworkExceptions, BasketOptimization>> getBasketOptimization();

  Future<Either<NetworkExceptions, Cart>> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
    String? reelTagContextId,
    required String idempotencyKey,
  });

  Future<Either<NetworkExceptions, Cart>> updateCartItem({
    required String itemId,
    required int quantity,
  });

  Future<Either<NetworkExceptions, Cart>> removeCartItem(String itemId);

  Future<Either<NetworkExceptions, Cart>> applyPromo(String code);

  Future<Either<NetworkExceptions, Cart>> removePromo();

  Future<Either<NetworkExceptions, Cart>> saveForLater(String lineId);
}
