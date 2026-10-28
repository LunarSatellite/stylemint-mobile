import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/screens/order_success_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _orderNumber = 'NK2026-00015';
const _money = Money(amount: 1100, currency: 'NPR');

/// What the server says about the order, changed by each test, and how many
/// times the screen asked.
class _Server {
  OrderTrackStatus status = OrderTrackStatus.awaitingPayment;
  int reads = 0;
}

OrderDetail _order(OrderTrackStatus status) => OrderDetail(
  id: 'order-id',
  orderNumber: _orderNumber,
  status: status,
  placedAt: DateTime.utc(2026, 10, 28),
  estimatedDelivery: DateTime.utc(2026, 11, 4),
  items: const [],
  subtotal: _money,
  shipping: const Money(amount: 0, currency: 'NPR'),
  tax: const Money(amount: 0, currency: 'NPR'),
  total: _money,
  shippingAddress: 'Kathmandu, Nepal',
  paymentMethod: 'eSewa',
  canCancel: true,
  canReturn: false,
);

Future<_Server> _pump(
  WidgetTester tester, {
  bool paymentPending = false,
  double width = 390,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = Size(width, width <= 320 ? 568 : 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final server = _Server();
  final repository = _MockOrdersRepository();
  when(() => repository.getOrderDetail(_orderNumber)).thenAnswer((_) async {
    server.reads++;
    return right(_order(server.status));
  });

  Widget page(String text) => Scaffold(body: Text(text));
  final router = GoRouter(
    initialLocation: '/order-success/$_orderNumber',
    routes: [
      GoRoute(
        path: RouteNames.orderSuccess,
        builder: (_, state) => MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: OrderSuccessScreen(
            orderId: state.pathParameters['orderId']!,
            paymentPending: paymentPending,
          ),
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

  await tester.pumpWidget(
    ProviderScope(
      overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return server;
}

/// Takes the screen down, then runs the clock well past every timer it had:
/// nothing may still be pending, or read the order again.
Future<void> _unmountAndDrain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(OrderSuccessScreen.pollWindow);
}

void main() {
  testWidgets('a confirmed order says so, and shows its number', (
    tester,
  ) async {
    final server = await _pump(tester);
    expect(find.text('Thank you'), findsOneWidget);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    expect(find.text(_orderNumber), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsWidgets);

    // Nothing is owed, so nothing is polled.
    await tester.pump(const Duration(seconds: 30));
    expect(server.reads, 0);
    await _unmountAndDrain(tester);
  });

  testWidgets('an unpaid order is waiting for its payment, never placed', (
    tester,
  ) async {
    await _pump(tester, paymentPending: true);
    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(find.textContaining('your order is placed as soon'), findsOneWidget);
    expect(find.text('Thank you'), findsNothing);
    expect(find.textContaining('Your order is placed'), findsNothing);
    expect(find.text('Placed'), findsNothing);
    expect(find.text('Confirmed'), findsNothing);
    expect(find.textContaining('Nothing has been charged'), findsOneWidget);
    // A different mark, not merely a different colour: the confirmed state's
    // tick must not appear on an unpaid order.
    expect(find.byIcon(Icons.hourglass_bottom_rounded), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MallStatusStepper),
        matching: find.byIcon(Icons.check_rounded),
      ),
      findsNothing,
    );
    await _unmountAndDrain(tester);
  });

  testWidgets('once the poll reads the order Paid, it is confirmed', (
    tester,
  ) async {
    final server = await _pump(tester, paymentPending: true);

    // Still unpaid at the first read: still waiting, now naming the method.
    await tester.pump(OrderSuccessScreen.pollInterval);
    await tester.pump();
    expect(server.reads, 1);
    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(find.textContaining('in eSewa'), findsOneWidget);

    server.status = OrderTrackStatus.preparingForShipping;
    await tester.pump(OrderSuccessScreen.pollInterval);
    await tester.pumpAndSettle();
    expect(server.reads, 2);
    expect(find.text('Thank you'), findsOneWidget);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    expect(find.text('Waiting for your payment'), findsNothing);
    expect(find.byIcon(Icons.check_rounded), findsWidgets);

    // Settled: no more reads.
    await tester.pump(const Duration(seconds: 30));
    expect(server.reads, 2);
    await _unmountAndDrain(tester);
  });

  testWidgets('once the server cancels the unpaid order, it says the payment '
      'did not go through and leads back to the cart', (tester) async {
    final server = await _pump(tester, paymentPending: true);

    server.status = OrderTrackStatus.cancelled;
    await tester.pump(OrderSuccessScreen.pollInterval);
    await tester.pumpAndSettle();
    expect(find.text("Payment didn't go through"), findsOneWidget);
    expect(
      find.text('Your order was not placed and you were not charged.'),
      findsOneWidget,
    );
    expect(find.text('Thank you'), findsNothing);
    expect(find.byType(MallStatusStepper), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    final reads = server.reads;
    await tester.pump(const Duration(seconds: 30));
    expect(server.reads, reads);

    await tester.tap(find.text('Back to cart'));
    await tester.pumpAndSettle();
    expect(find.text('Cart page'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  testWidgets('after the polling window it keeps waiting, and offers to check '
      'again and the order list', (tester) async {
    final server = await _pump(tester, paymentPending: true);

    await tester.pump(OrderSuccessScreen.pollWindow);
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
    expect(find.text('View my orders'), findsOneWidget);

    // Stopped: the clock moving on reads nothing more.
    final reads = server.reads;
    await tester.pump(const Duration(seconds: 30));
    expect(server.reads, reads);

    server.status = OrderTrackStatus.preparingForShipping;
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    expect(server.reads, reads + 1);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  testWidgets('"View my orders" opens the order list', (tester) async {
    await _pump(tester, paymentPending: true);
    await tester.pump(OrderSuccessScreen.pollWindow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('View my orders'));
    await tester.pumpAndSettle();
    expect(find.text('My orders'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  testWidgets('coming back to the app checks at once', (tester) async {
    final server = await _pump(tester, paymentPending: true);
    expect(server.reads, 0);

    server.status = OrderTrackStatus.preparingForShipping;
    final binding = tester.binding;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(server.reads, 1);
    expect(find.text('Your order is confirmed.'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  testWidgets('polling stops when the screen goes away', (tester) async {
    final server = await _pump(tester, paymentPending: true);
    await tester.pump(OrderSuccessScreen.pollInterval);
    await tester.pump();
    expect(server.reads, 1);

    await _unmountAndDrain(tester);
    expect(server.reads, 1);
  });

  test('every order state has a meaning on this screen', () {
    expect(
      OrderSuccessScreen.phaseFor(OrderTrackStatus.awaitingPayment),
      isNull,
    );
    expect(
      OrderSuccessScreen.phaseFor(OrderTrackStatus.cancelled),
      OrderSuccessPhase.paymentFailed,
    );
    for (final later in [
      OrderTrackStatus.preparingForShipping,
      OrderTrackStatus.inTransit,
      OrderTrackStatus.outForDelivery,
      OrderTrackStatus.delivered,
    ]) {
      expect(
        OrderSuccessScreen.phaseFor(later),
        OrderSuccessPhase.confirmed,
      );
    }
  });

  testWidgets('what happens next is spelled out for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester);
    expect(
      find.bySemanticsLabel(RegExp('Confirmed. completed')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Delivered. not started')),
      findsOneWidget,
    );
    await _unmountAndDrain(tester);
    semantics.dispose();
  });

  testWidgets('both actions are present and reachable', (tester) async {
    await _pump(tester);
    expect(find.text('View order'), findsOneWidget);
    expect(find.text('Keep shopping'), findsOneWidget);
    await _unmountAndDrain(tester);
  });

  for (final pending in [false, true]) {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          'no overflow — ${width.toInt()}dp, text ×$scale'
          '${pending ? ', payment pending' : ''}',
          (tester) async {
            await _pump(
              tester,
              paymentPending: pending,
              width: width,
              textScale: scale,
            );
            expect(tester.takeException(), isNull);
            if (pending) {
              // The longer still-waiting copy, too.
              await tester.pump(OrderSuccessScreen.pollWindow);
              await tester.pumpAndSettle();
              expect(find.text('Check again'), findsOneWidget);
              expect(tester.takeException(), isNull);
            }
            await _unmountAndDrain(tester);
          },
        );
      }
    }
  }
}
