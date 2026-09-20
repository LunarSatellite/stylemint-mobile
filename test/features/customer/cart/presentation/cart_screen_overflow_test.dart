import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockCartRepository extends Mock implements CartRepository {}

Money _npr(double a) => Money(amount: a, currency: 'NPR');

/// A cart whose grand total is long enough to matter. The bill card's
/// "Grand Total" row overflowed by 288px at 320dp x 1.3 before the fix.
final _cart = Cart(
  id: 'cart-1',
  items: [
    CartItem(
      id: 'line-1',
      productId: 'prod-1',
      productName: 'Hand-loomed pashmina overcoat',
      productImageUrl: 'https://example.test/coat.jpg',
      variantName: 'L / Charcoal',
      quantity: 2,
      unitPrice: _npr(62250),
      isInStock: true,
    ),
  ],
  subtotal: _npr(124500),
  shippingTotal: _npr(1200),
  taxTotal: _npr(16185),
  total: _npr(141885),
);

void main() {
  testWidgets('CartScreen does not overflow at 320dp with text at 1.3x', (
    tester,
  ) async {
    final repository = _MockCartRepository();
    when(repository.getCart).thenAnswer((_) async => right(_cart));
    when(repository.getBasketOptimization).thenAnswer(
      (_) async => right(const BasketOptimization(insights: [])),
    );

    await tester.binding.setSurfaceSize(const Size(320, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final router = GoRouter(
      initialLocation: RouteNames.cart,
      routes: [
        GoRoute(path: RouteNames.cart, builder: (_, _) => const CartScreen()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 2400),
              textScaler: TextScaler.linear(1.3),
            ),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The total shrinks to fit; it is never ellipsised away.
    expect(find.text('Grand Total'), findsOneWidget);
    expect(find.textContaining('141,885'), findsWidgets);
  });
}
