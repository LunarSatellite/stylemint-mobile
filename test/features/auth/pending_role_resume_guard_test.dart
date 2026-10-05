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
}
