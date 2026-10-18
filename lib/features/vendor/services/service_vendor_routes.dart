import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_appointment_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_appointments_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_lead_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bank/presentation/bank_leads_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/vendor_availability_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/vendor_booking_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/bookings/presentation/vendor_bookings_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/onboarding/vendor_apply_service_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_routes.dart';

/// The service vendors' seller-app routes, spread into the app router. Kept
/// here so the shared router file only gains one line.
final List<RouteBase> serviceVendorRoutes = <RouteBase>[
  GoRoute(
    path: ServiceRoutes.bookings,
    builder: (ctx, state) => VendorBookingsScreen(
      initialTab: switch (state.uri.queryParameters['tab']) {
        'upcoming' => 1,
        'all' => 2,
        _ => 0,
      },
    ),
  ),
  GoRoute(
    path: ServiceRoutes.bookingDetail,
    builder: (ctx, state) => VendorBookingDetailScreen(
      bookingId: state.pathParameters['bookingId']!,
    ),
  ),
  GoRoute(
    path: ServiceRoutes.availability,
    builder: (ctx, state) => const VendorAvailabilityScreen(),
  ),
  GoRoute(
    path: ServiceRoutes.bankLeads,
    builder: (ctx, state) => const BankLeadsScreen(),
  ),
  GoRoute(
    path: ServiceRoutes.bankLeadDetail,
    builder: (ctx, state) =>
        BankLeadDetailScreen(leadId: state.pathParameters['leadId']!),
  ),
  GoRoute(
    path: ServiceRoutes.bankAppointments,
    builder: (ctx, state) => const BankAppointmentsScreen(),
  ),
  GoRoute(
    path: ServiceRoutes.bankAppointmentDetail,
    builder: (ctx, state) => BankAppointmentDetailScreen(
      appointmentId: state.pathParameters['appointmentId']!,
    ),
  ),
  GoRoute(
    path: ServiceRoutes.applyService,
    builder: (ctx, state) => const VendorApplyServiceScreen(),
  ),
];
