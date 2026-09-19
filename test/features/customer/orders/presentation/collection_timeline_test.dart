import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_timeline_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_tracking_timeline.dart';

import '../../../orders_test_harness.dart';

/// The buyer's collection timeline, and the one thing it must never say.
///
/// A collection order has no shipment, no transit and no last mile. Showing
/// Shipped / In transit / Out for delivery on one was a live defect: three
/// courier journeys nobody performed, rendered as completed fact to someone
/// who is going to walk into a shop. The backend stopped producing those
/// steps. These tests stop the client from producing them on its own —
/// because the client can, and used to: the fallback timeline draws its
/// stages from order state with no backend timeline to correct it.

/// The exact words a buyer must never read on a collection order.
const _courierWords = [
  'Shipped',
  'In transit',
  'Out for delivery',
  'Picked up by the courier',
  'With the courier',
  'On its way',
  'Arriving today',
];

TimelineStep _step(
  BuyerTimelineStep step,
  TimelineStepStatus status, {
  DateTime? at,
}) => TimelineStep(
  step: step,
  key: step.name,
  status: status,
  occurredUtc: at,
);

/// The five steps the backend actually sends for a collected order.
List<TimelineStep> _collectionSteps({DateTime? collectedAt}) => [
  _step(BuyerTimelineStep.placed, TimelineStepStatus.done),
  _step(BuyerTimelineStep.confirmed, TimelineStepStatus.done),
  _step(BuyerTimelineStep.preparing, TimelineStepStatus.done),
  _step(BuyerTimelineStep.readyForCollection, TimelineStepStatus.done),
  _step(BuyerTimelineStep.collected, TimelineStepStatus.done, at: collectedAt),
];

SubOrderTimeline _collection({
  DateTime? collectedAt,
  String? locationName,
  BuyerTimelineStep current = BuyerTimelineStep.collected,
  List<TimelineStep>? steps,
  String? carrier,
  String? trackingNumber,
  DateTime? eta,
}) => SubOrderTimeline(
  subOrderId: 'sub-collection',
  vendorAccountId: 'v',
  itemsCount: 1,
  currentStep: current,
  isTerminal: current == BuyerTimelineStep.collected,
  fulfillmentChannel: OrderFulfillmentChannel.storePickup,
  collectedUtc: collectedAt,
  collectionLocationName: locationName,
  carrier: carrier,
  trackingNumber: trackingNumber,
  estimatedDeliveryUtc: eta,
  steps: steps ?? _collectionSteps(collectedAt: collectedAt),
);

