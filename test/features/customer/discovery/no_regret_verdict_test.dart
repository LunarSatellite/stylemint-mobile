import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **No surface in this app reads a blended regret score or a regret level.**
///
/// Product detail used to draw `RegretAssessment`, which shipped a
/// `regretScore` — a weighted blend of return rate and rating — and a
/// `regretLevel` of Low / Medium / High as a green, amber or red chip. Three
/// things were wrong with it at once, and every one of them is banned
/// elsewhere in this codebase by a reflection test:
///
/// 1. **A blended score.** Two unrelated measurements collapsed into one
///    number, so the reader could not see what any part of it rested on.
/// 2. **An implied verdict on a seller.** "Often regretted", in red, next to
///    a product somebody is selling.
/// 3. **A cross-category comparison.** The blend was computed against
///    `RegretRules.WorstReturnRate = 0.30`, one universal constant, so 6% on
///    a book read as fine and 25% on a shoe read as near-worst — a
///    difference that says nothing about either product. Return rates belong
///    to categories far more than to products.
///
/// The replacement, `/v1/public/products/{id}/return-record`, reports
/// within-category counts and one within-category comparison, and carries no
/// score, level, confidence or rank at all.
///
/// A widget test proves one card behaves. This reads the tree, so a second
/// surface cannot reintroduce the field a year from now.
const List<String> _bannedIdentifiers = [
  'regretScore',
  'regretLevel',
  'RegretLevel',
  'RegretAssessment',
  'RegretCheck',
  'regretCheckProvider',
  // The retired route. Calling it is how a score gets back into the app.
  'regret-check',
];

Iterable<File> _dartFilesUnder(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _posix(String path) => path.replaceAll(r'\', '/');

/// Strips `//` and `///` comments, so prose explaining the retired shape —
/// including the doc comment on the card that replaced it — cannot trip the
/// scan. Only code counts.
String _code(String line) {
  final slash = line.indexOf('//');
  return slash == -1 ? line : line.substring(0, slash);
}

void main() {
  test('no file in lib/ reads a regret score, a regret level or the '
      'retired route', () {
    final offenders = <String>[];
    for (final file in _dartFilesUnder('lib')) {
      final path = _posix(file.path);
      final lines = file.readAsStringSync().split('\n');
      for (var i = 0; i < lines.length; i++) {
        final code = _code(lines[i]);
        for (final banned in _bannedIdentifiers) {
          if (code.contains(banned)) {
            offenders.add('$path:${i + 1} reads $banned');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A blended score, a Low/Medium/High verdict, or the route that '
          'serves them. Use ProductReturnRecord: within-category counts, '
          'each rate beside the two counts it came from.',
    );
  });

  test('exactly one place calls the return-record route', () {
    final callers = <String>[];
    for (final file in _dartFilesUnder('lib')) {
      final lines = file.readAsStringSync().split('\n');
      for (final line in lines) {
        // The route, not the widget keys that share its name.
        if (_code(line).contains("/return-record'")) {
          callers.add(_posix(file.path));
        }
      }
    }

    const datasource =
        'lib/features/customer/discovery/data/datasources/'
        'discovery_remote_datasource.dart';
    expect(callers, [datasource]);
  });

  test('nothing in lib/ carries a universal worst-return-rate constant', () {
    final offenders = <String>[];
    for (final file in _dartFilesUnder('lib')) {
      final source = file.readAsStringSync();
      for (final banned in const [
        'worstReturnRate',
        'WorstReturnRate',
        'maxReturnRate',
      ]) {
        if (source.contains(banned)) {
          offenders.add('${_posix(file.path)} declares $banned');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A single cross-category rate is the trap this work removed. A '
          "product is only ever measured against its own category's "
          'measured rate, and the server supplies that.',
    );
  });
}
