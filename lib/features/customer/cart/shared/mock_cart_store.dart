import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Singleton in-memory cart shared by MockCartRepository and
/// MockDiscoveryRepository so add-to-cart from both PDP and reel tiles
/// lands in the same cart that CartScreen reads.
class MockCartStore {
  MockCartStore._();
  static final instance = MockCartStore._();

  final List<CartItem> _items = [];
  int _nextId = 1;

  List<CartItem> get items => List.unmodifiable(_items);

  void addOrIncrement({
    required String productId,
    required String productName,
    required String imageUrl,
    required Money price,
    required int quantity,
    String? variantName,
    String? creatorHandle,
  }) {
    final idx = _items.indexWhere((i) => i.productId == productId);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(quantity: _items[idx].quantity + quantity);
    } else {
      _items.add(CartItem(
        id: 'ci_${_nextId++}',
        productId: productId,
        productName: productName,
        productImageUrl: imageUrl,
        variantName: variantName ?? '',
        quantity: quantity,
        unitPrice: price,
        isInStock: true,
        creatorHandle: creatorHandle,
      ));
    }
  }

  void updateQuantity(String itemId, int quantity) {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return;
    if (quantity <= 0) {
      _items.removeAt(idx);
    } else {
      _items[idx] = _items[idx].copyWith(quantity: quantity);
    }
  }

  void remove(String itemId) => _items.removeWhere((i) => i.id == itemId);

  Cart toCart() {
    final subtotal = _items.fold<double>(
      0,
      (sum, i) => sum + i.unitPrice.amount * i.quantity,
    );
    const currency = 'NPR';
    final shipping = _items.isEmpty ? 0.0 : 150.0;
    final tax = subtotal * 0.13;
    return Cart(
      id: 'mock_cart_001',
      items: List.of(_items),
      subtotal: Money(amount: subtotal, currency: currency),
      shippingTotal: Money(amount: shipping, currency: currency),
      taxTotal: Money(amount: tax, currency: currency),
      total: Money(amount: subtotal + shipping + tax, currency: currency),
      supportedCreatorsCount:
          _items.where((i) => i.creatorHandle != null).length,
    );
  }
}
