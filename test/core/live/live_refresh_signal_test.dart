import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';

void main() {
  group('push -> refresh mapping', () {
    LiveSignal? push(Map<String, dynamic> data) =>
        LiveSignal.fromPushData(data);

    test('delivery pushes reach the screens they change', () {
      expect(push({'type': 'delivery.confirm_request'})!.scopes, [
        LiveScope.buyerOrders,
        LiveScope.courierJobs,
      ]);
      expect(
        push({'type': 'delivery.delivered'})!.scopes,
        containsAll([
          LiveScope.buyerOrders,
          LiveScope.vendorOrders,
          LiveScope.courierJobs,
        ]),
      );
      expect(
        push({'type': 'delivery.selected'})!.scopes,
        containsAll([LiveScope.courierJobs, LiveScope.vendorOrders]),
      );
      expect(push({'type': 'delivery.interest'})!.scopes, [
        LiveScope.vendorOrders,
      ]);
      expect(push({'type': 'delivery.request'})!.scopes, [
        LiveScope.courierOffers,
      ]);
    });

    test('order pushes refresh the buyer and the vendor', () {
      for (final type in [
        'order.placed',
        'order.packed',
        'order.shipped',
        'order.delivered',
      ]) {
        expect(push({'type': type})!.scopes, [
          LiveScope.buyerOrders,
          LiveScope.vendorOrders,
        ], reason: type);
      }
    });

    test('the type may arrive as the template key', () {
      expect(push({'templateKey': 'order.shipped'})?.type, 'order.shipped');
    });

    test('carries the ids it was given', () {
      final signal = push({
        'type': 'delivery.delivered',
        'orderId': 'o-1',
        'subOrderId': 's-1',
        'hopId': 'h-1',
      })!;
      expect(signal.orderId, 'o-1');
      expect(signal.subOrderId, 's-1');
      expect(signal.hopId, 'h-1');
    });

    test('anything else is not a refresh', () {
      expect(push(const {}), isNull);
      expect(push({'type': 'kyc.decided'}), isNull);
      expect(push({'type': 'social.like', 'orderId': 'o-1'}), isNull);
      expect(push({'url': '/orders/1'}), isNull);
    });
  });

  group('live event -> refresh mapping', () {
    test('order.updated, delivery.updated and delivery.offer', () {
      final order = LiveSignal.fromLiveEvent({
        'type': 'order.updated',
        'occurredUtc': '2026-10-09T09:00:00+00:00',
        'data': {
          'orderId': 'o-1',
          'subOrderId': 's-1',
          'state': 'Delivered',
          'somethingNew': 42,
        },
      })!;
      expect(order.scopes, [LiveScope.buyerOrders, LiveScope.vendorOrders]);
      expect(order.orderId, 'o-1');
      expect(order.subOrderId, 's-1');

      final delivery = LiveSignal.fromLiveEvent({
        'type': 'delivery.updated',
        'data': {'hopId': 'h-1'},
      })!;
      expect(
        delivery.scopes,
        containsAll([
          LiveScope.buyerOrders,
          LiveScope.vendorOrders,
          LiveScope.courierJobs,
        ]),
      );
      expect(delivery.hopId, 'h-1');

      expect(LiveSignal.fromLiveEvent({'type': 'delivery.offer'})!.scopes, [
        LiveScope.courierOffers,
      ]);
    });

    test('unknown types and malformed arguments are ignored', () {
      expect(LiveSignal.fromLiveEvent({'type': 'chat.typing'}), isNull);
      expect(LiveSignal.fromLiveEvent({'data': {'orderId': 'o'}}), isNull);
      expect(LiveSignal.fromLiveEvent('order.updated'), isNull);
      expect(LiveSignal.fromLiveEvent(null), isNull);
    });

    test('data that is not an object still refreshes, without ids', () {
      final signal = LiveSignal.fromLiveEvent({
        'type': 'order.updated',
        'data': 'oops',
      })!;
      expect(signal.orderId, isNull);
    });
  });

  group('is it about this order?', () {
    const ids = (orderId: 'o-1', orderNumber: 'NK-1', sub: ['s-1']);

    bool about(LiveSignal s) => s.mayConcernOrder(
      orderId: ids.orderId,
      orderNumber: ids.orderNumber,
      subOrderIds: ids.sub,
    );

    test('by order id, number or sub-order id', () {
      LiveSignal signal({String? o, String? n, String? s}) => LiveSignal(
        type: 'order.updated',
        scopes: const [LiveScope.buyerOrders],
        orderId: o,
        orderNumber: n,
        subOrderId: s,
      );
      expect(about(signal(o: 'o-1')), isTrue);
      expect(about(signal(n: 'NK-1')), isTrue);
      expect(about(signal(s: 's-1')), isTrue);
      expect(about(signal(o: 'o-2')), isFalse);
      expect(about(signal()), isTrue, reason: 'no ids: re-read anyway');
    });

    test('a reconnect concerns every screen', () {
      const signal = LiveSignal.reconnected();
      expect(about(signal), isTrue);
      expect(signal.concerns({LiveScope.courierOffers}), isTrue);
    });
  });
}
