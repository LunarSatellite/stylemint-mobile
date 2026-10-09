import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

void main() {
  group('DeliveryPushEvent.fromData', () {
    test('reads each contract type and its ids', () {
      final request = DeliveryPushEvent.fromData({
        'type': 'delivery.request',
        'offerId': 'offer-1',
      });
      expect(request?.type, DeliveryPushType.request);
      expect(request?.offerId, 'offer-1');

      final interest = DeliveryPushEvent.fromData({
        'type': 'delivery.interest',
        'subOrderId': 'sub-1',
      });
      expect(interest?.type, DeliveryPushType.interest);
      expect(interest?.subOrderId, 'sub-1');

      final selected = DeliveryPushEvent.fromData({
        'type': 'delivery.selected',
        'packageId': 'pkg-1',
        'hopId': 'hop-1',
      });
      expect(selected?.type, DeliveryPushType.selected);
      expect(selected?.packageId, 'pkg-1');
      expect(selected?.hopId, 'hop-1');

      final notSelected = DeliveryPushEvent.fromData({
        'type': 'delivery.not_selected',
        'offerId': 'offer-2',
      });
      expect(notSelected?.type, DeliveryPushType.notSelected);
    });

    test('anything else is not a delivery push', () {
      expect(DeliveryPushEvent.fromData({}), isNull);
      expect(DeliveryPushEvent.fromData({'type': 'order.shipped'}), isNull);
      expect(DeliveryPushEvent.fromData({'route': '/orders/1'}), isNull);
    });

    test('type is read case-insensitively and blank ids are null', () {
      final event = DeliveryPushEvent.fromData({
        'type': ' Delivery.Request ',
        'offerId': '  ',
      });
      expect(event?.type, DeliveryPushType.request);
      expect(event?.offerId, isNull);
    });
  });

  group('routing by type', () {
    String? routeOf(Map<String, dynamic> data) =>
        DeliveryPushEvent.fromData(data)?.route;

    test('a new request opens the offers screen', () {
      expect(
        routeOf({'type': 'delivery.request', 'offerId': 'o'}),
        RouteNames.courierOffers,
      );
    });

    test('interest opens that order with the partner sheet', () {
      final route = routeOf({
        'type': 'delivery.interest',
        'subOrderId': 'sub-42',
      });
      expect(route, '/vendor/orders/sub-42?${RouteNames.partnerSheetQuery}=1');

      final uri = Uri.parse(route!);
      expect(uri.path, '/vendor/orders/sub-42');
      expect(uri.queryParameters[RouteNames.partnerSheetQuery], '1');
    });

    test('interest without an order lands on the orders list', () {
      expect(routeOf({'type': 'delivery.interest'}), RouteNames.vendorOrders);
    });

    test('being chosen opens that job on the in-app map', () {
      expect(
        routeOf({'type': 'delivery.selected', 'hopId': 'h'}),
        RouteNames.courierJobPath('h'),
      );
      expect(
        RouteNames.courierJobPath('h').startsWith('${RouteNames.courier}/'),
        isTrue,
        reason: 'so the job has the dashboard to pop to',
      );
    });

    test('being chosen without a hop id opens the dashboard map', () {
      expect(
        routeOf({'type': 'delivery.selected', 'packageId': 'p'}),
        RouteNames.courier,
      );
    });

    test("a confirm request opens the buyer's order", () {
      final event = DeliveryPushEvent.fromData({
        'type': 'delivery.confirm_request',
        'orderId': '3f2b6c1e-0000-4000-8000-000000000001',
        'subOrderId': 'sub-1',
      });
      expect(event?.type, DeliveryPushType.confirmRequest);
      expect(event?.orderId, '3f2b6c1e-0000-4000-8000-000000000001');
      expect(event?.route, '/orders/3f2b6c1e-0000-4000-8000-000000000001');

      // An order number, when a server sends one, is used as is.
      expect(
        routeOf({
          'type': 'delivery.confirm_request',
          'orderId': 'id',
          'orderNumber': 'NK2026-00015',
        }),
        '/orders/NK2026-00015',
      );
      expect(
        routeOf({'type': 'delivery.confirm_request'}),
        RouteNames.orders,
      );
    });

    test('delivered opens the sub-order for a vendor, the map for a rider', () {
      final event = DeliveryPushEvent.fromData({
        'type': 'delivery.delivered',
        'subOrderId': 'sub-42',
        'hopId': 'hop-1',
      })!;
      expect(event.type, DeliveryPushType.delivered);
      expect(event.hopId, 'hop-1');
      expect(event.routeFor(vendor: true), '/vendor/orders/sub-42');
      expect(event.routeFor(vendor: false), RouteNames.courier);
    });

    test('not being chosen opens the offers screen', () {
      expect(
        routeOf({'type': 'delivery.not_selected', 'offerId': 'o'}),
        RouteNames.courierOffers,
      );
    });

    test('the offers route sits under the courier route', () {
      // So a notification-opened offers screen has the dashboard to pop to.
      expect(
        RouteNames.courierOffers.startsWith('${RouteNames.courier}/'),
        isTrue,
      );
    });
  });

  group('DeliveryPushBus', () {
    test('delivers published events to listeners', () async {
      final bus = DeliveryPushBus();
      addTearDown(bus.dispose);
      final received = <DeliveryPushType>[];
      final sub = bus.events.listen((e) => received.add(e.type));

      bus
        ..publish(const DeliveryPushEvent(type: DeliveryPushType.request))
        ..publish(const DeliveryPushEvent(type: DeliveryPushType.selected));
      await Future<void>.delayed(Duration.zero);

      expect(received, [DeliveryPushType.request, DeliveryPushType.selected]);
      await sub.cancel();
    });

    test('publishing after dispose is ignored, not thrown', () async {
      final bus = DeliveryPushBus();
      await bus.dispose();
      expect(
        () => bus.publish(
          const DeliveryPushEvent(type: DeliveryPushType.request),
        ),
        returnsNormally,
      );
    });
  });
}