void main() {
  group('the collection path never shows a courier step', () {
    test('no backend step for a collection order is courier-only', () {
      final steps = _collectionSteps().map((s) => s.step).toSet();

      expect(
        steps.intersection(BuyerTimelineStep.courierOnly),
        isEmpty,
        reason:
            'Picked up, In transit and Out for delivery describe a courier. '
            'A collection order never meets one.',
      );
    });

    testWidgets('renders none of the courier words on a collection order', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(
              timeline: _collection(
                collectedAt: DateTime.utc(2026, 9, 17, 8, 35),
                locationName: 'Durbar Marg Flagship',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      for (final word in _courierWords) {
        expect(
          find.textContaining(word, findRichText: true),
          findsNothing,
          reason: '"$word" describes a journey nobody made on this order',
        );
      }
      expect(find.text('Collected in store'), findsOneWidget);
      expect(find.text('Ready for collection'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('a delivery order still shows the courier steps', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(
              timeline: SubOrderTimeline(
                subOrderId: 'sub-delivery',
                vendorAccountId: 'v',
                itemsCount: 1,
                currentStep: BuyerTimelineStep.inTransit,
                isTerminal: false,
                steps: [
                  _step(BuyerTimelineStep.placed, TimelineStepStatus.done),
                  _step(BuyerTimelineStep.pickedUp, TimelineStepStatus.done),
                  _step(
                    BuyerTimelineStep.inTransit,
                    TimelineStepStatus.current,
                  ),
                  _step(
                    BuyerTimelineStep.outForDelivery,
                    TimelineStepStatus.upcoming,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The delivery path is untouched: this is the regression that would
      // fire if the fix were applied to everyone instead of to collections.
      expect(find.text('In transit'), findsWidgets);
      expect(find.text('Picked up by the courier'), findsOneWidget);
      expect(find.text('Out for delivery'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });
  });

  group('collected at', () {
    test('names the counter when the backend resolved one', () {
      final line = OrderTrackingTimeline.collectedLine(
        _collection(
          collectedAt: DateTime.utc(2026, 9, 17, 8, 35),
          locationName: 'Durbar Marg Flagship',
        ),
      );

      expect(line, contains('Durbar Marg Flagship'));
      expect(line, contains('Collected'));
    });

    test('says when, and simply not where, when it did not', () {
      final line = OrderTrackingTimeline.collectedLine(
        _collection(collectedAt: DateTime.utc(2026, 9, 17, 8, 35)),
      );

      expect(line, isNotNull);
      expect(line, contains('Collected'));
      // No "Store", no "Pickup point", no seller name standing in.
      expect(line, isNot(contains('·')));
    });

    test('is absent entirely on a delivery, and before collection', () {
      expect(OrderTrackingTimeline.collectedLine(_collection()), isNull);
      expect(
        OrderTrackingTimeline.collectedLine(
          const SubOrderTimeline(
            subOrderId: 's',
            vendorAccountId: 'v',
            itemsCount: 1,
            currentStep: BuyerTimelineStep.delivered,
            isTerminal: true,
            steps: [],
          ),
        ),
        isNull,
      );
    });

    testWidgets('a blank counter name from the wire renders nothing', (
      tester,
    ) async {
      setPhoneView(tester);
      final sub = OrderTimelineDto.fromJson(<String, dynamic>{
        'orderNumber': 'NK2026-00700',
        'placedUtc': '2026-09-15T08:00:00Z',
        'subOrders': [
          {
            'subOrderId': 's1',
            'vendorAccountId': 'v1',
            'itemsCount': 1,
            'currentStep': 11,
            'isTerminal': true,
            'fulfillmentChannel': 'StorePickup',
            'collectedUtc': '2026-09-17T08:35:00Z',
            'collectionLocationName': '   ',
            'steps': const <Map<String, dynamic>>[],
          },
        ],
      }).toDomain().subOrders.single;

      expect(sub.collectionLocationName, isNull);
      expect(sub.isCollection, isTrue);

      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(child: OrderTrackingTimeline(timeline: sub)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('timeline-collected-at')),
        findsOneWidget,
      );
      expectNoLayoutErrors(tester);
    });
  });

  group('no delivery promise on a collection order', () {
    testWidgets('an ETA and a carrier are not rendered', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(
              timeline: _collection(
                current: BuyerTimelineStep.readyForCollection,
                carrier: 'Aramex',
                trackingNumber: 'SM-D-123',
                eta: DateTime.utc(2026, 9, 18, 6),
                steps: [
                  _step(BuyerTimelineStep.placed, TimelineStepStatus.done),
                  _step(
                    BuyerTimelineStep.readyForCollection,
                    TimelineStepStatus.current,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Arriving by'), findsNothing);
      expect(find.textContaining('Aramex'), findsNothing);
      expect(find.textContaining('SM-D-123'), findsNothing);
      expectNoLayoutErrors(tester);
    });
  });

  group('a collection order has no shipping address', () {
    test('the empty snapshot is not formatted into "Location saved"', () {
      final order = OrderDetailDto.fromJson(<String, dynamic>{
        'id': 'o1',
        'orderNumber': 'NK2026-00700',
        'state': 3,
        'placedUtc': '2026-09-15T08:00:00Z',
        // Exactly what checkout records for a pickup order: an empty
        // ShippingAddressSnapshot, because there is no address.
        'shipTo': const <String, dynamic>{},
        'subOrders': [
          {
            'id': 's1',
            'state': 4,
            'fulfillmentChannel': 'StorePickup',
            'lines': const <Map<String, dynamic>>[],
          },
        ],
      }).toDomain();

      expect(order.isCollection, isTrue);
      expect(order.shippingAddress, isEmpty);
      expect(order.shippingAddress, isNot('Location saved'));
    });

    test('a delivery order still formats its address', () {
      final order = OrderDetailDto.fromJson(<String, dynamic>{
        'id': 'o2',
        'orderNumber': 'NK2026-00701',
        'state': 3,
        'placedUtc': '2026-09-15T08:00:00Z',
        'shipTo': const {'addressLine1': '12 New Road', 'city': 'Kathmandu'},
        'subOrders': const [
          {'id': 's1', 'state': 4, 'lines': <Map<String, dynamic>>[]},
        ],
      }).toDomain();

      expect(order.isCollection, isFalse);
      expect(order.shippingAddress, '12 New Road, Kathmandu');
    });
  });

  group('320dp at textScaleFactor 1.3', () {
    testWidgets('the collection card lays out without overflow', (
      tester,
    ) async {
      setPhoneView(tester, width: 320);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: OrderTrackingTimeline(
              timeline: _collection(
                collectedAt: DateTime.utc(2026, 9, 17, 8, 35),
                locationName: 'Durbar Marg Flagship Counter Two',
              ),
              showVendor: true,
            ),
          ),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('timeline-collected-at')),
        findsOneWidget,
      );
      expectNoLayoutErrors(tester);
    });
  });
}
