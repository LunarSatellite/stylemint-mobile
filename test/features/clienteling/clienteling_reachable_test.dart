import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// A screen with no route — or a route nothing links to — is not done.
///
/// These read the router and the settings hub as text rather than building a
/// GoRouter, because building one needs the whole auth stack. What matters is
/// the same either way: the path is registered, and something a person can
/// actually tap points at it.
void main() {
  late final router = File('lib/routes/app_router.dart').readAsStringSync();
  late final settings = File(
    'lib/features/settings/presentation/screens/settings_screen.dart',
  ).readAsStringSync();

  test('the paths are what the screens expect', () {
    expect(RouteNames.associateClientBook, '/associate/clients');
    expect(
      RouteNames.associateClientBrief,
      '/associate/clients/:customerAccountId',
    );
    expect(RouteNames.myClienteling, '/settings/in-store-assistance');
  });

  test('the brief sits under the book, so a card can push onto it', () {
    expect(
      RouteNames.associateClientBrief.startsWith(
        '${RouteNames.associateClientBook}/',
      ),
      isTrue,
    );
  });

  test('every path is registered in the router', () {
    for (final path in [
      'RouteNames.associateClientBook',
      'RouteNames.associateClientBrief',
      'RouteNames.myClienteling',
    ]) {
      expect(
        router.contains('path: $path'),
        isTrue,
        reason: '$path has no GoRoute',
      );
    }
    expect(router.contains('ClientBookScreen()'), isTrue);
    expect(router.contains('ClientBriefScreen('), isTrue);
    expect(router.contains('MyClientelingScreen()'), isTrue);
  });

  test('both surfaces are reachable from settings', () {
    expect(settings.contains('RouteNames.myClienteling'), isTrue);
    expect(settings.contains('RouteNames.associateClientBook'), isTrue);
  });
}
