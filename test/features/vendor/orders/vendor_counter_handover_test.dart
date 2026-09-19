import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_order_action_bar.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/order_fulfillment_channel.dart';

import '../../orders_test_harness.dart';

/// The seller's counter handover: what it is offered for, what it refuses,
/// and how the refusal reads.

Map<String, dynamic> _detail({
  String channel = 'StorePickup',
  String? collectedUtc,
  Map<String, dynamic>? shipTo,
}) => <String, dynamic>{
  'id': 'sub-1',
  'orderNumber': 'NK2026-00700',
  'state': 4,
  'fulfillmentChannel': channel,
  'collectedUtc': ?collectedUtc,
  'shipTo': shipTo ?? const <String, dynamic>{},
  'lines': const <Map<String, dynamic>>[],
};

void main() {
  group('OrderFulfillmentChannel.fromWire', () {
    test('reads the string, the int and the odd spellings', () {
      expect(
        OrderFulfillmentChannel.fromWire('StorePickup'),
        OrderFulfillmentChannel.storePickup,
      );
      expect(
        OrderFulfillmentChannel.fromWire('store_pickup'),
        OrderFulfillmentChannel.storePickup,
      );
      expect(
        OrderFulfillmentChannel.fromWire(2),
        OrderFulfillmentChannel.storePickup,
      );
      expect(
        OrderFulfillmentChannel.fromWire('Delivery'),
        OrderFulfillmentChannel.delivery,
      );
    });

    test('an unknown value reads as delivery, not as a collection', () {
      // The conservative direction in both senses: the counter handover is
      // refused rather than offered on an order nobody confirmed is a
      // collection, and no screen starts calling a delivery a collection.
      for (final raw in <Object?>[null, '', 'Teleport', 99, <String>[]]) {
        expect(
          OrderFulfillmentChannel.fromWire(raw),
          OrderFulfillmentChannel.delivery,
          reason: '$raw must not be read as a collection',
        );
      }
    });
  });

  group('which steps the seller is offered', () {
    test('the delivery path is unchanged when no channel is passed', () {
      // The additive guarantee: every existing caller of this function
      // passes no channel and must get exactly what it got before.
      expect(vendorActionsForState(SubOrderStateCode.packed), const [
        VendorOrderAction.handOver,
        VendorOrderAction.readyToShip,
      ]);
      expect(vendorActionsForState(SubOrderStateCode.shipped), const [
        VendorOrderAction.markDelivered,
      ]);
      expect(vendorActionsForState(SubOrderStateCode.paid), const [
        VendorOrderAction.accept,
        VendorOrderAction.reject,
      ]);
    });

    test('a collection order is never offered a courier step', () {
      const courierSteps = {
        VendorOrderAction.handOver,
        VendorOrderAction.markDelivered,
      };
      for (final state in const [
        SubOrderStateCode.paid,
        SubOrderStateCode.awaitingFulfillment,
        SubOrderStateCode.accepted,
        SubOrderStateCode.packed,
        SubOrderStateCode.readyToShip,
        SubOrderStateCode.awaitingTracking,
        SubOrderStateCode.delivered,
      ]) {
        final actions = vendorActionsForState(
          state,
          channel: OrderFulfillmentChannel.storePickup,
        );
        expect(
          actions.toSet().intersection(courierSteps),
          isEmpty,
          reason:
              'state $state offered a courier step on a collection order; '
              'the backend refuses both of them',
        );
      }
    });

    test('the counter handover is offered from every state that allows it', () {
      // SubOrder.MarkCollected is legal from Paid, AwaitingFulfillment,
      // Accepted, Packed, ReadyToShip and AwaitingTracking. A buyer who
      // walks in early is still a buyer holding the goods.
      for (final state in const [
        SubOrderStateCode.packed,
        SubOrderStateCode.readyToShip,
        SubOrderStateCode.awaitingTracking,
      ]) {
        expect(
          vendorActionsForState(
            state,
            channel: OrderFulfillmentChannel.storePickup,
          ),
          contains(VendorOrderAction.markCollected),
        );
      }
    });

    test('a delivery order is never offered the counter handover', () {
      for (var state = 1; state <= 14; state++) {
        expect(
          vendorActionsForState(state),
          isNot(contains(VendorOrderAction.markCollected)),
          reason: 'state $state offered a counter handover on a delivery',
        );
      }
    });
  });

  group('the refusal', () {
    test('names the reason on a delivery sub-order', () {
      final reason = collectionHandoverRefusal(
        state: SubOrderStateCode.packed,
        channel: OrderFulfillmentChannel.delivery,
      );

      expect(reason, isNotNull);
      expect(reason, contains('courier'));
      expect(reason, contains('collection orders'));
    });

    test('is null when the handover is genuinely available', () {
      expect(
        collectionHandoverRefusal(
          state: SubOrderStateCode.readyToShip,
          channel: OrderFulfillmentChannel.storePickup,
        ),
        isNull,
      );
    });

    test('explains a wrong status on a collection order', () {
      final reason = collectionHandoverRefusal(
        state: SubOrderStateCode.cancelled,
        channel: OrderFulfillmentChannel.storePickup,
      );

      expect(reason, contains('current status'));
    });
  });

  group('the action bar', () {
    testWidgets('shows the handover on a collection order', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          VendorOrderActionBar(
            stateCode: SubOrderStateCode.readyToShip,
            fulfillmentChannel: OrderFulfillmentChannel.storePickup,
            onAction: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hand over at counter'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('renames ready-to-ship on the collection path', (tester) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          VendorOrderActionBar(
            stateCode: SubOrderStateCode.packed,
            fulfillmentChannel: OrderFulfillmentChannel.storePickup,
            onAction: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nothing ships. "Mark as Shipped" on an order waiting at a counter
      // is the same false claim in the seller's hands.
      expect(find.text('Mark as Shipped'), findsNothing);
      expect(find.text('Ready for collection'), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('surfaces the refusal instead of hiding the control', (
      tester,
    ) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          VendorOrderActionBar(
            stateCode: SubOrderStateCode.packed,
            showCollectionRefusal: true,
            onAction: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(VendorOrderActionBar.refusalKey), findsOneWidget);
      expect(find.textContaining('delivered by courier'), findsOneWidget);
      // Drawn, and not takeable.
      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(VendorOrderActionBar.refusalKey),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
      expectNoLayoutErrors(tester);
    });

    testWidgets('at 320dp and textScaleFactor 1.3 the refusal still fits', (
      tester,
    ) async {
      setPhoneView(tester, width: 320);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            child: VendorOrderActionBar(
              stateCode: SubOrderStateCode.packed,
              showCollectionRefusal: true,
              onAction: (_) {},
            ),
          ),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(VendorOrderActionBar.refusalKey), findsOneWidget);
      expectNoLayoutErrors(tester);
    });
  });

  group('the vendor detail payload', () {
    test('reads the channel and the collected instant', () {
      final order = VendorOrderDetailDto.fromJson(
        _detail(collectedUtc: '2026-09-17T08:35:00Z'),
      ).toDomain();

      expect(order.isCollection, isTrue);
      expect(order.collectedAt, DateTime.utc(2026, 9, 17, 8, 35));
    });

    test('a collection order carries no shipping address at all', () {
      final order = VendorOrderDetailDto.fromJson(_detail()).toDomain();

      // The empty snapshot used to format into "Location saved" — a
      // destination nobody chose, on the seller's screen, as fact.
      expect(order.shippingAddress, isNull);
    });

    test('a delivery order still carries its address', () {
      final order = VendorOrderDetailDto.fromJson(
        _detail(
          channel: 'Delivery',
          shipTo: const {'addressLine1': '12 New Road', 'city': 'Kathmandu'},
        ),
      ).toDomain();

      expect(order.isCollection, isFalse);
      expect(order.shippingAddress, contains('New Road'));
    });
  });

  group('the fallback timeline cannot re-invent the courier stages', () {
    // A guard, not a widget test. _TrackingTimeline in the buyer's order
    // detail draws its stages from order state alone, with no backend
    // timeline to correct it — which is exactly how a collection order came
    // to show Shipped / In transit / Out for delivery in the first place.
    // A widget test would only prove the words are absent for one set of
    // inputs; this proves the channel is consulted at all.
    test('_TrackingTimeline selects its stages by fulfillment channel', () {
      final source = File(
        'lib/features/customer/orders/presentation/screens/'
        'order_detail_screen.dart',
      );
      expect(source.existsSync(), isTrue, reason: 'run from the package root');
      final text = source.readAsStringSync();

      expect(
        text,
        contains('collectionStages'),
        reason:
            'the fallback timeline must have a collection stage list; '
            'without one a collection order falls back onto the courier '
            'stages, which is the defect this guards',
      );
      expect(
        text,
        contains('channel.isCollection ? collectionStages : deliveryStages'),
        reason: 'the stage list must be chosen by channel, not fixed',
      );
      expect(
        text,
        contains('channel: order.fulfillmentChannel'),
        reason:
            "every buyer-facing call site must pass the order's real "
            'channel, or the default silently restores the courier stages',
      );
    });
  });
}
