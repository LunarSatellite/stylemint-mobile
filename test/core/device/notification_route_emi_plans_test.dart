import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// EMI-after-delivery contract v1: buyer `plan.*` notices open the buyer's
/// plan, `plan.vendor.*` the seller's — by `deepLink` when sent, else by
/// `agreementId`.
const _agreementId = 'b7c1d2e3-f405-4617-8829-3a4b5c6d7e8f';
const _orderId = '7a1e3f52-9a0b-4c55-8d1e-2b6f0c9e4d11';

String? _push(Map<String, dynamic> data) =>
    notificationLocation(NotificationPayload.fromPushData(data));

void main() {
  group('buyer plan notices open the buyer plan', () {
    const types = [
      'plan.delivered',
      'plan.started',
      'plan.payment.received',
      'plan.completed',
      'plan.reminder.upcoming',
      'plan.reminder.due',
      'plan.reminder.overdue',
    ];
    for (final type in types) {
      test('$type by its deepLink', () {
        expect(
          _push({
            'type': type,
            'deepLink': '/payment-plans/$_agreementId',
            'agreementId': _agreementId,
            'orderId': _orderId,
          }),
          '/payment-plans/$_agreementId',
        );
      });

      test('$type by its agreement id alone — not the order', () {
        expect(
          _push({
            'type': type,
            'agreementId': _agreementId,
            'orderId': _orderId,
          }),
          RouteNames.paymentPlanDetailPath(_agreementId),
        );
      });
    }

    test('an inbox plan.delivered row resolves like its push', () {
      final location = notificationLocation(
        NotificationPayload.fromInbox(
          templateKey: 'plan.delivered.inapp',
          variables: const {
            'data.agreementId': _agreementId,
            'orderId': _orderId,
            'outstanding': '32000',
          },
        ),
      );
      expect(location, RouteNames.paymentPlanDetailPath(_agreementId));
    });
  });
  // Seller plan notices (`plan.vendor.*`) are covered by
  // vendor_emi_notification_route_test.dart: they open the seller EMI plan.
}
