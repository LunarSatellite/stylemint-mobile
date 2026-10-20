import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/routes/route_path_match.dart';

/// Services are sold like items (2026-10-19): no Services tab, no browse
/// pages. The buyer's bookings and bank requests live under Orders, signed
/// in only, and are registered before Order Detail. Read as text, as the
/// other reachability checks do, because building the GoRouter needs the
/// whole auth stack.
void main() {
  late final router = File('lib/routes/app_router.dart').readAsStringSync();
  late final serviceRoutes = File(
    'lib/features/customer/services/services_routes.dart',
  ).readAsStringSync();

  late final publicPaths = () {
    final start = router.indexOf('const _publicPaths = {');
    final end = router.indexOf('};', start);
    expect(start, greaterThan(-1), reason: '_publicPaths not found');
    return RegExp(
      r'RouteNames\.(\w+),',
    ).allMatches(router.substring(start, end)).map((m) => m.group(1)!).toSet();
  }();

  // `/orders` is public, and a plain pattern matches as a prefix, so every
  // service page under it is public unless the signed-in-only list says not.
  bool isPublic(String location) =>
      publicPaths.contains('orders') &&
      routePathMatches(location, RouteNames.orders) &&
      !RouteNames.servicesSignedInOnly.any(
        (p) => routePathMatches(location, p),
      );

  test('there is no Services tab or browse page any more', () {
    expect(router.contains('ServicesHomeScreen'), isFalse);
    expect(router.contains('StayResultsScreen'), isFalse);
    expect(router.contains('TravelResultsScreen'), isFalse);
    expect(publicPaths, isNot(contains('services')));
  });

  test('the redirect honours the signed-in-only list', () {
    expect(router.contains('RouteNames.servicesSignedInOnly.any('), isTrue);
  });

  test('bookings and bank requests are signed-in only', () {
    for (final location in [
      RouteNames.myBookings,
      RouteNames.myBankRequests,
      RouteNames.bookingDetailPath('a'),
      RouteNames.bankEnquiryDetailPath('a'),
      RouteNames.bankAppointmentDetailPath('a'),
      RouteNames.bankEnquiryFormPath('a'),
    ]) {
      expect(isPublic(location), isFalse, reason: location);
    }
  });

  test('the service routes come before Order Detail', () {
    final spread = router.indexOf('...buyerServiceRoutes,');
    expect(spread, greaterThan(-1));
    expect(spread, lessThan(router.indexOf('path: RouteNames.orderDetail,')));
    for (final name in [
      'myBookings',
      'myBankRequests',
      'bookingDetail',
      'bankEnquiryDetail',
      'bankAppointmentDetail',
      'bankEnquiryForm',
      'bankAppointmentForm',
    ]) {
      expect(
        serviceRoutes.contains('path: RouteNames.$name,'),
        isTrue,
        reason: name,
      );
    }
  });

  test('the v1 /services links are still registered, as redirects', () {
    for (final name in [
      'legacyServices',
      'legacyMyBookings',
      'legacyBookingDetail',
      'legacyBankEnquiryDetail',
      'legacyBankAppointmentDetail',
    ]) {
      expect(serviceRoutes.contains('RouteNames.$name,'), isTrue, reason: name);
    }
    expect(
      serviceRoutes.indexOf('RouteNames.legacyBankAppointmentDetail,'),
      lessThan(serviceRoutes.indexOf('...RouteNames.legacyServiceBrowse')),
    );
  });
}
