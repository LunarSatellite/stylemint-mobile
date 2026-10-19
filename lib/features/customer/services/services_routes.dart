import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/bank_forms_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/bank_requests_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/booking_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/services/presentation/screens/my_bookings_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// The buyer's service pages, spread into the router ahead of
/// `/orders/:orderId` so `bookings`, `bank-requests`, `bank-enquiries` and
/// `bank-appointments` are never read as order numbers.
///
/// Services are sold like items (owner change, 2026-10-19): there is no
/// Services tab. A stay, trip or bank product opens on the product page; what
/// the buyer booked or asked for lives under Orders. The v1 `/services/...`
/// links — in notifications already delivered, and from a v1 server — still
/// work: each forwards to where its page lives now, and the old browse pages
/// (search, results, a stay or trip by listing id, a bank) go to Home, the
/// way in to reels.
final List<RouteBase> buyerServiceRoutes = [
  GoRoute(
    path: RouteNames.myBookings,
    builder: (ctx, state) => const MyBookingsScreen(),
  ),
  GoRoute(
    path: RouteNames.myBankRequests,
    builder: (ctx, state) =>
        const MyBookingsScreen(initialTab: MyBookingsTab.banks),
  ),
  GoRoute(
    path: RouteNames.bookingDetail,
    builder: (ctx, state) =>
        BookingDetailScreen(bookingId: state.pathParameters['bookingId']!),
  ),
  GoRoute(
    path: RouteNames.bankEnquiryDetail,
    builder: (ctx, state) => EnquiryDetailScreen(
      leadId: state.pathParameters['leadId']!,
      justSent: state.uri.queryParameters['sent'] == '1',
    ),
  ),
  GoRoute(
    path: RouteNames.bankAppointmentDetail,
    builder: (ctx, state) => AppointmentDetailScreen(
      appointmentId: state.pathParameters['appointmentId']!,
      justSent: state.uri.queryParameters['sent'] == '1',
    ),
  ),
  GoRoute(
    path: RouteNames.bankEnquiryForm,
    builder: (ctx, state) =>
        BankEnquiryScreen(productId: state.pathParameters['productId']!),
  ),
  GoRoute(
    path: RouteNames.bankAppointmentForm,
    builder: (ctx, state) => BankAppointmentScreen(
      bankId: state.pathParameters['bankId']!,
      productId: state.uri.queryParameters['productId'],
    ),
  ),
  ...legacyServiceRedirects,
];

/// Where a v1 `/services/...` location lives now, or null when [location]
/// is not one. Pure, so the forwarding is testable without a router.
String? legacyServiceLocation(Uri location) {
  final s = location.pathSegments;
  if (s.isEmpty || s.first != 'services') return null;
  String keepSent(String path) =>
      location.queryParameters['sent'] == '1' ? '$path?sent=1' : path;
  if (s.length >= 3 && s[1] == 'bookings' && s[2] != 'checkout') {
    return RouteNames.bookingDetailPath(s[2]);
  }
  if (s.length == 2 && s[1] == 'bookings') return RouteNames.myBookings;
  if (s.length == 4 && s[1] == 'banks' && s[2] == 'enquiries') {
    return keepSent(RouteNames.bankEnquiryDetailPath(s[3]));
  }
  if (s.length == 4 && s[1] == 'banks' && s[2] == 'appointments') {
    return keepSent(RouteNames.bankAppointmentDetailPath(s[3]));
  }
  return RouteNames.home;
}

/// The v1 paths, each forwarding through [legacyServiceLocation]. The two
/// bank request paths come before `/services/banks/:bankId` so `enquiries`
/// and `appointments` are never read as a bank id.
final List<RouteBase> legacyServiceRedirects = [
  for (final path in [
    RouteNames.legacyServices,
    RouteNames.legacyMyBookings,
    RouteNames.legacyBookingConfirmed,
    RouteNames.legacyBookingDetail,
    RouteNames.legacyBankEnquiryDetail,
    RouteNames.legacyBankAppointmentDetail,
    ...RouteNames.legacyServiceBrowse,
  ])
    GoRoute(
      path: path,
      redirect: (ctx, state) =>
          legacyServiceLocation(state.uri) ?? RouteNames.home,
    ),
];
