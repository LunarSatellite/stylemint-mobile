import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Where a shopper lives is personal data. It is allowed to travel in a
/// request body and nowhere else: not in a URL path, not in a query string,
/// not in a log line, not in analytics, not in a crash breadcrumb.
///
/// Asserting that at one call site only proves that call site. These scan the
/// shipped source instead, so a leak introduced anywhere under `lib/` fails
/// here rather than in someone's log aggregator.
void main() {
  /// Every non-generated Dart file we actually ship.
  Iterable<File> shippedSources() => Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where(
        (f) =>
            !f.path.endsWith('.g.dart') && !f.path.endsWith('.freezed.dart'),
      );

  bool isComment(String line) {
    final t = line.trimLeft();
    return t.startsWith('//') || t.startsWith('*') || t.startsWith('/*');
  }

  test('no coordinate is written to a log, a route or a query string', () {
    final coordinate = RegExp('latitude|longitude', caseSensitive: false);
    final sink = RegExp(
      r'debugPrint|developer\.log|\bprint\(|logger\.|Logger\(|'
      'queryParameters|queryParams|'
      r'context\.(go|push|replace|pushNamed|goNamed)|'
      r'GoRouter\.of|Uri\.(parse|https|http)',
    );

    final offenders = <String>[];
    for (final file in shippedSources()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        // Comments explain the rule; they don't break it.
        if (isComment(line)) continue;
        if (coordinate.hasMatch(line) && sink.hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A coordinate reached a log, a route or a query string. It may '
          'travel in a request body only.\n${offenders.join('\n')}',
    );
  });

  test('no route declares a coordinate path or query parameter', () {
    final routeCoordinate = RegExp(
      r':lat\b|:lng\b|:latitude|:longitude|'
      """['"]lat['"]|['"]lng['"]|['"]latitude['"]|['"]longitude['"]""",
      caseSensitive: false,
    );

    final offenders = <String>[];
    for (final file in shippedSources().where(
      (f) => f.path.contains('routes'),
    )) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (isComment(lines[i])) continue;
        if (routeCoordinate.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'A route carries a coordinate. Routes are logged, restored and '
          'shared; the point belongs in the body.\n${offenders.join('\n')}',
    );
  });

  test('the address write path builds no URL from a coordinate', () {
    // Narrower and stricter than the sweep above: in the shipping data layer
    // the point may appear in a body map and in nothing else.
    final offenders = <String>[];
    for (final file in shippedSources().where(
      (f) => f.path.contains('shipping') && f.path.contains('data'),
    )) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (isComment(line)) continue;
        if (RegExp(r'queryParameters|Uri\.|\$\{?lat|\$\{?lng').hasMatch(line)) {
          offenders.add('${file.path}:${i + 1}: ${line.trim()}');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
