import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_scenarios.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart_offer.dart';

abstract interface class CartRepository {
  Future<Either<NetworkExceptions, Cart>> getCart();

  Future<Either<NetworkExceptions, BasketOptimization>> getBasketOptimization();

  Future<Either<NetworkExceptions, CartOfferAdvice>> getOfferAdvice();

  /// "Try other baskets": read-only alternatives to the current cart, built
  /// within [budget] (when given) without touching [keepLineIds].
  Future<Either<NetworkExceptions, BasketScenarios>> getScenarios({
    double? budget,
    List<String> keepLineIds,
    List<String> excludeProductIds,
  });

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
