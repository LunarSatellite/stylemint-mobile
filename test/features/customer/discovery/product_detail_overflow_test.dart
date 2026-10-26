import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_detail_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/product_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../../../smoke/fake_api_client.dart';

class _MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

class _MockCartRepository extends Mock implements CartRepository {}

/// A discounted product with a named variant, so the price row carries two
/// prices and a unit suffix. Three rows on this screen overflowed at
/// 320dp x 1.3 before the fix: the name/price row (400px), the "Sold By"
/// row (47px, with the seller block squeezed to zero width) and the
/// "Customer Reviews" header (310px).
const _product = ProductDetail(
  id: 'p1',
  name: 'Hand-loomed pashmina overcoat',
  description: 'Woven in Kathmandu.',
  images: [],
  price: Money(amount: 62250, currency: 'NPR'),
  compareAtPrice: Money(amount: 124500, currency: 'NPR'),
  rating: 4.8,
  reviewCount: 214,
  vendorId: 'v1',
  vendorName: 'Himalayan Weaves',
  vendorAvatarUrl: '',
  isInStock: true,
  stockCount: 6,
  variants: [
    ProductVariant(
      id: 'v-l',
      name: 'Large',
      values: ['Large'],
      type: 'size',
    ),
  ],
  specifications: {},
  shippingInfo: 'Ships in 2 days',
  isSaved: false,
  isInCart: false,
);

const _zero = Money(amount: 0, currency: 'NPR');

/// The cart holding two of [_product]: the bar shows the in-cart counter.
const _cartWithProduct = Cart(
  id: 'cart-1',
  items: [
    CartItem(
      id: 'line-1',
      productId: 'p1',
      productName: 'Hand-loomed pashmina overcoat',
      productImageUrl: '',
      variantName: 'Large',
      quantity: 2,
      unitPrice: Money(amount: 62250, currency: 'NPR'),
      isInStock: true,
    ),
  ],
  subtotal: _zero,
  shippingTotal: _zero,
  taxTotal: _zero,
  total: _zero,
);

Future<void> _pumpInCart(WidgetTester tester, ProductDetail product) async {
  final repository = _MockDiscoveryRepository();
  when(
    () => repository.getProductDetail(any()),
  ).thenAnswer((_) async => right(product));
  final cart = _MockCartRepository();
  when(() => cart.getCart()).thenAnswer((_) async => right(_cartWithProduct));

  await tester.binding.setSurfaceSize(const Size(320, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(FakeApiClient()),
        productDetailNotifierProvider.overrideWith(
          (ref, id) => ProductDetailNotifier(repository),
        ),
        cartRepositoryProvider.overrideWithValue(cart),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(320, 3000),
            textScaler: TextScaler.linear(1.3),
          ),
          child: ProductDetailScreen(productId: 'p1'),
        ),
      ),
    ),
  );
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets(
    'the in-cart bar fits its 44dp steppers at 320dp with text at 1.3x',
    (tester) async {
      await _pumpInCart(tester, _product);

      expect(tester.takeException(), isNull);
      expect(find.text('Buy Now'), findsOneWidget);
      expect(find.byKey(ProductDetailScreen.cartCountKey), findsOneWidget);
      // Both quantity controls clear the iOS HIG minimum.
      for (final icon in [Icons.remove_rounded, Icons.add_rounded]) {
        final box = tester.getSize(
          find
              .ancestor(of: find.byIcon(icon), matching: find.byType(SizedBox))
              .first,
        );
        expect(box.width, greaterThanOrEqualTo(DesignTokens.minTouchTarget));
        expect(box.height, greaterThanOrEqualTo(DesignTokens.minTouchTarget));
      }
    },
  );

  testWidgets(
    'ProductDetailScreen does not overflow at 320dp with text at 1.3x',
    (tester) async {
      final repository = _MockDiscoveryRepository();
      when(
        () => repository.getProductDetail(any()),
      ).thenAnswer((_) async => right(_product));

      await tester.binding.setSurfaceSize(const Size(320, 3000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWithValue(FakeApiClient()),
            productDetailNotifierProvider.overrideWith(
              (ref, id) => ProductDetailNotifier(repository),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 3000),
                textScaler: TextScaler.linear(1.3),
              ),
              child: ProductDetailScreen(productId: 'p1'),
            ),
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(tester.takeException(), isNull);
      // The seller block must survive beside the "Ask a question" button.
      expect(find.text('Sold By'), findsOneWidget);
      expect(find.text('Himalayan Weaves'), findsOneWidget);
      // Prices shrink to fit rather than being ellipsised.
      expect(find.textContaining('62,250'), findsWidgets);
    },
  );
}
