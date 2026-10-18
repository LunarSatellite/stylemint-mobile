import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/routes/route_path_match.dart';

/// The Services tab browses signed out; the buyer's own bookings, enquiries
/// and appointments under `/services` do not. Read as text, as the other
/// reachability checks do, because building the GoRouter needs the whole
/// auth stack.
void main() {
  late final router = File('lib/routes/app_router.dart').readAsStringSync();

  late final publicPaths = () {
    final start = router.indexOf('const _publicPaths = {');
    final end = router.indexOf('};', start);
    expect(start, greaterThan(-1), reason: '_publicPaths not found');
    return RegExp(
      r'RouteNames\.(\w+),',
    ).allMatches(router.substring(start, end)).map((m) => m.group(1)!).toSet();
  }();

  bool isPublic(String location) =>
      routePathMatches(location, RouteNames.services) &&
      !RouteNames.servicesSignedInOnly.any(
        (p) => routePathMatches(location, p),
      );

  test('the Services tab is a public path', () {
    expect(publicPaths, contains('services'));
  });

  test('the redirect honours the signed-in-only list', () {
    expect(router.contains('RouteNames.servicesSignedInOnly.any('), isTrue);
  });

  test('browsing is public', () {
    for (final location in [
      RouteNames.services,
      '${RouteNames.serviceStayResults}?q=Pokhara&checkIn=2026-10-21'
          '&checkOut=2026-10-23',
      RouteNames.serviceStayDetailPath('a'),
      RouteNames.serviceTravelDetailPath('a'),
      RouteNames.serviceBankDetailPath('a'),
      RouteNames.serviceBankProductPath('a'),
    ]) {
      expect(isPublic(location), isTrue, reason: location);
    }
  });

  test('bookings, enquiries and appointments are signed-in only', () {
    for (final location in [
      RouteNames.myBookings,
      RouteNames.bookingCheckout,
      RouteNames.bookingDetailPath('a'),
      RouteNames.bookingConfirmedPath('a'),
      RouteNames.bankEnquiryDetailPath('a'),
      RouteNames.bankAppointmentDetailPath('a'),
    ]) {
      expect(isPublic(location), isFalse, reason: location);
    }
    // The forms live outside /services and are never public.
    expect(
      routePathMatches(
        RouteNames.bankEnquiryFormPath('a'),
        RouteNames.services,
      ),
      isFalse,
    );
  });

  test('every Services route is registered, Services as a shell branch', () {
    for (final name in [
      'services',
      'serviceStayResults',
      'serviceStayDetail',
      'serviceTravelResults',
      'serviceTravelDetail',
      'serviceBankDetail',
      'serviceBankProduct',
      'bankEnquiryForm',
      'bankAppointmentForm',
      'bankEnquiryDetail',
      'bankAppointmentDetail',
      'myBookings',
      'bookingCheckout',
      'bookingConfirmed',
      'bookingDetail',
    ]) {
      expect(router.contains('path: RouteNames.$name,'), isTrue, reason: name);
    }
    // Results before the id route, and the bank request pages before the
    // bank page, so `results` / `appointments` is never read as an id.
    expect(
      router.indexOf('path: RouteNames.serviceStayResults,'),
      lessThan(router.indexOf('path: RouteNames.serviceStayDetail,')),
    );
    expect(
      router.indexOf('path: RouteNames.bankAppointmentDetail,'),
      lessThan(router.indexOf('path: RouteNames.serviceBankDetail,')),
    );
    expect(
      router.indexOf('path: RouteNames.bookingCheckout,'),
      lessThan(router.indexOf('path: RouteNames.bookingDetail,')),
    );
  });
}
