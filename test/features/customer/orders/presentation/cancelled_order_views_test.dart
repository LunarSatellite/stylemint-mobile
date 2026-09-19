import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/cancelled_order_views.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_badge.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

// These four blocks are shared by Order Detail and Cancel Order, which used to
// keep a copy each. Testing them here covers both screens' cancelled state.

OrderDetail _order() => OrderDetail(
  id: 'order-id',
  orderNumber: 'NK2026-00015',
  status: OrderTrackStatus.cancelled,
  placedAt: DateTime.utc(2026, 9, 11),
  estimatedDelivery: DateTime.utc(2026, 9, 14),
  items: const [],
  subtotal: const Money(amount: 1000, currency: 'NPR'),
  shipping: const Money(amount: 100, currency: 'NPR'),
  tax: const Money(amount: 0, currency: 'NPR'),
  total: const Money(amount: 1100, currency: 'NPR'),
  shippingAddress: 'Kathmandu, Nepal',
  paymentMethod: 'eSewa',
  trackingNumber: 'SM-D-00000001',
  canCancel: false,
  canReturn: false,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double textScale = 1,
}) async {
  tester.view
    ..physicalSize = Size(width, width <= 320 ? 568 : 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _allFour(OrderDetail? order) => Column(
  children: [
    CancelledOrderSummary(order: order),
    const SizedBox(height: 16),
    CancellationDetailsCard(
      order: order,
      cancelledAt: DateTime.utc(2026, 9, 12, 14, 30),
    ),
    const SizedBox(height: 16),
    const CancelledTrackingStepper(),
    const SizedBox(height: 16),
    CancelledOrderHistory(
      order: order,
      cancelledAt: DateTime.utc(2026, 9, 12, 14, 30),
      note: 'Changed my mind about the colour',
    ),
  ],
);

void main() {
  testWidgets('the state leads, and the refund is unambiguous', (tester) async {
    await _pump(tester, _allFour(_order()));

    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Order total'), findsOneWidget);
    // Signed, glyphed and named — a refund can never read as a charge.
    expect(find.text('+Rs 1,100.00'), findsOneWidget);
    expect(find.byIcon(Icons.south_west_rounded), findsOneWidget);
    expect(find.text('Back to eSewa'), findsOneWidget);
  });

  testWidgets('cancelled is carried by a mark, not only by red', (
    tester,
  ) async {
    await _pump(tester, _allFour(_order()));
    expect(
      find.descendant(
        of: find.byType(CancelledOrderSummary),
        matching: find.byIcon(
          OrderStatusBadge.iconFor(OrderTrackStatus.cancelled),
        ),
      ),
      findsOneWidget,
    );
    // The stopped stage ends the rail with a cross.
    expect(find.byKey(const ValueKey('delivery-stage-icon-2')), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsWidgets);
  });

  testWidgets('every step says its state in words', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _allFour(_order()));
    expect(
      find.bySemanticsLabel(RegExp('Order cancelled. failed')),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel(RegExp('Order placed. completed')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets("the buyer's own reason is what the history shows", (
    tester,
  ) async {
    await _pump(tester, _allFour(_order()));
    expect(find.text('Changed my mind about the colour'), findsOneWidget);
  });

  testWidgets('a missing order degrades to the state alone', (tester) async {
    await _pump(tester, _allFour(null));
    expect(find.text('Cancelled'), findsOneWidget);
    // No order means no figures: nothing is invented to fill the card.
    expect(find.byType(MallMoneyLedger), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow — ${width.toInt()}dp, text ×$scale', (
        tester,
      ) async {
        await _pump(tester, _allFour(_order()), width: width, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
