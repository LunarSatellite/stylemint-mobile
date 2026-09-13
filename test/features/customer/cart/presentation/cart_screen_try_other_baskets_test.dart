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

const _zero = Money(amount: 0, currency: 'NPR');

const _cartWithItems = Cart(
  id: 'cart-1',
  items: [
    CartItem(
      id: 'line-1',
      productId: 'prod-1',
      productName: 'Linen shirt',
      productImageUrl: 'https://example.test/shirt.jpg',
      variantName: 'M / White',
      quantity: 1,
      unitPrice: Money(amount: 2500, currency: 'NPR'),
      isInStock: true,
    ),
  ],
  subtotal: Money(amount: 2500, currency: 'NPR'),
  shippingTotal: _zero,
  taxTotal: Money(amount: 325, currency: 'NPR'),
  total: Money(amount: 2825, currency: 'NPR'),
);

const _emptyCart = Cart(
  id: 'cart-1',
  items: [],
  subtotal: _zero,
  shippingTotal: _zero,
  taxTotal: _zero,
  total: _zero,
);

void main() {
  late _MockCartRepository repository;

  setUp(() {
    repository = _MockCartRepository();
    when(() => repository.getBasketOptimization()).thenAnswer(
      (_) async => right(const BasketOptimization(insights: [])),
    );
  });

  Future<void> pumpCart(WidgetTester tester, Cart cart) async {
    when(() => repository.getCart()).thenAnswer((_) async => right(cart));
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: RouteNames.cart,
      routes: [
        GoRoute(path: RouteNames.cart, builder: (_, _) => const CartScreen()),
        GoRoute(
          path: RouteNames.cartScenarios,
          builder: (_, _) => const Scaffold(body: Text('Scenarios page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a cart with items offers "Try other baskets" and opens it', (
    tester,
  ) async {
    await pumpCart(tester, _cartWithItems);

    expect(find.text('Try other baskets'), findsOneWidget);

    await tester.tap(find.text('Try other baskets'));
    await tester.pumpAndSettle();

    expect(find.text('Scenarios page'), findsOneWidget);
  });

  testWidgets('an empty cart does not offer it', (tester) async {
    await pumpCart(tester, _emptyCart);

    expect(find.text('Your cart is empty. Start shopping!'), findsOneWidget);
    expect(find.text('Try other baskets'), findsNothing);
  });

  test('the scenarios route sits under the cart route', () {
    expect(RouteNames.cartScenarios, '/cart/scenarios');
  });
}
