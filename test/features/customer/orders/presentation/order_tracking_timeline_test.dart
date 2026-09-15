import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_timeline_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/kathmandu_time.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_tracking_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/tracking_step_list.dart';

import '../../../orders_test_harness.dart';
import '../data/order_timeline_dto_test.dart' show contractTimelineJson;

SubOrderTimeline _contractSubOrder() =>
    OrderTimelineDto.fromJson(contractTimelineJson).toDomain().subOrders.single;

SubOrderTimeline _sub({
  required BuyerTimelineStep current,
  required List<TimelineStep> steps,
  bool terminal = false,
  String? vendor,
  DateTime? eta,
}) => SubOrderTimeline(
  subOrderId: 's-${current.name}',
  vendorAccountId: 'v',
  vendorName: vendor,
  itemsCount: 1,
  currentStep: current,
  isTerminal: terminal,
  estimatedDeliveryUtc: eta,
  steps: steps,
);

TimelineStep _step(
  BuyerTimelineStep step,
  TimelineStepStatus status, {
  DateTime? at,
  String? note,
}) => TimelineStep(
  step: step,
  key: step.name,
  status: status,
  occurredUtc: at,
  note: note,
);

void main() {
  group('Kathmandu time', () {
    test('formats in UTC+05:45 across midnight', () {
      // 20:00 UTC on the 16th is 01:45 on the 17th in Kathmandu.
      expect(
        formatNptDateTime(DateTime.utc(2026, 9, 16, 20)),
        'Thu 17 Sep, 1:45 AM',
      );
      expect(formatNptWeekday(DateTime.utc(2026, 9, 16, 20)), 'Thu 17 Sep');
    });
  });

  group('OrderTrackingTimeline', () {
    testWidgets('renders done, current and upcoming steps with the ETA', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(timeline: _contractSubOrder()),
          ),
        ),
      );

      // ETA in Kathmandu: 12:00 UTC on 17 Sep 2026 is a Thursday.
      expect(find.text('Arriving by Thu 17 Sep'), findsOneWidget);
      expect(find.text('StyleMint Delivery · SM-D-00012847'), findsOneWidget);
      // Current step: pill, headline, hint and handover note.
      expect(find.text('Picked up'), findsOneWidget);
      expect(find.text('With the courier'), findsOneWidget);
      expect(find.text('Your parcel is with the courier.'), findsOneWidget);
      expect(find.text('Given to rider Ram at the gate'), findsOneWidget);
      // 10:00 UTC -> 3:45 PM NPT.
      expect(find.text('Tue 15 Sep, 3:45 PM'), findsOneWidget);

      final steps = OrderTrackingTimeline.stepsFor(_contractSubOrder());
      expect(steps.map((s) => s.state), [
        TrackingStepState.done,
        TrackingStepState.done,
        TrackingStepState.done,
        TrackingStepState.current,
        TrackingStepState.upcoming,
        TrackingStepState.upcoming,
        TrackingStepState.upcoming,
      ]);
      expect(
        find.bySemanticsLabel(
          RegExp('^Picked up by the courier, current step'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('^Delivered, upcoming')),
        findsOneWidget,
      );
    });

    testWidgets('hides the ETA when unknown or terminal', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(
              timeline: _sub(
                current: BuyerTimelineStep.delivered,
                terminal: true,
                eta: DateTime.utc(2026, 9, 17, 12),
                steps: [
                  _step(BuyerTimelineStep.placed, TimelineStepStatus.done),
                  _step(BuyerTimelineStep.delivered, TimelineStepStatus.done),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Arriving by'), findsNothing);
      // Pill, headline and the final step row.
      expect(find.text('Delivered'), findsNWidgets(3));
    });

    testWidgets('cancelled branch shows the seller note in the error tone', (
      tester,
    ) async {
      setPhoneView(tester);
      final timeline = _sub(
        current: BuyerTimelineStep.cancelled,
        terminal: true,
        steps: [
          _step(
            BuyerTimelineStep.placed,
            TimelineStepStatus.done,
            at: DateTime.utc(2026, 9, 15, 8),
          ),
          _step(
            BuyerTimelineStep.cancelled,
            TimelineStepStatus.done,
            at: DateTime.utc(2026, 9, 15, 9),
            note: 'Sold out this morning',
          ),
        ],
      );
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(timeline: timeline),
          ),
        ),
      );

      expect(find.text('Order cancelled'), findsOneWidget);
      expect(find.text('Sold out this morning'), findsOneWidget);
      expect(
        OrderTrackingTimeline.stepsFor(timeline).last.tone,
        TrackingStepTone.negative,
      );
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('returned branch uses the return marker', (tester) async {
      setPhoneView(tester);
      final timeline = _sub(
        current: BuyerTimelineStep.returned,
        terminal: true,
        steps: [
          _step(BuyerTimelineStep.delivered, TimelineStepStatus.done),
          _step(BuyerTimelineStep.returned, TimelineStepStatus.done),
        ],
      );
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(timeline: timeline),
          ),
        ),
      );

      expect(find.text('Returned'), findsWidgets);
      expect(find.byIcon(Icons.keyboard_return_rounded), findsOneWidget);
    });

    testWidgets('one card per sub-order with vendor names when several', (
      tester,
    ) async {
      setPhoneView(tester);
      final order = OrderTimeline(
        orderNumber: 'NK2026-00412',
        orderState: 3,
        placedUtc: DateTime.utc(2026, 9, 15),
        subOrders: [
          _contractSubOrder(),
          _sub(
            current: BuyerTimelineStep.confirmed,
            vendor: 'Kathmandu Atelier',
            steps: [
              _step(BuyerTimelineStep.placed, TimelineStepStatus.done),
              _step(BuyerTimelineStep.confirmed, TimelineStepStatus.current),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(child: OrderTimelineSection(timeline: order)),
        ),
      );

      expect(find.byType(OrderTrackingTimeline), findsNWidgets(2));
      expect(find.text('FROM MINT GOODS · 2 ITEMS'), findsOneWidget);
      expect(find.text('FROM KATHMANDU ATELIER · 1 ITEM'), findsOneWidget);
    });

    testWidgets('a single sub-order has no vendor header', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTimelineSection(
              timeline: OrderTimelineDto.fromJson(
                contractTimelineJson,
              ).toDomain(),
            ),
          ),
        ),
      );

      expect(find.text('TRACKING'), findsOneWidget);
      expect(find.textContaining('FROM '), findsNothing);
    });

    testWidgets('no overflow at 320dp with text ×1.3', (tester) async {
      setPhoneView(tester, width: 320);
      final order = OrderTimeline(
        orderNumber: 'NK2026-00412',
        orderState: 3,
        placedUtc: DateTime.utc(2026, 9, 15),
        subOrders: [
          _contractSubOrder(),
          _sub(
            current: BuyerTimelineStep.outForDelivery,
            vendor: 'A seller with a rather long brand name for small phones',
            eta: DateTime.utc(2026, 9, 17, 12),
            steps: [
              for (final s in BuyerTimelineStep.values.take(5))
                _step(
                  s,
                  TimelineStepStatus.done,
                  at: DateTime.utc(2026, 9, 15),
                ),
              _step(
                BuyerTimelineStep.outForDelivery,
                TimelineStepStatus.current,
                note: 'Rider will call before arriving at the building gate',
              ),
              _step(BuyerTimelineStep.delivered, TimelineStepStatus.upcoming),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: OrderTimelineSection(timeline: order),
          ),
          textScale: 1.3,
        ),
      );

      expectNoLayoutErrors(tester);
    });
  });
}
