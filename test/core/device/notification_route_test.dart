import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

const _orderId = '3f2b8a1c-0d4e-4f5a-9b6c-7d8e9f0a1b2c';
const _subOrderId = 'aa11bb22-cc33-4d44-8e55-ff6677889900';

String? _push(
  Map<String, dynamic> data, {
  NotificationViewer viewer = const NotificationViewer(),
}) => notificationLocation(
  NotificationPayload.fromPushData(data),
  viewer: viewer,
);

String? _inbox(
  String? templateKey,
  Map<String, dynamic> variables, {
  NotificationViewer viewer = const NotificationViewer(),
}) => notificationLocation(
  NotificationPayload.fromInboxJson(
    templateKey: templateKey,
    variablesJson: jsonEncode(variables),
  ),
  viewer: viewer,
);

void main() {
  group('notificationTypeFromTemplateKey', () {
    test('strips the channel suffix and lower-cases', () {
      expect(
        notificationTypeFromTemplateKey('order.packed.push'),
        'order.packed',
      );
      expect(
        notificationTypeFromTemplateKey('Order.Packed.InApp'),
        'order.packed',
      );
      expect(
        notificationTypeFromTemplateKey('order.shipped.email'),
        'order.shipped',
      );
      expect(notificationTypeFromTemplateKey('order.placed'), 'order.placed');
    });

    test('is null for nothing', () {
      expect(notificationTypeFromTemplateKey(null), isNull);
      expect(notificationTypeFromTemplateKey('  '), isNull);
    });
  });

  group('order notifications open the buyer order', () {
    const types = [
      'order.placed',
      'order.packed',
      'order.shipped',
      'order.delivered',
      'order.cancelled',
      'order.refunded',
    ];

    for (final type in types) {
      test('$type by order number', () {
        expect(
          _push({
            'type': type,
            'orderNumber': 'SM-2026-0042',
            'orderId': _orderId,
          }),
          '/orders/SM-2026-0042',
        );
      });

      test('$type by order id when there is no number', () {
        expect(
          _push({'type': type, 'orderId': _orderId, 'subOrderId': _subOrderId}),
          '/orders/$_orderId',
        );
      });

      test('$type by sub-order id alone', () {
        expect(
          _push({'type': type, 'subOrderId': _subOrderId}),
          '/orders/$_subOrderId',
        );
      });

      test('$type with no id lands on the orders list', () {
        expect(_push({'type': type}), RouteNames.orders);
      });
    }

    test('a GUID in orderNumber is the sub-order id of an older push', () {
      expect(
        _push({'type': 'order.packed', 'orderNumber': _subOrderId}),
        '/orders/$_subOrderId',
      );
    });

    test('the order id beats a GUID in orderNumber', () {
      expect(
        _push({
          'type': 'order.packed',
          'orderNumber': _subOrderId,
          'orderId': _orderId,
        }),
        '/orders/$_orderId',
      );
    });

    test('an order number is URL-encoded', () {
      expect(
        _push({'type': 'order.placed', 'orderNumber': 'SM 42/A'}),
        '/orders/SM%2042%2FA',
      );
    });

    test('a vendor on the vendor side still gets the buyer order: every '
        'order.* template goes to the buyer', () {
      expect(
        _push(
          {'type': 'order.packed', 'orderId': _orderId},
          viewer: const NotificationViewer(
            onVendorSide: true,
            roles: {'vendor'},
          ),
        ),
        '/orders/$_orderId',
      );
    });

    test('a type sent with a channel suffix is still an order', () {
      expect(
        _push({'type': 'order.shipped.push', 'orderId': _orderId}),
        '/orders/$_orderId',
      );
    });
  });

  group('explicit links come first', () {
    test('a deepLink beats the type', () {
      expect(
        _push({
          'type': 'order.packed',
          'orderId': _orderId,
          'deepLink': 'stylemint://orders/SM-1',
        }),
        '/orders/SM-1',
      );
    });

    test('a bare route is used as-is', () {
      expect(_push({'route': '/wallet'}), '/wallet');
    });

    test('a backend API link is not an app route', () {
      expect(
        _push({'url': 'https://stylemint.voyageritnepal.com/v1/x'}),
        isNull,
      );
    });
  });

  group('delivery notifications keep their own routing', () {
    test('delivery.request opens the rider offers', () {
      expect(
        _push({'type': 'delivery.request', 'offerId': 'o1'}),
        RouteNames.courierOffers,
      );
    });

    test('delivery.selected opens the job', () {
      expect(
        _push({'type': 'delivery.selected', 'hopId': 'h1'}),
        RouteNames.courierJobPath('h1'),
      );
    });

    test('delivery.interest opens the vendor sub-order with the partner '
        'sheet', () {
      expect(
        _push({'type': 'delivery.interest', 'subOrderId': _subOrderId}),
        '/vendor/orders/$_subOrderId?${RouteNames.partnerSheetQuery}=1',
      );
    });

    test('delivery.confirm_request opens the buyer order', () {
      expect(
        _push({
          'type': 'delivery.confirm_request',
          'orderNumber': 'SM-7',
          'orderId': _orderId,
        }),
        '/orders/SM-7',
      );
    });

    test('delivery.delivered: the vendor gets the sub-order, the rider the '
        'dashboard', () {
      final data = {'type': 'delivery.delivered', 'subOrderId': _subOrderId};
      expect(
        _push(data, viewer: const NotificationViewer(onVendorSide: true)),
        '/vendor/orders/$_subOrderId',
      );
      expect(
        _push(
          data,
          viewer: const NotificationViewer(
            onRiderSide: true,
            roles: {'vendor'},
          ),
        ),
        RouteNames.courier,
      );
      expect(
        _push(data, viewer: const NotificationViewer(roles: {'vendor'})),
        '/vendor/orders/$_subOrderId',
      );
      expect(_push(data), RouteNames.courier);
    });

    test('delivery.at_risk opens the recovery screen by tracking number', () {
      expect(
        _push({'type': 'delivery.at_risk', 'trackingNumber': 'TRK1'}),
        '/delivery/TRK1/recovery',
      );
    });
  });

  group('payment-plan notifications open the plan', () {
    const agreementId = 'b7c1d2e3-f405-4617-8829-3a4b5c6d7e8f';
    const types = [
      'plan.reminder.upcoming',
      'plan.reminder.due',
      'plan.reminder.overdue',
      'plan.defaulted',
    ];

    for (final type in types) {
      test('$type by the deepLink the server sends', () {
        expect(
          _push({'type': type, 'deepLink': '/payment-plans/$agreementId'}),
          '/payment-plans/$agreementId',
        );
      });

      test('$type by its agreement id alone', () {
        expect(
          _push({'type': type, 'agreementId': agreementId}),
          RouteNames.paymentPlanDetailPath(agreementId),
        );
      });
    }

    test('with no usable id, the list of plans', () {
      expect(_push({'type': 'plan.reminder.due'}), RouteNames.paymentPlans);
      expect(
        _push({'type': 'plan.reminder.due', 'agreementId': 'not-an-id'}),
        RouteNames.paymentPlans,
      );
    });

    test('an inbox row resolves like its push', () {
      expect(
        _inbox('plan.reminder.overdue.inapp', {
          'data.deepLink': '/payment-plans/$agreementId',
          'data.agreementId': agreementId,
          'amount': '8000.00',
        }),
        '/payment-plans/$agreementId',
      );
    });
  });

  test('kyc.decided opens the verification screen', () {
    expect(
      _push({'type': 'kyc.decided', 'status': 'Approved'}),
      RouteNames.customerKyc,
    );
  });

  group('payouts', () {
    test('go to the vendor or creator earnings by side, then by role', () {
      final data = {'type': 'payout.paid'};
      expect(
        _push(data, viewer: const NotificationViewer(onVendorSide: true)),
        RouteNames.vendorEarnings,
      );
      expect(
        _push(
          data,
          viewer: const NotificationViewer(
            onCreatorSide: true,
            roles: {'vendor'},
          ),
        ),
        RouteNames.earnings,
      );
      expect(
        _push(data, viewer: const NotificationViewer(roles: {'creator'})),
        RouteNames.earnings,
      );
      expect(_push(data), isNull);
    });
  });

  test('vendor-facing order types open the vendor sub-order', () {
    expect(
      _push({'type': 'vendor.order.placed', 'subOrderId': _subOrderId}),
      '/vendor/orders/$_subOrderId',
    );
    expect(_push({'type': 'vendor.order.placed'}), RouteNames.vendorOrders);
  });

  group('payloads with no destination', () {
    test('a push from before data.type was sent opens just the app', () {
      expect(_push(const {}), isNull);
    });

    test('an untyped push that names an order still opens it', () {
      expect(_push({'orderNumber': _subOrderId}), '/orders/$_subOrderId');
      expect(_push({'orderId': _orderId}), '/orders/$_orderId');
    });

    test('an unknown type opens just the app', () {
      expect(_push({'type': 'comment.reply'}), isNull);
    });
  });

  group('inbox rows resolve like their pushes', () {
    test('order.packed with the sub-order GUID in orderNumber and the order '
        'id', () {
      expect(
        _inbox('order.packed', {
          'orderNumber': _subOrderId,
          'orderId': _orderId,
          'subOrderId': _subOrderId,
        }),
        '/orders/$_orderId',
      );
    });

    test('order.packed with only the GUID orderNumber (older row)', () {
      expect(
        _inbox('order.packed', {'orderNumber': _subOrderId}),
        '/orders/$_subOrderId',
      );
    });

    test('order.placed by number', () {
      expect(
        _inbox('order.placed', {'orderNumber': 'SM-9', 'orderId': _orderId}),
        '/orders/SM-9',
      );
    });

    test('a template key with a channel suffix', () {
      expect(
        _inbox('order.shipped.inapp', {'orderId': _orderId}),
        '/orders/$_orderId',
      );
    });

    test('data.* variables are what the push carries, and win', () {
      expect(
        _inbox('delivery.interest', {
          'data.type': 'delivery.interest',
          'data.subOrderId': _subOrderId,
          'trackingNumber': 'TRK',
        }),
        '/vendor/orders/$_subOrderId?${RouteNames.partnerSheetQuery}=1',
      );
    });

    test('a deepLink variable is used first', () {
      expect(
        _inbox('delivery.at_risk', {
          'deepLink': 'stylemint://delivery/TRK9/recovery',
          'trackingNumber': 'TRK9',
        }),
        '/delivery/TRK9/recovery',
      );
    });

    test('malformed variables are no variables', () {
      expect(
        notificationLocation(
          NotificationPayload.fromInboxJson(
            templateKey: 'order.placed',
            variablesJson: '{not json',
          ),
        ),
        RouteNames.orders,
      );
    });
  });

  group('NotificationViewer.from', () {
    test('reads the side from the location', () {
      expect(
        NotificationViewer.from(location: '/vendor/home').onVendorSide,
        isTrue,
      );
      expect(
        NotificationViewer.from(location: '/courier/offers').onRiderSide,
        isTrue,
      );
      expect(
        NotificationViewer.from(location: '/creator/dashboard').onCreatorSide,
        isTrue,
      );
      final buyer = NotificationViewer.from(location: '/home');
      expect(
        buyer.onVendorSide || buyer.onRiderSide || buyer.onCreatorSide,
        isFalse,
      );
    });
  });
}
