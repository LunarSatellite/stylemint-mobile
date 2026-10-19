import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';

final _guid = RegExp(
  r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Where a service vendor's notification opens, or null when [type] is not
/// one of theirs.
///
///  * `booking.vendor.*` (bookings contract v1 §7: confirmed, reminder,
///    cancelled, refunded) → the booking, by `bookingId`;
///  * `service.bank.enquiry.*` (banks contract v1 §7) → the lead, by
///    `leadId`;
///  * `service.bank.appointment.*` → the appointment, by `appointmentId`
///    (else its lead).
///
/// With no usable id, the server's own vendor `deepLink` ([link], already
/// turned into an app location) when it is one; otherwise the list.
String? serviceVendorNotificationLocation(
  String? type,
  Map<String, dynamic> data, {
  String? link,
}) {
  if (type == null) return null;
  String? id(String key) {
    final raw = data[key]?.toString().trim();
    return raw != null && _guid.hasMatch(raw) ? raw : null;
  }

  String? vendorLink(String prefix) =>
      link != null && link.startsWith(prefix) ? link : null;

  if (type.startsWith('booking.vendor.')) {
    final bookingId = id('bookingId');
    if (bookingId != null) return ServiceRoutes.bookingPath(bookingId);
    return vendorLink('/vendor/bookings') ?? ServiceRoutes.bookings;
  }
  if (type.startsWith('service.bank.enquiry.')) {
    final leadId = id('leadId');
    if (leadId != null) return ServiceRoutes.bankLeadPath(leadId);
    return vendorLink('/vendor/bank/') ?? ServiceRoutes.bankLeads;
  }
  if (type.startsWith('service.bank.appointment.')) {
    final appointmentId = id('appointmentId');
    if (appointmentId != null) {
      return ServiceRoutes.bankAppointmentPath(appointmentId);
    }
    final leadId = id('leadId');
    if (leadId != null) return ServiceRoutes.bankLeadPath(leadId);
    return vendorLink('/vendor/bank/') ?? ServiceRoutes.bankAppointments;
  }
  return null;
}
