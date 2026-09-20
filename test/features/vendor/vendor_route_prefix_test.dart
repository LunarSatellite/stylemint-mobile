import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Commerce routes are `v1/*`; CRM/OmniFlow routes are `api/v1/*`. The split is
/// why the StyleMint absorption needed no route rewriting, and it is load-bearing.
///
/// These three vendor paths were being called with the CRM prefix against a
/// backend that maps them only under the commerce prefix, so each **404'd on
/// every open**. The route table serves:
///
///   v1/vendor/campaign-workspaces          (no api/ variant exists at all)
///   v1/vendor/digital-twin/scenarios       (api/ variant needs a stylemint/ segment)
///   v1/vendor/growth-quality               (same)
///
/// A blanket ban on `api/v1/vendor/` would be wrong — some vendor routes are
/// genuinely mapped under both prefixes. So this names the three that are not.
void main() {
  const wrong = <String>[
    'api/v1/vendor/campaign-workspaces',
    'api/v1/vendor/digital-twin',
    'api/v1/vendor/growth-quality',
  ];

  test('these vendor paths are never called with the CRM prefix', () {
    final offenders = <String>[];

    for (final file in Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final w in wrong) {
          if (lines[i].contains(w)) {
            offenders.add('${file.path}:${i + 1} -> $w');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'these map only under the commerce prefix; the CRM prefix 404s:\n'
          '${offenders.join('\n')}',
    );
  });
}
