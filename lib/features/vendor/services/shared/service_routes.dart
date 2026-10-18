/// Seller-app routes for service vendors (hotels, travel agencies, banks).
///
/// The booking, lead and appointment detail paths are exactly the vendor
/// deep links the backend puts in its notifications (bookings contract v1
/// §7: `/vendor/bookings/{bookingId}`; banks contract v1 §7:
/// `/vendor/bank/leads/{leadId}`, `/vendor/bank/appointments/{id}`), so a
/// tapped notification lands without any translation.
abstract final class ServiceRoutes {
  /// Hotel / travel bookings: today, upcoming, all.
  static const bookings = '/vendor/bookings';
  static const bookingDetail = '/vendor/bookings/:bookingId';
  static String bookingPath(String bookingId) =>
      '/vendor/bookings/${Uri.encodeComponent(bookingId)}';

  /// Rooms free per night / seats left per departure, with quick close.
  static const availability = '/vendor/availability';

  /// Bank leads inbox and one lead.
  static const bankLeads = '/vendor/bank/leads';
  static const bankLeadDetail = '/vendor/bank/leads/:leadId';
  static String bankLeadPath(String leadId) =>
      '/vendor/bank/leads/${Uri.encodeComponent(leadId)}';

  /// A day's branch appointments, and one appointment.
  static const bankAppointments = '/vendor/bank/appointments';
  static const bankAppointmentDetail =
      '/vendor/bank/appointments/:appointmentId';
  static String bankAppointmentPath(String appointmentId) =>
      '/vendor/bank/appointments/${Uri.encodeComponent(appointmentId)}';

  /// Vendor application: what kind of business, and its licence. Under
  /// `/vendor/apply` so the approval gate leaves it alone.
  static const applyService = '/vendor/apply/service';
}
