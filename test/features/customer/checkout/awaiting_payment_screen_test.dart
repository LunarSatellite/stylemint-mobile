import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/repositories/checkout_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/awaiting_payment_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/order_success_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

class _MockCheckoutRepository extends Mock implements CheckoutRepository {}

class _MockCartRepository extends Mock implements CartRepository {}

const _sessionId = '7d1c0f2e-5b9a-4c33-9e61-0a4f8b2d9c17';
const _orderNumber = 'NK2026-00061';

const _cart = Cart(
  id: 'cart-1',
  items: [],
  subtotal: Money(amount: 0, currency: 'NPR'),
  shippingTotal: Money(amount: 0, currency: 'NPR'),
  taxTotal: Money(amount: 0, currency: 'NPR'),
  total: Money(amount: 0, currency: 'NPR'),
);

/// What the server says about the session, changed by each test, and how
/// many times the screen asked (and the cart was read).
class _Server {
  CheckoutSessionStatus status = CheckoutSessionStatus.awaitingPayment;
  String? orderNumber;
  bool readFails = false;
  int reads = 0;
  int cartReads = 0;
}

Future<_Server> _pump(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = Size(width, width <= 320 ? 568 : 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final server = _Server();
  final checkout = _MockCheckoutRepository();
  when(() => checkout.getCheckoutSession(_sessionId)).thenAnswer((_) async {
    server.reads++;
    if (server.readFails) {
      return left(const NetworkExceptions.noInternetConnection());
    }
    return right(
      CheckoutSessionProgress(
        sessionId: _sessionId,
        status: server.status,
        orderNumber: server.orderNumber,
      ),
    );
  });
  final cart = _MockCartRepository();
  when(() => cart.getCart()).thenAnswer((_) async {
    server.cartReads++;
    return right(_cart);
  });

  Widget page(String text) => Scaffold(body: Text(text));
  final router = GoRouter(
    initialLocation: RouteNames.awaitingPayment.replaceAll(
      ':sessionId',
      _sessionId,
    ),
    routes: [
      GoRoute(
        path: RouteNames.awaitingPayment,
        builder: (_, state) => MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: AwaitingPaymentScreen(
            checkoutSessionId: state.pathParameters['sessionId']!,
          ),
        ),
      ),
      // The real order-success screen, built the way the app router builds
      // it, so the test sees which view it opens in.
      GoRoute(
        path: RouteNames.orderSuccess,
        builder: (_, state) => OrderSuccessScreen(
          orderId: state.pathParameters['orderId']!,
          paymentPending: state.uri.queryParameters['paymentPending'] == '1',
        ),
      ),
      GoRoute(path: RouteNames.cart, builder: (_, _) => page('Cart page')),
      GoRoute(path: RouteNames.orders, builder: (_, _) => page('My orders')),
      GoRoute(path: RouteNames.home, builder: (_, _) => page('Home page')),
      GoRoute(
        path: RouteNames.orderDetail,
        builder: (_, _) => page('Order detail'),
      ),
    ],
  );
  addTearDown(router.dispose);

  final container = ProviderContainer(
    overrides: [
      checkoutRepositoryProvider.overrideWithValue(checkout),
      cartRepositoryProvider.overrideWithValue(cart),
    ],
  );
  addTearDown(container.dispose);
  // The cart is already loaded, as it is after a checkout: the screen must
  // refresh it once the order exists.
  container.read(cartNotifierProvider);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  // The opening animation runs past one poll interval, so a read may already
  // have happened: every test counts from here.
  server.reads = 0;
  return server;
}

/// The app goes to the background (the payment page) and comes back, through
/// the states a real device reports.
void _backToTheApp(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// Takes the screen down, then runs the clock well past every timer it had:
/// nothing may still be pending, or read the session again.
Future<void> _unmountAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(AwaitingPaymentScreen.pollWindow);
}

