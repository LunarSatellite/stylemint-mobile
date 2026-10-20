import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/widgets/cart_item_tile.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/bookings.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/domain/entities/service_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/checkout/checkout_service_guests.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/checkout/checkout_service_messages.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/widgets/service_line_widgets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import 'services_fakes.dart';

class _MockCartRepository extends Mock implements CartRepository {}

CartItem _stayItem() => serviceCart().items.single;

Future<void> _pumpTile(
  WidgetTester tester,
  CartItem item, {
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) async {
  phoneSize(tester);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CartItemTile(
          item: item,
          onIncrement: () {},
          onDecrement: () {},
          onDelete: onDelete ?? () {},
          onSaveForLater: () {},
          onEditService: onEdit,
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('a service line in the cart', () {
    testWidgets('shows its dates, guests, pay now and at the venue', (
      tester,
    ) async {
      await _pumpTile(tester, _stayItem(), onEdit: () {});
      expect(find.text('Deluxe Double'), findsOneWidget);
      expect(
        find.byKey(ServiceLineSummary.datesKey('line-stay')),
        findsOneWidget,
      );
      expect(find.text('1 room · 2 adults'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(ServiceLineSummary.payNowKey('line-stay')))
            .data,
        'Rs 2,700',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(ServiceLineSummary.payAtVenueKey('line-stay')),
            )
            .data,
        'Rs 6,300',
      );
      // One booking per line: no quantity, no save for later.
      expect(find.text('Save for later'), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byKey(CartItemTile.editServiceKey('line-stay')), findsOneWidget);
    });

    testWidgets('Change and Remove', (tester) async {
      var edits = 0;
      var deletes = 0;
      await _pumpTile(
        tester,
        _stayItem(),
        onEdit: () => edits++,
        onDelete: () => deletes++,
      );
      await tester.tap(find.byKey(CartItemTile.editServiceKey('line-stay')));
      await tester.tap(find.byKey(CartItemTile.removeServiceKey('line-stay')));
      expect(edits, 1);
      expect(deletes, 1);
    });

    testWidgets('a product line keeps its stepper', (tester) async {
      await _pumpTile(
        tester,
        CartItem(
          id: 'p-line',
          productId: 'p1',
          productName: 'Scarf',
          productImageUrl: '',
          variantName: 'Red',
          quantity: 1,
          unitPrice: npr(1200),
          isInStock: true,
        ),
      );
      expect(find.text('Save for later'), findsOneWidget);
      expect(find.text('Red'), findsOneWidget);
    });
  });

  group('the cart with stays', () {
    Future<GoRouter> pumpCart(WidgetTester tester, Cart cart) async {
      final repository = _MockCartRepository();
      when(repository.getCart).thenAnswer((_) async => right(cart));
      when(repository.getBasketOptimization).thenAnswer(
        (_) async => right(const BasketOptimization(insights: [])),
      );
      phoneSize(tester);
      final router = GoRouter(
        initialLocation: RouteNames.cart,
        routes: [
          GoRoute(path: RouteNames.cart, builder: (_, _) => const CartScreen()),
          GoRoute(
            path: RouteNames.productDetail,
            builder: (_, state) => Text('item:${state.uri}'),
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
      await settle(tester);
      return router;
    }

    testWidgets('pays the pay-now part, the rest at the venue, no shipping', (
      tester,
    ) async {
      await pumpCart(tester, serviceCart());
      expect(
        tester.widget<Text>(find.byKey(const Key('cart-checkout-amount'))).data,
        'Rs 2,700.00',
      );
      await reveal(tester, find.byKey(const Key('cart-pay-at-venue')));
      expect(find.byKey(const Key('cart-pay-now')), findsOneWidget);
      expect(find.text('Shipping'), findsNothing);
      expect(find.text('Total price'), findsOneWidget);
    });

    testWidgets('Change opens the item page to replace the line', (
      tester,
    ) async {
      await pumpCart(tester, serviceCart());
      await tapVisible(
        tester,
        find.byKey(CartItemTile.editServiceKey('line-stay')),
      );
      expect(
        find.text('item:${RouteNames.serviceItemEditPath(stayId, 'line-stay')}'),
        findsOneWidget,
      );
    });
  });

  group('checkout guests', () {
    Future<GlobalKey<CheckoutServiceGuestsState>> pumpGuests(
      WidgetTester tester,
      List<ServiceLine> lines, {
      FakeServiceCartRepository? repo,
      Map<String, String> errors = const {},
      List<List<ServiceLine>>? saved,
    }) async {
      final key = GlobalKey<CheckoutServiceGuestsState>();
      phoneSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: servicesOverrides(serviceCart: repo),
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: CheckoutServiceGuests(
                  key: key,
                  sessionId: 'session-1',
                  lines: lines,
                  lineErrors: errors,
                  onSaved: saved == null ? null : saved.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return key;
    }

    testWidgets('a stay is under the buyer\'s name; a trip names every '
        'traveller, adults then children', (tester) async {
      final repo = FakeServiceCartRepository();
      final saved = <List<ServiceLine>>[];
      final key = await pumpGuests(
        tester,
        [stayLine(), packageLine()],
        repo: repo,
        saved: saved,
      );
      // Prefilled with the buyer's name, which they can change.
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(CheckoutServiceGuests.guestKey('line-stay')),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'Sita Sharma',
      );
      await tester.enterText(
        find.byKey(CheckoutServiceGuests.guestKey('line-trip')),
        'Ram Thapa',
      );
      await tester.enterText(
        find.byKey(CheckoutServiceGuests.travellerKey('line-trip', 1)),
        'Gita Thapa',
      );
      await tester.enterText(
        find.byKey(CheckoutServiceGuests.travellerKey('line-trip', 2)),
        'Hari Thapa',
      );

      final ok = await key.currentState!.save();
      expect(ok, isTrue);
      final lines = repo.guests.single['lines']! as List<ServiceGuests>;
      expect(lines.first.guestName, 'Sita Sharma');
      expect(lines.first.travellers, isEmpty);
      final trip = lines.last;
      expect(trip.guestName, 'Ram Thapa');
      expect(trip.travellers.map((t) => t.type), [
        TravellerType.adult,
        TravellerType.adult,
        TravellerType.child,
      ]);
      expect(trip.travellers[2].fullName, 'Hari Thapa');
      expect(saved, hasLength(1));
    });

    testWidgets('a missing traveller name stops the order', (tester) async {
      final repo = FakeServiceCartRepository();
      final key = await pumpGuests(tester, [packageLine()], repo: repo);
      final ok = await key.currentState!.save();
      await tester.pump();
      expect(ok, isFalse);
      expect(repo.guests, isEmpty);
      expect(find.byKey(CheckoutServiceGuests.errorKey), findsOneWidget);
    });

    testWidgets('names already saved are not sent again', (tester) async {
      final repo = FakeServiceCartRepository();
      final key = await pumpGuests(tester, [
        stayLine(guestsComplete: true),
      ], repo: repo);
      expect(await key.currentState!.save(), isTrue);
      expect(repo.guests, isEmpty);
    });

    testWidgets('a refused name says so', (tester) async {
      final repo = FakeServiceCartRepository()
        ..guestsFailure = const ServiceFailure(
          ServiceFailureKind.rejected,
          code: 'booking.invalid',
          statusCode: 400,
        );
      final key = await pumpGuests(tester, [stayLine()], repo: repo);
      expect(await key.currentState!.save(), isFalse);
      await tester.pump();
      expect(find.textContaining('Check the guest'), findsOneWidget);
    });

    testWidgets('a line the server could not hold is marked', (tester) async {
      await pumpGuests(
        tester,
        [stayLine()],
        errors: {'line-stay': 'Sold out for these dates.'},
      );
      expect(
        find.byKey(CheckoutServiceGuests.lineErrorKey('line-stay')),
        findsOneWidget,
      );
    });
  });

  testWidgets('checkout that could not hold a stay names it', (tester) async {
    final repository = _MockCartRepository();
    when(repository.getCart).thenAnswer((_) async => right(serviceCart()));
    phoneSize(tester);
    var back = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cartRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: CheckoutServiceUnavailable(
              failure: const NetworkExceptions.validation(
                code: 'checkout.service_unavailable',
                errors: [
                  FieldErrorVm(
                    field: 'line-stay',
                    code: 'sold_out',
                    message: 'Sold out',
                  ),
                ],
              ),
              onBackToCart: () => back++,
              onRetry: () {},
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(
      tester
          .widget<Text>(
            find.byKey(CheckoutServiceUnavailable.lineKey('line-stay')),
          )
          .data,
      startsWith('Hotel Barahi: Sold out'),
    );
    await tester.tap(find.text('Back to cart'));
    expect(back, 1);
  });
}

