import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/core/device/return_pickup_push.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/screens/vendor_orders_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

String? _push(
  Map<String, dynamic> data, {
  NotificationViewer viewer = const NotificationViewer(),
}) => notificationLocation(
  NotificationPayload.fromPushData(data),
  viewer: viewer,
);

String? _inbox(
  String templateKey,
  Map<String, dynamic> variables, {
  NotificationViewer viewer = const NotificationViewer(),
}) => notificationLocation(
  NotificationPayload.fromInboxJson(
    templateKey: templateKey,
    variablesJson: jsonEncode(variables),
  ),
  viewer: viewer,
);

const _home = NotificationViewer(); // cold start / home screen, no roles
const _courierAtHome = NotificationViewer(roles: {'customer', 'courier'});
const _vendorAtHome = NotificationViewer(roles: {'customer', 'vendor'});

void main() {
  test("the buyer's return pickup pushes open that return", () {
    for (final type in const [
      'return.accepted',
      'return_pickup.rider_assigned',
      'return_pickup.confirm_request',
      'return_pickup.attempt_failed',
      'return_pickup.something_new',
    ]) {
      expect(
        _push({'type': type, 'returnRequestId': 'ret-1'}),
        '${RouteNames.myReturns}/ret-1',
        reason: type,
      );
    }
    expect(_push({'type': 'return_pickup.collected'}), RouteNames.myReturns);
  });

  group('data.audience decides, whatever the screen or roles', () {
    const data = {
      'type': 'return_pickup.received',
      'returnRequestId': 'ret-1',
      'hopId': 'hop-9',
    };

    test('rider → the job, or the courier dashboard without one', () {
      for (final viewer in const [
        _home,
        _vendorAtHome,
        NotificationViewer(onVendorSide: true, roles: {'vendor'}),
      ]) {
        expect(
          _push({...data, 'audience': 'rider'}, viewer: viewer),
          RouteNames.courierJobPath('hop-9'),
        );
      }
      expect(
        _push({
          'type': 'return_pickup.cancelled',
          'returnRequestId': 'ret-1',
          'audience': 'Rider',
        }),
        RouteNames.courier,
      );
    });

    test("seller → the Returns tab of the seller's orders", () {
      for (final viewer in const [
        _home,
        _courierAtHome,
        NotificationViewer(onRiderSide: true, roles: {'courier'}),
      ]) {
        expect(
          _push({...data, 'audience': 'seller'}, viewer: viewer),
          RouteNames.vendorOrdersReturns,
        );
      }
    });

    test("buyer → the buyer's return, even for a courier or a vendor", () {
      for (final viewer in const [
        _courierAtHome,
        NotificationViewer(onRiderSide: true, roles: {'courier'}),
        NotificationViewer(onVendorSide: true, roles: {'vendor'}),
      ]) {
        expect(
          _push({...data, 'audience': 'buyer'}, viewer: viewer),
          '${RouteNames.myReturns}/ret-1',
        );
      }
    });

    test('return.accepted with an audience routes too', () {
      expect(
        _push(
          {
            'type': 'return.accepted',
            'returnRequestId': 'ret-1',
            'audience': 'buyer',
          },
          viewer: _vendorAtHome,
        ),
        '${RouteNames.myReturns}/ret-1',
      );
    });

    test('an unknown audience falls back like an older server', () {
      expect(
        _push({...data, 'audience': 'martian'}, viewer: _courierAtHome),
        RouteNames.courierJobPath('hop-9'),
      );
    });

    test('an explicit link does not override the audience', () {
      expect(
        _push({
          ...data,
          'audience': 'rider',
          'deepLink': '/orders/returns/ret-1',
        }),
        RouteNames.courierJobPath('hop-9'),
      );
    });
  });

  group('no audience (an older server): fall back by account', () {
    test('a courier tapping a rider notice from home or a cold start gets '
        'the job, not the buyer page that 404s', () {
      expect(
        _push({
          'type': 'return_pickup.received',
          'returnRequestId': 'ret-1',
          'hopId': 'hop-9',
        }, viewer: _courierAtHome),
        RouteNames.courierJobPath('hop-9'),
      );
      expect(
        _push({
          'type': 'return_pickup.cancelled',
          'returnRequestId': 'ret-1',
          'hopId': 'hop-9',
        }, viewer: const NotificationViewer(onVendorSide: true, roles: {'vendor', 'courier'})),
        RouteNames.courierJobPath('hop-9'),
      );
    });

    test('without the courier role a hop id does not make a rider', () {
      expect(
        _push({
          'type': 'return_pickup.received',
          'returnRequestId': 'ret-1',
          'hopId': 'hop-9',
        }),
        '${RouteNames.myReturns}/ret-1',
      );
    });

    test("a courier's notice with no job is the buyer's or seller's", () {
      expect(
        _push({
          'type': 'return.accepted',
          'returnRequestId': 'ret-1',
        }, viewer: _courierAtHome),
        '${RouteNames.myReturns}/ret-1',
      );
      expect(
        _push({
          'type': 'return_pickup.no_riders',
          'returnRequestId': 'ret-1',
        }, viewer: const NotificationViewer(roles: {'vendor', 'courier'})),
        RouteNames.vendorOrdersReturns,
      );
    });

    test('on the courier screens it is still the rider', () {
      expect(
        _push(
          {
            'type': 'return_pickup.received',
            'returnRequestId': 'ret-1',
            'hopId': 'hop-9',
          },
          viewer: const NotificationViewer(onRiderSide: true),
        ),
        RouteNames.courierJobPath('hop-9'),
      );
      expect(
        _push(
          {'type': 'return_pickup.cancelled', 'returnRequestId': 'ret-1'},
          viewer: const NotificationViewer(onRiderSide: true),
        ),
        RouteNames.courier,
      );
    });

    test("a vendor account opens the seller's returns", () {
      expect(
        _push(
          {'type': 'return_pickup.interest', 'returnRequestId': 'ret-1'},
          viewer: const NotificationViewer(onVendorSide: true),
        ),
        RouteNames.vendorOrdersReturns,
      );
      expect(
        _push({
          'type': 'return_pickup.interest',
          'returnRequestId': 'ret-1',
        }, viewer: _vendorAtHome),
        RouteNames.vendorOrdersReturns,
      );
    });

    test("an inbox row's .seller / .rider template says who it is for", () {
      expect(
        _inbox('return_pickup.collected.seller.inapp', {
          'data.type': 'return_pickup.collected',
          'data.returnRequestId': 'ret-1',
        }, viewer: _courierAtHome),
        RouteNames.vendorOrdersReturns,
      );
      expect(
        _inbox('return_pickup.received.rider', {
          'data.type': 'return_pickup.received',
          'data.returnRequestId': 'ret-1',
          'data.hopId': 'hop-9',
        }),
        RouteNames.courierJobPath('hop-9'),
      );
      expect(
        _inbox('return_pickup.received', {
          'data.type': 'return_pickup.received',
          'data.returnRequestId': 'ret-1',
          'data.hopId': 'hop-9',
          'data.audience': 'buyer',
        }, viewer: _courierAtHome),
        '${RouteNames.myReturns}/ret-1',
      );
    });
  });

  group('order.refunded', () {
    const orderId = '3f2b8a1c-0d4e-4f5a-9b6c-7d8e9f0a1b2c';

    test('a refund for a return opens that return', () {
      expect(
        _push({
          'type': 'order.refunded',
          'orderId': orderId,
          'returnRequestId': 'ret-7',
        }),
        '${RouteNames.myReturns}/ret-7',
      );
      expect(
        _inbox('order.refunded.inapp', {
          'orderId': orderId,
          'returnRequestId': 'ret-7',
        }),
        '${RouteNames.myReturns}/ret-7',
      );
    });

    test('a refund with no return still opens the order', () {
      expect(
        _push({'type': 'order.refunded', 'orderId': orderId}),
        '/orders/$orderId',
      );
    });
  });

  test('audience parsing', () {
    expect(ReturnPickupAudience.fromWire('buyer'), ReturnPickupAudience.buyer);
    expect(
      ReturnPickupAudience.fromWire(' SELLER '),
      ReturnPickupAudience.seller,
    );
    expect(ReturnPickupAudience.fromWire('rider'), ReturnPickupAudience.rider);
    expect(ReturnPickupAudience.fromWire(null), isNull);
    expect(ReturnPickupAudience.fromWire(''), isNull);
  });

  test("the seller's returns route opens the Returns tab", () {
    final uri = Uri.parse(RouteNames.vendorOrdersReturns);
    expect(uri.path, RouteNames.vendorOrders);
    expect(
      VendorOrdersTab.fromQuery(
        uri.queryParameters[RouteNames.vendorOrdersTabQuery],
      ),
      VendorOrdersTab.returns,
    );
    expect(VendorOrdersTab.fromQuery(null), VendorOrdersTab.toShip);
    expect(VendorOrdersTab.fromQuery('nonsense'), VendorOrdersTab.toShip);
  });

  test('a rider return request is still a delivery request', () {
    expect(
      _push({'type': 'delivery.request', 'offerId': 'o', 'kind': 'Return'}),
      RouteNames.courierOffers,
    );
  });

  test('return pickup pushes refresh the buyer, seller and rider screens', () {
    final signal = LiveSignal.fromPushData({
      'type': 'return_pickup.collected',
      'returnRequestId': 'ret-1',
    });
    expect(signal, isNotNull);
    expect(
      signal!.scopes,
      containsAll([
        LiveScope.buyerOrders,
        LiveScope.vendorOrders,
        LiveScope.courierJobs,
      ]),
    );
  });
}
