import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/device/notification_route.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_notification_route.dart';

/// Service vendors' notices (bookings contract v1 §7, banks contract v1 §7)
/// open the vendor's booking, lead or appointment.
void main() {
  const bookingId = '99999999-8888-4777-8666-555555555555';
  const leadId = '11111111-2222-4333-8444-555555555555';
  const appointmentId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';

  String? push(Map<String, dynamic> data) =>
      notificationLocation(NotificationPayload.fromPushData(data));

  for (final type in const [
    'booking.vendor.confirmed',
    'booking.vendor.reminder',
    'booking.vendor.cancelled',
    'booking.vendor.refunded',
  ]) {
    test('$type opens the vendor booking', () {
      expect(
        push({
          'type': type,
          'deepLink': '/vendor/bookings/$bookingId',
          'bookingId': bookingId,
          'kind': 'service_booking',
        }),
        '/vendor/bookings/$bookingId',
      );
      expect(
        push({'type': type, 'bookingId': bookingId}),
        '/vendor/bookings/$bookingId',
      );
    });
  }

  test('a vendor booking notice without an id: its deep link, else the list',
      () {
    expect(
      push({
        'type': 'booking.vendor.confirmed',
        'deepLink': '/vendor/bookings/$bookingId',
      }),
      '/vendor/bookings/$bookingId',
    );
    expect(push({'type': 'booking.vendor.confirmed'}), '/vendor/bookings');
    expect(
      push({'type': 'booking.vendor.confirmed', 'bookingId': 'BK-7F3A9C21'}),
      '/vendor/bookings',
    );
  });

  test('a new enquiry opens the lead', () {
    expect(
      push({
        'type': 'service.bank.enquiry.received',
        'deepLink': '/vendor/bank/leads/$leadId',
        'leadId': leadId,
        'kind': 'service_lead',
      }),
      '/vendor/bank/leads/$leadId',
    );
    expect(
      push({'type': 'service.bank.enquiry.received'}),
      '/vendor/bank/leads',
    );
  });

  for (final type in const [
    'service.bank.appointment.booked',
    'service.bank.appointment.reminder',
    'service.bank.appointment.cancelled',
  ]) {
    test('$type opens the appointment', () {
      expect(
        push({
          'type': type,
          'deepLink': '/vendor/bank/appointments/$appointmentId',
          'appointmentId': appointmentId,
          'leadId': leadId,
        }),
        '/vendor/bank/appointments/$appointmentId',
      );
      expect(
        push({'type': type, 'leadId': leadId}),
        '/vendor/bank/leads/$leadId',
      );
      expect(push({'type': type}), '/vendor/bank/appointments');
    });
  }

  test('an inbox row resolves like its push', () {
    final location = notificationLocation(
      NotificationPayload.fromInboxJson(
        templateKey: 'booking.vendor.confirmed.inapp',
        variablesJson: jsonEncode({
          'data.deepLink': '/vendor/bookings/$bookingId',
          'data.bookingId': bookingId,
          'bookingNumber': 'BK-7F3A9C21',
          'guestName': 'Sita Sharma',
        }),
      ),
    );
    expect(location, '/vendor/bookings/$bookingId');
  });

  test('buyer notices are not the vendor\'s', () {
    expect(
      serviceVendorNotificationLocation('booking.confirmed', const {
        'bookingId': bookingId,
      }),
      isNull,
    );
    expect(
      serviceVendorNotificationLocation('service.appointment.booked', const {
        'appointmentId': appointmentId,
      }),
      isNull,
    );
    expect(
      serviceVendorNotificationLocation('service.enquiry.contacted', const {
        'leadId': leadId,
      }),
      isNull,
    );
    expect(serviceVendorNotificationLocation(null, const {}), isNull);
  });
}
