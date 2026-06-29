import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/mock_cart_store.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/mock_product_catalogue.dart';

/// In-memory cart repository backed by [MockCartStore].
/// Shares the same singleton as [MockDiscoveryRepository] so items added
/// from either PDP or reel tiles all appear in the cart screen.
class MockCartRepository implements CartRepository {
  final _store = MockCartStore.instance;

  @override
  Future<Either<NetworkExceptions, Cart>> getCart() async {
    await _delay();
    return right(_store.toCart());
  }

  @override
  Future<Either<NetworkExceptions, Cart>> addToCart({
    required String productId,
    required int quantity,
    String? variantId,
    required String idempotencyKey,
  }) async {
    await _delay(ms: 400);
    final product = kMockProductCatalogue[productId];
    if (product == null) return left(const NetworkExceptions.notFound());
    _store.addOrIncrement(
      productId: productId,
      productName: product.name,
      imageUrl: product.images.first,
      price: product.price,
      quantity: quantity,
    );
    return right(_store.toCart());
  }

  @override
  Future<Either<NetworkExceptions, Cart>> updateCartItem({
    required String itemId,
    required int quantity,
  }) async {
    await _delay(ms: 300);
    _store.updateQuantity(itemId, quantity);
    return right(_store.toCart());
  }

  @override
  Future<Either<NetworkExceptions, Cart>> removeCartItem(
    String itemId,
  ) async {
    await _delay(ms: 300);
    _store.remove(itemId);
    return right(_store.toCart());
  }

  Future<void> _delay({int ms = 500}) =>
      Future<void>.delayed(Duration(milliseconds: ms));
}
