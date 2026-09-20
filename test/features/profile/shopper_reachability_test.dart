import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Four shopper-facing capabilities were built, tested, wired to working
/// endpoints — and unreachable by a shopper. They lived only on the `/settings`
/// screen, and the only three routes to `/settings` are the **vendor** menu,
/// the **creator** menu and the vendor profile. A customer could never open it.
///
/// A screen with no navigation path is not a feature, so this pins the entry
/// points rather than the screens. It scans source because the failure is the
/// *absence* of a call — a widget test of the profile screen would pass just as
/// happily with the tiles deleted, since nothing else references them.
void main() {
  final profile = File(
    'lib/features/profile/presentation/screens/profile_screen.dart',
  );

  /// Route name → what a shopper loses when it is stranded.
  const mustBeReachable = <String, String>{
    'RouteNames.settingsShoppingPlans':
        'Shopping plans — the shopper cannot open a plan they asked for',
    'RouteNames.settingsConnectedAssistants':
        'Connected assistants — no way to see or revoke an agent',
    'RouteNames.myClienteling':
        'In-store assistance — the only control that turns an associate '
        'claim into credit, so without it a claim can never be confirmed',
  };

  test('the customer profile reaches every shopper-facing settings screen', () {
    expect(profile.existsSync(), isTrue, reason: 'profile screen moved');
    final source = profile.readAsStringSync();

    final stranded = mustBeReachable.entries
        .where((e) => !source.contains(e.key))
        .map((e) => '${e.key} — ${e.value}')
        .toList();

    expect(
      stranded,
      isEmpty,
      reason:
          'these are reachable only from /settings, which no customer can '
          'open. Re-add the tile rather than relying on deep links:\n'
          '${stranded.join('\n')}',
    );
  });
}
