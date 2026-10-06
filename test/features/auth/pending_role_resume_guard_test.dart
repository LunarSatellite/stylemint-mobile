import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every screen that routes a signed-in user onward has to honour a role they
/// picked before signing in.
///
/// This has now gone wrong three times in the same shape. The screen takes a
/// successful auth, sends the user to `RouteNames.home`, and the choice they
/// made on the picker is silently dropped — they land on the reels feed
/// wondering why "Delivery partner" did nothing. It was fixed in the OAuth
/// callback, then found again on the passkey path, and the magic-link and
/// register paths had it too.
///
/// A unit test cannot catch this: each screen is a different widget with a
/// different auth provider, and the fault is an absent branch rather than a
/// wrong result. So this reads the sources. Any auth screen that navigates to
/// home must also consult [pendingRoleNeedsResume] — and a new sign-in method
/// added without that check fails here rather than in someone's hands.
void main() {
  final screens = Directory('lib/features/auth/presentation/screens');

  test('auth screens that route home also resume a pending role', () {
    expect(
      screens.existsSync(),
      isTrue,
      reason: 'auth screens moved — update this guard, do not delete it',
    );

    final offenders = <String>[];
    var checked = 0;

    for (final entity in screens.listSync().whereType<File>()) {
      if (!entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      if (!source.contains('RouteNames.home')) continue;

      checked++;
      if (!source.contains('pendingRoleNeedsResume')) {
        offenders.add(entity.uri.pathSegments.last);
      }
    }

    expect(
      checked,
      greaterThanOrEqualTo(5),
      reason: 'expected to find the known post-auth routers; '
          'if the files moved, point this guard at the new location',
    );

    expect(
      offenders,
      isEmpty,
      reason:
          'These route a signed-in user to home without checking whether they '
          'picked a role first, so the choice is discarded:\n'
          '  ${offenders.join('\n  ')}\n'
          'Read pendingRoleProvider and send them to '
          'RouteNames.userTypeSelection instead — the picker resumes it. See '
          'the OAuth callback screen for the shape.',
    );
  });

  /// The check above is per FILE, and that is not enough.
  ///
  /// The native Apple sign-in landed on a screen that already consulted
  /// pendingRoleNeedsResume — in a different handler. Its own success branch
  /// went straight to `RouteNames.home`, so the file passed and the bug
  /// shipped anyway: the fourth path in the same shape, on a screen that had
  /// just been fixed for the third.
  ///
  /// So look inside each success handler. A `loadSuccess` that reaches
  /// `RouteNames.home` without passing through the shared router or the
  /// pendingRole check is the fault, wherever else in the file those appear.
  test('no sign-in success handler routes to home on its own', () {
    final offenders = <String>[];

    for (final entity in screens.listSync().whereType<File>()) {
      if (!entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();

      for (final match in RegExp('loadSuccess:').allMatches(source)) {
        // The handler body, bounded generously: long enough to hold a
        // multi-line branch, short enough not to run into the next handler.
        final end = (match.start + 400).clamp(0, source.length);
        final body = source.substring(match.start, end);
        final upToNext = body.indexOf('loadFailure:');
        final handler = upToNext == -1 ? body : body.substring(0, upToNext);

        if (!handler.contains('RouteNames.home')) continue;
        if (handler.contains('_routeAfterAuth')) continue;
        if (handler.contains('pendingRoleNeedsResume')) continue;

        offenders.add(
          '${entity.uri.pathSegments.last}: '
          '${handler.split('\n').first.trim()}',
        );
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'These success handlers navigate to home themselves, so a role '
          'picked before signing in is dropped on that path even if the rest '
          'of the file handles it:\n  ${offenders.join('\n  ')}\n'
          'Delegate to the screen\'s shared post-auth router, or check '
          'pendingRoleProvider here too.',
    );
  });
}