void main() {
  testWidgets('it waits for the payment and never calls anything placed', (
    tester,
  ) async {
    final server = await _pump(tester);
    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(find.textContaining('your order is placed as soon'), findsOneWidget);
    expect(find.textContaining('Nothing has been charged'), findsOneWidget);
    expect(find.text('Thank you'), findsNothing);
    expect(find.text('Confirmed'), findsNothing);
    expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MallStatusStepper),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
    // There is no order to open while waiting.
    expect(find.text('View order'), findsNothing);
    expect(find.text('Back to cart'), findsOneWidget);
    expect(server.reads, 0);
    await _unmountAndDrain(tester);
  });

  testWidgets('once the session reads Placed, the order opens confirmed with '
      'its number, and the cart is refreshed', (tester) async {
    final server = await _pump(tester);
    final cartReadsBefore = server.cartReads;

    // Still waiting at the first read.
    await tester.pump(AwaitingPaymentScreen.pollInterval);
    await tester.pump();
    expect(server.reads, 1);
    expect(find.text('Waiting for your payment'), findsOneWidget);

    server
      ..status = CheckoutSessionStatus.placed
      ..orderNumber = _orderNumber;
    await tester.pump(AwaitingPaymentScreen.pollInterval);
    await tester.pumpAndSettle();

    expect(server.reads, 2);
    expect(find.byType(AwaitingPaymentScreen), findsNothing);
    expect(find.byType(OrderSuccessScreen), findsOneWidget);
    expect(find.text('Thank you'), findsOneWidget);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    expect(find.text(_orderNumber), findsOneWidget);
    expect(find.text('Waiting for your payment'), findsNothing);
    expect(server.cartReads, cartReadsBefore + 1);

    // Gone from the screen: no more reads.
    await tester.pump(const Duration(seconds: 30));
    expect(server.reads, 2);
    await _unmountAndDrain(tester);
  });

  testWidgets('Placed without its order number yet keeps waiting', (
    tester,
  ) async {
    final server = await _pump(tester);
    server.status = CheckoutSessionStatus.placed;
    await tester.pump(AwaitingPaymentScreen.pollInterval);
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(find.byType(OrderSuccessScreen), findsNothing);

    server.orderNumber = _orderNumber;
    await tester.pump(AwaitingPaymentScreen.pollInterval);
    await tester.pumpAndSettle();
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  for (final ended in [
    CheckoutSessionStatus.failed,
    CheckoutSessionStatus.expired,
  ]) {
    testWidgets('once the session reads ${ended.name}, the payment did not go '
        'through, no order was placed, and it leads back to the cart', (
      tester,
    ) async {
      final server = await _pump(tester);

      server.status = ended;
      await tester.pump(AwaitingPaymentScreen.pollInterval);
      await tester.pumpAndSettle();
      expect(find.text("Payment didn't go through"), findsOneWidget);
      expect(
        find.text('No order was placed and you were not charged.'),
        findsOneWidget,
      );
      expect(find.text('Waiting for your payment'), findsNothing);
      expect(find.text('Thank you'), findsNothing);
      expect(find.byType(MallStatusStepper), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Settled: the clock moving on reads nothing more.
      final reads = server.reads;
      await tester.pump(const Duration(seconds: 30));
      expect(server.reads, reads);

      await tester.tap(find.text('Back to cart'));
      await tester.pumpAndSettle();
      expect(find.text('Cart page'), findsOneWidget);
      await _unmountAndDrain(tester);
    });
  }

  testWidgets('a failed read changes nothing; the next tick asks again', (
    tester,
  ) async {
    final server = await _pump(tester);
    server.readFails = true;
    await tester.pump(AwaitingPaymentScreen.pollInterval);
    await tester.pump();
    expect(server.reads, 1);
    expect(find.text('Waiting for your payment'), findsOneWidget);

    server
      ..readFails = false
      ..status = CheckoutSessionStatus.placed
      ..orderNumber = _orderNumber;
    await tester.pump(AwaitingPaymentScreen.pollInterval);
    await tester.pumpAndSettle();
    expect(server.reads, 2);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  testWidgets('after the polling window it offers to check again and the '
      'cart', (tester) async {
    final server = await _pump(tester);

    await tester.pump(AwaitingPaymentScreen.pollWindow);
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.text('Back to cart'), findsOneWidget);

    // Stopped: the clock moving on reads nothing more.
    final reads = server.reads;
    await tester.pump(const Duration(seconds: 30));
    expect(server.reads, reads);

    server
      ..status = CheckoutSessionStatus.placed
      ..orderNumber = _orderNumber;
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(server.reads, reads + 1);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  testWidgets('"Back to cart" while still waiting opens the cart', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pump(AwaitingPaymentScreen.pollWindow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to cart'));
    await tester.pumpAndSettle();
    expect(find.text('Cart page'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  testWidgets('coming back to the app checks at once', (tester) async {
    final server = await _pump(tester);
    expect(server.reads, 0);

    server
      ..status = CheckoutSessionStatus.placed
      ..orderNumber = _orderNumber;
    _backToTheApp(tester);
    await tester.pumpAndSettle();
    expect(server.reads, 1);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  testWidgets('coming back after the window lapsed polls again', (
    tester,
  ) async {
    final server = await _pump(tester);
    await tester.pump(AwaitingPaymentScreen.pollWindow);
    await tester.pumpAndSettle();
    expect(find.text('Check again'), findsOneWidget);
    final reads = server.reads;

    _backToTheApp(tester);
    await tester.pump();
    expect(server.reads, reads + 1);
    expect(find.text('Check again'), findsNothing);

    await tester.pump(AwaitingPaymentScreen.pollInterval);
    await tester.pump();
    expect(server.reads, reads + 2);
    await _unmountAndDrain(tester);
  });

  testWidgets('polling stops when the screen goes away', (tester) async {
    final server = await _pump(tester);
    await tester.pump(AwaitingPaymentScreen.pollInterval);
    await tester.pump();
    expect(server.reads, 1);

    await _unmountAndDrain(tester);
    expect(server.reads, 1);
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow — ${width.toInt()}dp, text ×$scale', (
        tester,
      ) async {
        final server = await _pump(tester, width: width, textScale: scale);
        expect(tester.takeException(), isNull);
        // The longer still-waiting copy, with two buttons.
        await tester.pump(AwaitingPaymentScreen.pollWindow);
        await tester.pumpAndSettle();
        expect(find.text('Check again'), findsOneWidget);
        expect(tester.takeException(), isNull);
        // And the failed view.
        server.status = CheckoutSessionStatus.failed;
        await tester.tap(find.text('Check again'));
        await tester.pumpAndSettle();
        expect(find.text("Payment didn't go through"), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _unmountAndDrain(tester);
      });
    }
  }
}
