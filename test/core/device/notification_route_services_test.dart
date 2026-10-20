import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/services_routes.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Bookings contract v1 §7 and banks contract v1 §7: buyer booking,
/// appointment and enquiry notices open the buyer's booking, appointment or
/// enquiry — by `deepLink` when sent, else by id.
const _bookingId = '7a1e3f52-9a0b-4c55-8d1e-2b6f0c9e4d11';
const _appointmentId = 'b7c1d2e3-f405-4617-8829-3a4b5c6d7e8f';
const _leadId = 'c3d4e5f6-0718-4293-a4b5-c6d7e8f90a1b';

String? _push(
  Map<String, dynamic> data, {
  NotificationViewer viewer = const NotificationViewer(),
}) => notificationLocation(NotificationPayload.fromPushData(data), viewer: viewer);

void main() {
  group('buyer booking notices', () {
    for (final type in const [
      'booking.confirmed',
      'booking.reminder',
      'booking.cancelled',
      'booking.refunded',
    ]) {
      test('$type by its deepLink', () {
        expect(
          _push({
            'type': type,
            'deepLink': '/services/bookings/$_bookingId',
            'bookingId': _bookingId,
          }),
          '/services/bookings/$_bookingId',
        );
      });

      test('$type by its booking id alone', () {
        expect(
          _push({'type': type, 'bookingId': _bookingId}),
          RouteNames.bookingDetailPath(_bookingId),
        );
      });
    }

    test('the push type service_booking with a booking id', () {
      expect(
        _push({'type': 'service_booking', 'bookingId': _bookingId}),
        RouteNames.bookingDetailPath(_bookingId),
      );
    });

    test('without a usable id, the buyer\'s bookings', () {
      expect(_push({'type': 'booking.confirmed'}), RouteNames.myBookings);
      expect(
        _push({'type': 'booking.reminder', 'bookingId': 'BK-7F3A9C21'}),
        RouteNames.myBookings,
      );
    });

    test('an inbox row resolves like its push', () {
      expect(
        notificationLocation(
          NotificationPayload.fromInboxJson(
            templateKey: 'booking.confirmed.inapp',
            variablesJson: '{"data.bookingId":"$_bookingId"}',
          ),
        ),
        RouteNames.bookingDetailPath(_bookingId),
      );
    });

    test('the seller\'s booking.vendor.* notice is not the buyer\'s', () {
      expect(
        _push({'type': 'booking.vendor.confirmed', 'bookingId': _bookingId}),
        isNot(RouteNames.bookingDetailPath(_bookingId)),
      );
      expect(
        _push({
          'type': 'service_booking',
          'bookingId': _bookingId,
        }, viewer: const NotificationViewer(onVendorSide: true)),
        isNot(RouteNames.bookingDetailPath(_bookingId)),
      );
    });
  });

  group('bank notices', () {
    for (final type in const [
      'service.appointment.booked',
      'service.appointment.reminder',
      'service.appointment.cancelled',
    ]) {
      test('$type by its deepLink', () {
        expect(
          _push({
            'type': type,
            'deepLink': '/services/banks/appointments/$_appointmentId',
            'appointmentId': _appointmentId,
          }),
          '/services/banks/appointments/$_appointmentId',
        );
      });

      test('$type by its appointment id alone', () {
        expect(
          _push({'type': type, 'appointmentId': _appointmentId}),
          RouteNames.bankAppointmentDetailPath(_appointmentId),
        );
      });
    }

    test('service.enquiry.contacted by its lead id', () {
      expect(
        _push({'type': 'service.enquiry.contacted', 'leadId': _leadId}),
        RouteNames.bankEnquiryDetailPath(_leadId),
      );
    });

    test('the bank\'s own service.bank.* notices open the seller screen', () {
      // Routed by the seller app (service_notification_route.dart), never
      // to the buyer's appointment.
      expect(
        _push({
          'type': 'service.bank.appointment.booked',
          'appointmentId': _appointmentId,
        }),
        '/vendor/bank/appointments/$_appointmentId',
      );
    });
  });

  test('the v1 deep links forward to where the pages live now', () {
    // A v1 server, and notices already delivered, still send /services/...;
    // the router forwards each one (services_routes.dart).
    expect(
      legacyServiceLocation(Uri.parse('/services/bookings/$_bookingId')),
      RouteNames.bookingDetailPath(_bookingId),
    );
    expect(
      legacyServiceLocation(
        Uri.parse('/services/banks/appointments/$_appointmentId'),
      ),
      RouteNames.bankAppointmentDetailPath(_appointmentId),
    );
    expect(
      legacyServiceLocation(Uri.parse('/services/banks/enquiries/$_leadId')),
      RouteNames.bankEnquiryDetailPath(_leadId),
    );
    expect(
      legacyServiceLocation(Uri.parse('/services/bookings')),
      RouteNames.myBookings,
    );
    expect(
      RouteNames.bookingDetailPath(_bookingId),
      '/orders/bookings/$_bookingId',
    );
  });

  test('the v1 browse pages forward to Home', () {
    for (final path in [
      '/services',
      '/services/stays/results?q=Pokhara',
      '/services/stays/$_bookingId',
      '/services/travel/$_bookingId',
      '/services/banks/$_bookingId',
      '/services/bank-products/$_bookingId',
      '/services/bookings/checkout',
    ]) {
      expect(legacyServiceLocation(Uri.parse(path)), RouteNames.home);
    }
    expect(legacyServiceLocation(Uri.parse('/orders')), isNull);
  });

  test('bank notices without an id open the bank requests list', () {
    expect(
      _push({'type': 'service.appointment.booked'}),
      RouteNames.myBankRequests,
    );
    expect(
      _push({'type': 'service.enquiry.contacted'}),
      RouteNames.myBankRequests,
    );
  });
}
