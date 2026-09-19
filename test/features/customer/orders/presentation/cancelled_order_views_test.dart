import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_event_history.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/cancelled_order_views.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

// These blocks are shared by Order Detail and Cancel Order, which used to keep
// a copy each. Testing them here covers both screens' cancelled state.
//
// Everything on screen now comes from `GET /v1/orders/{orderNumber}/events`.
// The tests below are mostly about what is NOT drawn: no stage the order did
// not reach, no sentence the backend did not send, and no timestamp derived
// from another one.

const _orderNumber = 'NK2026-00015';

OrderDetail _order() => OrderDetail(
  id: 'order-id',
  orderNumber: _orderNumber,
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

OrderEvent _event({
  required int sequence,
  required String code,
  required String statement,
  DateTime? occurredUtc,
  String source = 'order',
  String? detail,
}) => OrderEvent(
  sequence: sequence,
  code: code,
  statement: statement,
  occurredUtc: occurredUtc,
  source: source,
  detail: detail,
);

/// The common case this whole change exists for: an order that was placed and
/// then cancelled, and never went anywhere in between.
OrderEventHistory _sparse({
  List<OrderEventSource> sources = const [
    OrderEventSource(name: 'order', status: OrderEventSourceStatus.ok),
  ],
  List<OrderEvent>? events,
}) => OrderEventHistory(
  orderNumber: _orderNumber,
  orderState: 5,
  placedUtc: DateTime.utc(2026, 9, 11, 9, 15),
  events:
      events ??
      [
        _event(
          sequence: 1,
          code: 'order_placed',
          statement: 'You placed this order.',
          occurredUtc: DateTime.utc(2026, 9, 11, 9, 15),
        ),
        _event(
          sequence: 2,
          code: 'cancelled',
          statement: 'This order was cancelled.',
          occurredUtc: DateTime.utc(2026, 9, 12, 14, 30),
          source: 'cancellation_request',
          detail: 'Changed my mind about the colour',
        ),
      ],
  sources: sources,
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 390,
  double textScale = 1,
  OrderEventHistory? history,
  bool fails = false,
}) async {
  tester.view
    ..physicalSize = Size(width, width <= 320 ? 568 : 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        orderEventHistoryProvider(_orderNumber).overrideWith((ref) async {
          if (fails) throw StateError('events read failed');
          return history ?? _sparse();
        }),
      ],
      child: MaterialApp(
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
    ),
  );
  await tester.pumpAndSettle();
}

/// The headline only — "Cancelled" is also a rail label, and the two are
/// different claims: one is the order's state, the other is one recorded event.
final Finder _headline = find.descendant(
  of: find.byType(CancelledOrderSummary),
  matching: find.text('Cancelled'),
);

Widget _allFour(OrderDetail? order) => Column(
  children: [
    CancelledOrderSummary(order: order),
    const SizedBox(height: 16),
    CancellationDetailsCard(order: order),
    const SizedBox(height: 16),
    CancelledTrackingStepper(orderNumber: order?.orderNumber),
    const SizedBox(height: 16),
    CancelledOrderHistory(orderNumber: order?.orderNumber),
  ],
);

