import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

String? _push(
  Map<String, dynamic> data, {
  NotificationViewer viewer = const NotificationViewer(),
}) => notificationLocation(
  NotificationPayload.fromPushData(data),
  viewer: viewer,
);

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

  test("the seller's open their orders, the rider's open the job", () {
    expect(
      _push(
        {'type': 'return_pickup.interest', 'returnRequestId': 'ret-1'},
        viewer: const NotificationViewer(onVendorSide: true),
      ),
      RouteNames.vendorOrders,
    );
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
