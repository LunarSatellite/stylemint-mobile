import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A source-level guard on the one property this feature cannot test at
/// runtime: **the cleartext marker secret exists in exactly one place.**
///
/// The platform stores only a SHA-256 digest, so a secret written to disk, to
/// a log, to a crash report or into a URL is a secret that has escaped the
/// single moment it was allowed to exist. A widget test can prove a screen
/// does not *render* one; only a scan over the source can prove no code path
/// *writes* one.
///
/// These tests read the repository's own files. They are deliberately blunt:
/// a false positive here costs a rename, and a false negative costs a leaked
/// credential.
void main() {
  final root = Directory.current.path;

  List<File> dartFilesUnder(String relative) {
    final dir = Directory('$root/$relative');
    if (!dir.existsSync()) return const [];
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList(growable: false);
  }

  /// Source with comments stripped, so prose *about* the secret never trips a
  /// guard that is looking for code.
  String codeOf(File file) => file
      .readAsStringSync()
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('///'))
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  final featureFiles = dartFilesUnder('lib/features/unit_markers');

  test('the feature has source to scan', () {
    expect(featureFiles, isNotEmpty);
  });

  test('`secret` appears in only the files that are allowed to hold it', () {
    // The reveal path and nothing else: the wire DTO that receives it, the
    // domain type that carries it, the notifier state that holds it for one
    // screen, and the one screen that renders it.
    const allowed = {
      'data/models/unit_marker_dtos.dart',
      'domain/entities/unit_marker.dart',
      'presentation/notifiers/unit_marker_provision_notifier.dart',
      'presentation/screens/unit_marker_provision_screen.dart',
      'shared/providers.dart',
      // Names the routes but holds no value.
      'data/datasources/unit_markers_remote_datasource.dart',
      'domain/repositories/unit_markers_repository.dart',
      'domain/unit_marker_format.dart',
    };

    final offenders = <String>[];
    for (final file in featureFiles) {
      final relative = file.path
          .replaceAll(r'\', '/')
          .split('lib/features/unit_markers/')
          .last;
      if (allowed.contains(relative)) continue;
      if (RegExp(r'\bsecret\b', caseSensitive: false).hasMatch(codeOf(file))) {
        offenders.add(relative);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'these files mention a marker secret and are not on the reveal '
          'path: $offenders',
    );
  });

  test('no marker secret is ever written to storage', () {
    // Every persistence door the app has. A secret that reaches any of them
    // has outlived its one permitted moment.
    final persistence = RegExp(
      r'FlutterSecureStorage|SharedPreferences|secureStorage|prefs\.set'
      // \b before File( for the same reason as log( above: without it this
      // matches XFile( and PlatformFile(, which are file *references* from
      // the pickers, not the disk writes this guard is about.
      r'|TokenStorage|writeAsString|\bFile\(|Hive|sqflite|openDatabase',
    );
    final offenders = <String>[];
    for (final file in featureFiles) {
      final code = codeOf(file);
      if (persistence.hasMatch(code)) {
        offenders.add(file.path.replaceAll(r'\', '/').split('/').last);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'the unit markers feature must not persist anything: $offenders',
    );
  });

  test('no marker value is ever logged or sent to a reporter', () {
    final logging = RegExp(
      r'\bprint\(|debugPrint\(|logger\.|Logger\(|Sentry\.|captureMessage'
      // \b before log( matters: without it this also matches the tail of
      // AlertDialog( / showDialog( / SimpleDialog(, and the next person to
      // add a dialog here would hit a false positive and be tempted to
      // weaken the whole guard rather than narrow one pattern.
      r'|FirebaseCrashlytics|\blog\(',
    );
    final offenders = <String>[];
    for (final file in featureFiles) {
      if (logging.hasMatch(codeOf(file))) {
        offenders.add(file.path.replaceAll(r'\', '/').split('/').last);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'no logging in this feature: $offenders',
    );
  });

  test('no route, path or query is built from a marker or a secret', () {
    // The datasource is the only place that builds a URL for these routes.
    final source = File(
      '$root/lib/features/unit_markers/data/datasources/'
      'unit_markers_remote_datasource.dart',
    );
    expect(source.existsSync(), isTrue);

    for (final line in source.readAsStringSync().split('\n')) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('///') || trimmed.startsWith('//')) continue;
      final buildsAUrl = line.contains("'/v1/");
      if (!buildsAUrl) continue;
      // The literal path segment `unit-markers` is fine; what must never
      // appear is an *interpolated* marker or secret value.
      for (final forbidden in [
        r'$marker',
        r'${marker',
        r'$secret',
        r'${secret',
        'encodeComponent(marker',
        'encodeComponent(secret',
      ]) {
        expect(
          line,
          isNot(contains(forbidden)),
          reason: 'a credential must never be interpolated into a URL: $line',
        );
      }
    }
  });

  test('the scan and bind routes carry the marker in the request body', () {
    final source = File(
      '$root/lib/features/unit_markers/data/datasources/'
      'unit_markers_remote_datasource.dart',
    ).readAsStringSync();

    // `'marker': marker` is a body field in a `data:` map, three times: scan,
    // bind and correct.
    expect(
      RegExp("'marker': marker").allMatches(source).length,
      3,
      reason: 'scan, bind and correct each send the marker in the body',
    );
    // The reference-named routes interpolate the reference, which is not a
    // credential.
    expect(source, contains(r'${Uri.encodeComponent(reference)}'));
  });

  test('no route definition mentions a marker secret', () {
    final routes = File('$root/lib/routes/route_names.dart').readAsStringSync();
    // Only the opaque id and the line id appear in per-unit route paths.
    expect(routes, contains('/unit-tag/:unitMarkerId'));
    expect(routes, isNot(contains(':marker')));
    expect(routes, isNot(contains(':secret')));
  });

  test('the scanner hands the code to the repository, never to a route', () {
    final scanner = File(
      '$root/lib/features/scan/presentation/screens/'
      'style_mint_scan_screen.dart',
    ).readAsStringSync();

    // It reaches the scan call...
    expect(scanner, contains('marker: marker'));
    // ...and what gets navigated with is the opaque id the server answered.
    expect(scanner, contains('reading.unitMarkerId'));
    // The code itself is never spliced into a location.
    expect(scanner, isNot(contains("replaceFirst(':unitMarkerId', marker")));
    expect(scanner, isNot(contains('extra: marker')));
  });

  test('the provisioning screen is the only renderer of a secret', () {
    final screens = dartFilesUnder(
      'lib/features/unit_markers/presentation/screens',
    );
    final renderers = <String>[];
    for (final file in screens) {
      if (RegExp(r'\.secret\b').hasMatch(codeOf(file))) {
        renderers.add(file.path.replaceAll(r'\', '/').split('/').last);
      }
    }
    expect(renderers, ['unit_marker_provision_screen.dart']);
  });
}