void main() {
  testWidgets('the state leads, and the refund is unambiguous', (tester) async {
    await _pump(tester, _allFour(_order()));

    expect(_headline, findsOneWidget);
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
    expect(find.byIcon(Icons.close_rounded), findsWidgets);
  });

  testWidgets('a sparse history renders a sparse timeline', (tester) async {
    await _pump(tester, _allFour(_order()));

    // Exactly the two events the endpoint sent, verbatim.
    expect(find.text('You placed this order.'), findsOneWidget);
    expect(find.text('This order was cancelled.'), findsOneWidget);

    final rail = tester
        .widget<MallTimeline>(
          find.descendant(
            of: find.byType(CancelledOrderHistory),
            matching: find.byType(MallTimeline),
          ),
        )
        .steps;
    expect(rail, hasLength(2));

    // The order never shipped, so nothing anywhere claims it did.
    for (final word in ['Shipped', 'In transit', 'Out for delivery']) {
      expect(find.text(word), findsNothing, reason: '"$word" never happened');
    }
  });

  testWidgets('the stage rail only rungs milestones that have a record', (
    tester,
  ) async {
    await _pump(tester, _allFour(_order()));
    final stepper = tester
        .widget<MallStatusStepper>(find.byType(MallStatusStepper))
        .steps;
    expect(stepper.map((s) => s.title), ['Placed', 'Cancelled']);
    expect(stepper.last.state, MallStepState.failed);
  });

  testWidgets("the buyer's own reason is what the history shows", (
    tester,
  ) async {
    await _pump(tester, _allFour(_order()));
    expect(find.text('Changed my mind about the colour'), findsOneWidget);
  });

  testWidgets('no stamp is computed — only stamps the endpoint sent appear', (
    tester,
  ) async {
    await _pump(
      tester,
      _allFour(_order()),
      history: _sparse(
        events: [
          _event(
            sequence: 1,
            code: 'order_placed',
            statement: 'You placed this order.',
            occurredUtc: DateTime.utc(2026, 9, 11, 9, 15),
          ),
          // A record with no stamp: the row appears, the stamp does not get
          // stood in for by arithmetic on its neighbour or on placedUtc.
          _event(
            sequence: 2,
            code: 'payment_confirmed',
            statement: 'Your payment was confirmed.',
          ),
        ],
      ),
    );

    final stamps = tester
        .widget<MallTimeline>(
          find.descendant(
            of: find.byType(CancelledOrderHistory),
            matching: find.byType(MallTimeline),
          ),
        )
        .steps
        .map((s) => s.timestamp)
        .toList();
    expect(stamps.where((s) => s != null), hasLength(1));
    expect(stamps.last, isNull);
  });

  testWidgets('an unknown cancellation date says so instead of guessing', (
    tester,
  ) async {
    await _pump(
      tester,
      _allFour(_order()),
      history: _sparse(
        events: [
          _event(
            sequence: 1,
            code: 'order_placed',
            statement: 'You placed this order.',
            occurredUtc: DateTime.utc(2026, 9, 11, 9, 15),
          ),
        ],
      ),
    );
    expect(find.text('Not recorded'), findsOneWidget);
  });

  group('the two kinds of silence are not drawn the same', () {
    testWidgets('empty — the source was read and had nothing to say', (
      tester,
    ) async {
      await _pump(
        tester,
        _allFour(_order()),
        history: _sparse(
          events: const [],
          sources: const [
            OrderEventSource(name: 'order', status: OrderEventSourceStatus.ok),
            OrderEventSource(
              name: 'custody_chain',
              status: OrderEventSourceStatus.empty,
            ),
          ],
        ),
      );
      expect(find.text('Nothing recorded'), findsOneWidget);
      expect(
        find.text('Nothing has been recorded against this order.'),
        findsOneWidget,
      );
      // Nothing hedges, because nothing needs hedging.
      expect(find.text('History may be incomplete'), findsNothing);
    });

    testWidgets('unavailable — we could not find out, and we say it', (
      tester,
    ) async {
      await _pump(
        tester,
        _allFour(_order()),
        history: _sparse(
          sources: const [
            OrderEventSource(name: 'order', status: OrderEventSourceStatus.ok),
            OrderEventSource(
              name: 'custody_chain',
              status: OrderEventSourceStatus.unavailable,
              note: 'The parcel handling record could not be read.',
            ),
          ],
        ),
      );
      expect(find.text('History may be incomplete'), findsOneWidget);
      expect(
        find.text('The parcel handling record could not be read.'),
        findsOneWidget,
      );
      // The one thing it must never do is claim nothing happened.
      expect(find.text('Nothing recorded'), findsNothing);
    });

    testWidgets('an unknown status is treated as unavailable, not as empty', (
      tester,
    ) async {
      expect(
        OrderEventSourceStatus.fromWire('something_new'),
        OrderEventSourceStatus.unavailable,
      );
    });
  });

  testWidgets('an unverified custody chain renders its entries flagged', (
    tester,
  ) async {
    await _pump(
      tester,
      _allFour(_order()),
      history: _sparse(
        events: [
          _event(
            sequence: 1,
            code: 'order_placed',
            statement: 'You placed this order.',
            occurredUtc: DateTime.utc(2026, 9, 11, 9, 15),
          ),
          _event(
            sequence: 2,
            code: 'handed_to_courier',
            statement: 'Your package was handed to the courier.',
            occurredUtc: DateTime.utc(2026, 9, 11, 18),
            source: 'custody_chain',
          ),
        ],
        sources: const [
          OrderEventSource(name: 'order', status: OrderEventSourceStatus.ok),
          OrderEventSource(
            name: 'custody_chain',
            status: OrderEventSourceStatus.unverified,
            note: 'The parcel handling record failed its integrity check.',
          ),
        ],
      ),
    );

    // The entry is still shown...
    expect(
      find.text('Your package was handed to the courier.'),
      findsOneWidget,
    );
    // ...flagged, and only it: the order-sourced row carries no flag.
    expect(find.text('Unverified'), findsOneWidget);
    expect(find.text('Could not be verified'), findsOneWidget);
  });

  testWidgets('a failed events call degrades without breaking the screen', (
    tester,
  ) async {
    await _pump(tester, _allFour(_order()), fails: true);

    // The rest of the order detail is untouched.
    expect(_headline, findsOneWidget);
    expect(find.text('+Rs 1,100.00'), findsOneWidget);
    expect(find.byType(MallMoneyLedger), findsOneWidget);
    // And the history says it could not be read, rather than showing a
    // plausible one or an empty one.
    expect(find.text('History unavailable'), findsOneWidget);
    expect(find.text('Nothing recorded'), findsNothing);
    expect(find.byType(MallTimeline), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a missing order degrades to the state alone', (tester) async {
    await _pump(tester, _allFour(null));
    expect(_headline, findsOneWidget);
    // No order means no figures: nothing is invented to fill the card.
    expect(find.byType(MallMoneyLedger), findsNothing);
    expect(find.byType(MallTimeline), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every step says its state in words', (tester) async {
    final semantics = tester.ensureSemantics();
    await _pump(tester, _allFour(_order()));
    expect(
      find.bySemanticsLabel(RegExp('This order was cancelled.. failed')),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel(RegExp('You placed this order.. completed')),
      findsWidgets,
    );
    semantics.dispose();
  });

  for (final width in [320.0, 390.0]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('no overflow — ${width.toInt()}dp, text ×$scale', (
        tester,
      ) async {
        await _pump(tester, _allFour(_order()), width: width, textScale: scale);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'no overflow with notices — ${width.toInt()}dp, text ×$scale',
        (tester) async {
          await _pump(
            tester,
            _allFour(_order()),
            width: width,
            textScale: scale,
            history: _sparse(
              sources: const [
                OrderEventSource(
                  name: 'order',
                  status: OrderEventSourceStatus.ok,
                ),
                OrderEventSource(
                  name: 'custody_chain',
                  status: OrderEventSourceStatus.unavailable,
                  note: 'The parcel handling record could not be read.',
                ),
                OrderEventSource(
                  name: 'sub_order_history',
                  status: OrderEventSourceStatus.unverified,
                  note: 'The seller record failed its integrity check.',
                ),
              ],
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
