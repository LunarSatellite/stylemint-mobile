import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

/// Password auth had three built screens and zero registered routes.
///
/// That is not merely dead code. Identity's `AuthLinkOptions` sets
/// `PasswordResetUrl` to `https://<app-links host>/reset-password` and its own
/// comment says to keep that in lockstep with the app — so the backend was
/// configured to email people a link into a route the app did not have. Anyone
/// who requested a reset followed the mail to go_router's error page.
///
/// Like the sibling reachability checks, these read the router as text rather
/// than building a `GoRouter`, which would drag in the whole auth stack. The
/// fact under test is the same either way: the path is registered, and the
/// redirect lets the person who arrives actually finish.
void main() {
  late final router = File('lib/routes/app_router.dart').readAsStringSync();

  group('the emailed password reset', () {
    test('lands on a registered route', () {
      expect(
        router.contains('path: RouteNames.resetPassword'),
        isTrue,
        reason: 'the reset link in the backend/s email has nowhere to land',
      );
      expect(router.contains('ResetPasswordScreen('), isTrue);
    });

    test('its path matches the URL the backend is configured to send', () {
      // AuthLinkOptions.PasswordResetUrl ends in this exact path. If either
      // side moves, the mail goes somewhere the app cannot route.
      expect(RouteNames.resetPassword, '/reset-password');
    });

    test('works while signed out', () {
      expect(
        _publicPathsBlock(router).contains('RouteNames.resetPassword'),
        isTrue,
        reason: 'a forgotten password is exactly the signed-out case',
      );
    });

    test('is NOT bounced away from when already signed in', () {
      // The other sign-in surfaces belong in _authOnlyPaths, which redirects an
      // authenticated user to home. A reset link does not: people tap it on a
      // phone where they are still signed in, and sending them home would leave
      // them unable to finish the reset they just asked for.
      expect(
        _authOnlyPathsBlock(router).contains('RouteNames.resetPassword'),
        isFalse,
        reason: 'signing in elsewhere must not block finishing a reset',
      );
    });
  });

  group('the screens the reset flow hands off to', () {
    test('its success exit is registered', () {
      // ResetPasswordScreen does context.go(passwordLogin) once the password
      // is changed. Registering the arrival without the exit would fix the
      // dead link and replace it with a dead landing.
      expect(router.contains('path: RouteNames.passwordLogin'), isTrue);
      expect(router.contains('PasswordLoginScreen()'), isTrue);
    });

    test('the forgot-password screen it starts from is registered', () {
      // PasswordLoginScreen pushes this from its "Forgot password?" row.
      expect(router.contains('path: RouteNames.forgotPassword'), isTrue);
      expect(router.contains('ForgotPasswordScreen()'), isTrue);
    });
  });
}

String _publicPathsBlock(String router) => _block(router, 'const _publicPaths');

String _authOnlyPathsBlock(String router) =>
    _block(router, 'const _authOnlyPaths');

/// The `{ … }` body of a top-level `const <name> = {` declaration, **with
/// comments stripped**.
///
/// The comments have to go. The first version of this helper kept them, and the
/// router explains in a comment inside `_authOnlyPaths` why `resetPassword` is
/// deliberately not in that set — which contains the literal
/// `RouteNames.resetPassword` and so made the "is it absent?" check read it as
/// present. A guard that a nearby comment can defeat is not a guard.
String _block(String source, String declaration) {
  final start = source.indexOf(declaration);
  expect(start, isNot(-1), reason: 'no $declaration in the router');
  final open = source.indexOf('{', start);
  final close = source.indexOf('};', open);
  expect(close, isNot(-1), reason: '$declaration is not closed');
  return source
      .substring(open, close)
      .split('\n')
      .map((line) {
        final comment = line.indexOf('//');
        return comment == -1 ? line : line.substring(0, comment);
      })
      .join('\n');
}
