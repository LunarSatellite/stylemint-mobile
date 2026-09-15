import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_timeline_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_timeline.dart';

/// The response example from docs/mall/orders-contract.md §3.
const Map<String, dynamic> contractTimelineJson = {
  'orderNumber': 'NK2026-00412',
  'orderState': 3,
  'placedUtc': '2026-09-15T08:00:00+00:00',
  'subOrders': [
    {
      'subOrderId': '5b8c',
      'vendorAccountId': '11c0',
      'vendorName': 'Mint Goods',
      'itemsCount': 2,
      'currentStep': 4,
      'isTerminal': false,
      'carrier': 'StyleMint Delivery',
      'trackingNumber': 'SM-D-00012847',
      'estimatedDeliveryUtc': '2026-09-17T12:00:00+00:00',
      'steps': [
        {
          'step': 1,
          'key': 'placed',
          'status': 1,
          'occurredUtc': '2026-09-15T08:00:00+00:00',
          'note': null,
        },
        {
          'step': 2,
          'key': 'confirmed',
          'status': 1,
          'occurredUtc': '2026-09-15T08:20:00+00:00',
          'note': null,
        },
        {
          'step': 3,
          'key': 'preparing',
          'status': 1,
          'occurredUtc': '2026-09-15T09:05:00+00:00',
          'note': null,
        },
        {
          'step': 4,
          'key': 'picked_up',
          'status': 2,
          'occurredUtc': '2026-09-15T10:00:00+00:00',
          'note': 'Given to rider Ram at the gate',
        },
        {
          'step': 5,
          'key': 'in_transit',
          'status': 3,
          'occurredUtc': null,
          'note': null,
        },
        {
          'step': 6,
          'key': 'out_for_delivery',
          'status': 3,
          'occurredUtc': null,
          'note': null,
        },
        {
          'step': 7,
          'key': 'delivered',
          'status': 3,
          'occurredUtc': null,
          'note': null,
        },
      ],
    },
  ],
};

void main() {
  group('OrderTimelineDto', () {
    test('parses the contract example', () {
      final timeline = OrderTimelineDto.fromJson(
        contractTimelineJson,
      ).toDomain();

      expect(timeline.orderNumber, 'NK2026-00412');
      expect(timeline.orderState, 3);
      expect(timeline.placedUtc, DateTime.utc(2026, 9, 15, 8));
      expect(timeline.subOrders, hasLength(1));

      final sub = timeline.subOrders.single;
      expect(sub.subOrderId, '5b8c');
      expect(sub.vendorAccountId, '11c0');
      expect(sub.vendorName, 'Mint Goods');
      expect(sub.itemsCount, 2);
      expect(sub.currentStep, BuyerTimelineStep.pickedUp);
      expect(sub.isTerminal, isFalse);
      expect(sub.carrier, 'StyleMint Delivery');
      expect(sub.trackingNumber, 'SM-D-00012847');
      expect(sub.estimatedDeliveryUtc, DateTime.utc(2026, 9, 17, 12));
      expect(sub.steps, hasLength(7));

      final pickedUp = sub.steps[3];
      expect(pickedUp.step, BuyerTimelineStep.pickedUp);
      expect(pickedUp.key, 'picked_up');
      expect(pickedUp.status, TimelineStepStatus.current);
      expect(pickedUp.occurredUtc, DateTime.utc(2026, 9, 15, 10));
      expect(pickedUp.note, 'Given to rider Ram at the gate');

      expect(sub.steps.first.status, TimelineStepStatus.done);
      expect(sub.steps.last.status, TimelineStepStatus.upcoming);
      expect(sub.steps.last.occurredUtc, isNull);
    });

    test('unknown step and status ints never throw', () {
      final timeline = OrderTimelineDto.fromJson({
        'orderNumber': 'NK2026-00001',
        'orderState': 42,
        'placedUtc': '2026-09-15T08:00:00Z',
        'subOrders': [
          {
            'subOrderId': 'a',
            'vendorAccountId': 'b',
            'currentStep': 99,
            'steps': [
              {'step': 77, 'key': 'teleported', 'status': 9},
            ],
          },
        ],
      }).toDomain();

      final sub = timeline.subOrders.single;
      expect(sub.currentStep, BuyerTimelineStep.unknown);
      expect(sub.vendorName, isNull);
      expect(sub.estimatedDeliveryUtc, isNull);
      expect(sub.steps.single.step, BuyerTimelineStep.unknown);
      expect(sub.steps.single.status, TimelineStepStatus.upcoming);
    });

    test('maps the cancelled and returned branches', () {
      final timeline = OrderTimelineDto.fromJson({
        'orderNumber': 'NK2026-00002',
        'placedUtc': '2026-09-15T08:00:00Z',
        'subOrders': [
          {
            'subOrderId': 'c',
            'vendorAccountId': 'v',
            'currentStep': 8,
            'isTerminal': true,
            'steps': [
              {'step': 1, 'key': 'placed', 'status': 1},
              {
                'step': 8,
                'key': 'cancelled',
                'status': 1,
                'note': 'Sold out this morning',
              },
            ],
          },
          {
            'subOrderId': 'r',
            'vendorAccountId': 'v',
            'currentStep': 9,
            'isTerminal': true,
            'steps': [
              {'step': 9, 'key': 'returned', 'status': 1},
            ],
          },
        ],
      }).toDomain();

      expect(timeline.subOrders[0].isCancelled, isTrue);
      expect(timeline.subOrders[0].steps.last.step.isBranch, isTrue);
      expect(timeline.subOrders[0].steps.last.note, 'Sold out this morning');
      expect(timeline.subOrders[1].isReturned, isTrue);
    });
  });
}
