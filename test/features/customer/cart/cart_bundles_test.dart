import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/widgets/cart_bundle_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../bundles/bundle_fixtures.dart';

class _MockCartRepository extends Mock
    implements CartRepository, CartBundlesRepository {}

Cart _cart({
  bool purchasable = true,
  bool withBundle = true,
  List<Map<String, dynamic>> notices = const [],
}) => CartDto.fromJson(
  bundleCartWire(
    purchasable: purchasable,
    withBundle: withBundle,
    notices: notices,
  ),
).toDomain();

void main() {
  group('cart wire (contract §B8)', () {
    test('bundle lines, groups and notices are read', () {
      final cart = _cart(
        notices: [
          {'code': 'bundle_broken', 'bundleTitle': 'Trekking kit'},
          {'kind': 1, 'productTitleSnapshot': 'Old item'},
        ],
      );
      expect(cart.hasBundleLines, isTrue);
      expect(cart.bundleGroups, hasLength(1));
      final group = cart.bundleGroups.single;
      expect(group.title, 'Trekking kit');
      expect(group.saving.amount, 1300);
      expect(cart.bundleLines('g-1').map((l) => l.id), ['l-jacket', 'l-socks']);
      expect(cart.looseItems.map((l) => l.id), ['l-cap']);
      final jacket = cart.items.first;
      expect(jacket.bundleListUnitPrice?.amount, 12000);
      expect(jacket.vendorName, 'Peak Gear');
      // Only the coded notice is a bundle notice.
      expect(cart.notices, hasLength(1));
      expect(cart.notices.single.isBundleBroken, isTrue);
    });

    test('a cart from before bundles reads exactly as before', () {
      final cart = CartDto.fromJson({
        'accountId': 'acc-1',
        'lines': [
          {
            'lineId': 'l-1',
            'productId': 'p-1',
            'productTitleSnapshot': 'Shirt',
            'quantity': 1,
            'unitPriceAmount': 2500,
          },
        ],
        'subtotalAmount': 2500,
        'shippingAmount': 0,
        'taxAmount': 0,
        'grandTotalAmount': 2500,
      }).toDomain();
      expect(cart.hasBundleLines, isFalse);
      expect(cart.bundleGroups, isEmpty);
      expect(cart.notices, isEmpty);
      expect(cart.looseItems, hasLength(1));
    });

    test('lines without a bundles[] entry still get their card', () {
      final wire = bundleCartWire()..['bundles'] = <dynamic>[];
      final cart = CartDto.fromJson(wire).toDomain();
      final group = cart.bundleGroups.single;
      expect(group.groupId, 'g-1');
      expect(group.title, 'Trekking kit');
      expect(group.total.amount, 10800 + 900);
      expect(group.listTotal.amount, 12000 + 1000);
    });

    test('a local copy does not replay the notices', () {
      final cart = _cart(
        notices: [
          {'code': 'bundle_broken'},
        ],
      );
      expect(cart.copyWith().notices, isEmpty);
    });
  });

  group('cart screen', () {
    late _MockCartRepository repo;

    setUp(() {
      repo = _MockCartRepository();
      when(() => repo.getBasketOptimization()).thenAnswer(
        (_) async => right(const BasketOptimization(insights: [])),
      );
    });

    Future<void> pump(WidgetTester tester, Cart cart) async {
      when(() => repo.getCart()).thenAnswer((_) async => right(cart));
      tester.view
        ..physicalSize = const Size(1080, 3000)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final router = GoRouter(
        initialLocation: RouteNames.cart,
        routes: [
          GoRoute(path: RouteNames.cart, builder: (_, _) => const CartScreen()),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a bundle is one card over its lines, with its saving', (
      tester,
    ) async {
      await pump(tester, _cart());

      expect(find.byKey(CartBundleCard.cardKey('g-1')), findsOneWidget);
      expect(find.text('Trekking kit'), findsOneWidget);
      expect(find.text('You save Rs 1,300'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(CartBundleCard.cardKey('g-1')),
          matching: find.text('Down jacket'),
        ),
        findsOneWidget,
      );
      // The ordinary line keeps its own tile.
      expect(find.text('Sun cap'), findsOneWidget);
    });

    testWidgets('Unbundle keeps the lines at list price', (tester) async {
      when(() => repo.unbundle('g-1')).thenAnswer(
        (_) async => right(_cart(withBundle: false)),
      );
      await pump(tester, _cart());

      await tester.tap(find.byKey(CartBundleCard.unbundleKey('g-1')));
      await tester.pumpAndSettle();

      verify(() => repo.unbundle('g-1')).called(1);
      expect(find.byKey(CartBundleCard.cardKey('g-1')), findsNothing);
      expect(find.text('Down jacket'), findsOneWidget);
    });

    testWidgets('more bundles scales the group, never one line', (
      tester,
    ) async {
      when(() => repo.setBundleQuantity('g-1', 2)).thenAnswer(
        (_) async => right(_cart()),
      );
      await pump(tester, _cart());

      await tester.tap(find.byKey(CartBundleCard.plusKey('g-1')));
      await tester.pumpAndSettle();

      verify(() => repo.setBundleQuantity('g-1', 2)).called(1);
      verifyNever(
        () => repo.updateCartItem(
          itemId: any(named: 'itemId'),
          quantity: any(named: 'quantity'),
        ),
      );
    });

    testWidgets('removing one bundle line asks first, then the server '
        'breaks the bundle and the buyer is told', (tester) async {
      when(() => repo.removeCartItem('l-socks')).thenAnswer(
        (_) async => right(
          _cart(
            withBundle: false,
            notices: [
              {'code': 'bundle_broken', 'bundleTitle': 'Trekking kit'},
            ],
          ),
        ),
      );
      await pump(tester, _cart());

      await tester.tap(find.byKey(CartBundleCard.removeLineKey('l-socks')));
      await tester.pumpAndSettle();
      expect(find.text('Break up the bundle?'), findsOneWidget);
      await tester.tap(find.byKey(CartBundleCard.confirmBreakKey));
      await tester.pumpAndSettle();

      verify(() => repo.removeCartItem('l-socks')).called(1);
      expect(find.byKey(CartScreen.bundleBrokenKey), findsOneWidget);
      expect(find.textContaining('"Trekking kit" was split up'), findsOneWidget);
    });

    testWidgets('an unavailable bundle says why and offers buying '
        'separately', (tester) async {
      await pump(tester, _cart(purchasable: false));

      expect(find.textContaining('paused'), findsOneWidget);
      expect(find.text('Buy separately'), findsOneWidget);
      final plus = tester.widget<IconButton>(
        find.byKey(CartBundleCard.plusKey('g-1')),
      );
      expect(plus.onPressed, isNull);
    });

    testWidgets('a refused bundle change keeps the cart and explains', (
      tester,
    ) async {
      when(() => repo.removeBundle('g-1')).thenAnswer(
        (_) async => left(
          const NetworkExceptions.validation(code: 'bundle_not_purchasable'),
        ),
      );
      await pump(tester, _cart());

      await tester.tap(find.byKey(CartBundleCard.removeKey('g-1')));
      await tester.pumpAndSettle();

      expect(find.text('This bundle cannot be bought right now.'), findsOneWidget);
      expect(find.byKey(CartBundleCard.cardKey('g-1')), findsOneWidget);
    });
  });
}
