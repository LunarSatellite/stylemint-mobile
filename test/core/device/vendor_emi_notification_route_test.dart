import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Seller EMI notices (emi-after contract v1): `plan.vendor.upcoming`,
/// `plan.vendor.overdue`, `plan.vendor.payment.received` and
/// `plan.vendor.completed` open the seller's EMI plan — never the buyer's.
void main() {
  const agreementId = 'b7c1d2e3-f405-4617-8829-3a4b5c6d7e8f';
  const orderId = '3f2b8a1c-0d4e-4f5a-9b6c-7d8e9f0a1b2c';
  const types = [
    'plan.vendor.upcoming',
    'plan.vendor.overdue',
    'plan.vendor.payment.received',
    'plan.vendor.completed',
  ];

  String? push(Map<String, dynamic> data) =>
      notificationLocation(NotificationPayload.fromPushData(data));

  for (final type in types) {
    test('$type opens the vendor EMI plan, over its deepLink', () {
      expect(
        push({
          'type': type,
          'deepLink': '/vendor/payment-plans/$agreementId',
          'agreementId': agreementId,
          'orderId': orderId,
        }),
        RouteNames.vendorEmiPlanDetailPath(agreementId),
      );
    });

    test('$type with only the deepLink still finds the plan', () {
      expect(
        push({'type': type, 'deepLink': '/vendor/payment-plans/$agreementId'}),
        RouteNames.vendorEmiPlanDetailPath(agreementId),
      );
    });
  }

  test('with no usable id, the seller\'s plans list', () {
    expect(push({'type': 'plan.vendor.overdue'}), RouteNames.vendorEmiPlans);
    expect(
      push({'type': 'plan.vendor.overdue', 'agreementId': 'not-an-id'}),
      RouteNames.vendorEmiPlans,
    );
  });

  test('an inbox row resolves like its push', () {
    final location = notificationLocation(
      NotificationPayload.fromInboxJson(
        templateKey: 'plan.vendor.upcoming.inapp',
        variablesJson: jsonEncode({
          'data.deepLink': '/vendor/payment-plans/$agreementId',
          'data.agreementId': agreementId,
          'amount': '16000.00',
        }),
      ),
    );
    expect(location, RouteNames.vendorEmiPlanDetailPath(agreementId));
  });

  test('buyer plan notices still open the buyer plan', () {
    expect(
      push({
        'type': 'plan.delivered',
        'deepLink': '/payment-plans/$agreementId',
      }),
      '/payment-plans/$agreementId',
    );
  });
}
