import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/routes/route_path_match.dart';

/// Guests can search: Discover, the results and the product listing that
/// "See all" opens are all public paths, so a signed-out shopper is never
/// sent to sign in just for typing in the search box.
///
/// Read as text, as the other reachability checks do, because building the
/// GoRouter needs the whole auth stack.
void main() {
  late final router = File('lib/routes/app_router.dart').readAsStringSync();

  /// The entries of the router's `_publicPaths` set.
  late final publicPaths = () {
    final start = router.indexOf('const _publicPaths = {');
    final end = router.indexOf('};', start);
    expect(start, greaterThan(-1), reason: '_publicPaths not found');
    return RegExp(
      r'RouteNames\.(\w+),',
    ).allMatches(router.substring(start, end)).map((m) => m.group(1)!).toSet();
  }();

  test('search, its results and the listing are public paths', () {
    expect(
      publicPaths,
      containsAll(['search', 'searchResults', 'productListing']),
    );
  });

  test('a results location with a query matches the public pattern', () {
    expect(
      routePathMatches(
        '${RouteNames.searchResults}?q=red%20kurta',
        RouteNames.searchResults,
      ),
      isTrue,
    );
    expect(
      routePathMatches('/products?q=red+kurta', RouteNames.productListing),
      isTrue,
    );
  });

  test('both routes are registered', () {
    expect(router.contains('path: RouteNames.searchResults'), isTrue);
    expect(router.contains('path: RouteNames.productListing'), isTrue);
  });
}
