import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one rule this feature cannot get wrong.
///
/// `verificationCode` is returned exactly once, on creation, and is never
/// retrievable again. It is the credential that lets another person take the
/// customer's parcel, so it must not reach any store the app — or anything
/// else on the device — can read back: `shared_preferences`, secure storage,
/// the clipboard, a log line, a crash breadcrumb, an analytics event, a route
/// argument or a URL.
///
/// These are source scans rather than behaviour tests on purpose: the risk is
/// a future edit quietly adding a `Clipboard.setData` or a `debugPrint`, and a
/// behaviour test would only catch it on the one path it happens to drive.
/// `handover_delegation_flow_test.dart` covers the runtime half by inspecting
/// `SharedPreferences` and secure storage after a real creation.
void main() {
  final root = Directory('lib/features/customer/orders');

  List<File> handoverSources() => root
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (f) =>
            f.path.endsWith('.dart') &&
            f.uri.pathSegments.last.startsWith('handover_delegation'),
      )
      .toList(growable: false);

  setUpAll(() {
    expect(
      handoverSources(),
      isNotEmpty,
      reason: 'the scan must actually find the feature files',
    );
  });

  group('the one-time code never reaches a store the app can read', () {
    // Anything that writes somewhere readable later — by this app, by another
    // app, or by a support engineer reading a log.
    const forbidden = <String, String>{
      'Clipboard.setData':
          'the system clipboard is readable by this app and every other app, '
          'and survives long after the sheet closes',
      'SelectableText':
          'selection offers a copy action, which is the clipboard by another '
          'name',
      'SharedPreferences': 'plain on-disk storage',
      'FlutterSecureStorage':
          'even the keystore is a store, and the backend keeps only a hash — '
          'there is nothing to keep',
      'Hive': 'on-disk storage',
      'debugPrint': 'goes to logcat/console and to attached log collectors',
      'developer.log': 'goes to the dev log',
      'FirebaseCrashlytics': 'a crash report leaves the device',
      'logEvent': 'analytics leaves the device',
      'setCustomKey': 'crash-report custom keys leave the device',
    };

    test('no forbidden sink appears in any handover source file', () {
      final offences = <String>[];
      for (final file in handoverSources()) {
        final source = file.readAsStringSync();
        for (final entry in forbidden.entries) {
          // Skip the doc comments that explain why each sink is banned.
          for (final line in source.split('\n')) {
            final code = line.trimLeft();
            if (code.startsWith('///') ||
                code.startsWith('//') ||
                code.startsWith('*')) {
              continue;
            }
            if (code.contains(entry.key)) {
              offences.add('${file.path}: ${entry.key} — ${entry.value}');
            }
          }
        }
      }
      expect(offences, isEmpty, reason: offences.join('\n'));
    });

    test('print() is never called in the feature', () {
      for (final file in handoverSources()) {
        for (final line in file.readAsStringSync().split('\n')) {
          final code = line.trimLeft();
          if (code.startsWith('//') || code.startsWith('*')) continue;
          expect(
            RegExp(r'(^|[^a-zA-Z.])print\s*\(').hasMatch(code),
            isFalse,
            reason: '${file.path}: $code',
          );
        }
      }
    });
  });

  group('the code never becomes a URL or a route', () {
    test('no route, deep link or query string carries it', () {
      for (final file in handoverSources()) {
        final source = file.readAsStringSync();
        for (final line in source.split('\n')) {
          final code = line.trimLeft();
          if (code.startsWith('///') ||
              code.startsWith('//') ||
              code.startsWith('*')) {
            continue;
          }
          // The creation flow is a modal sheet precisely so the code never
          // becomes navigator state.
          expect(
            code.contains('pushNamed') || code.contains('stylemint://'),
            isFalse,
            reason: '${file.path}: $code',
          );
        }
      }
    });

    test('the delegation id, not the code, is what goes in a path', () {
      final source = File(
        'lib/features/customer/orders/data/datasources/'
        'handover_delegation_datasource.dart',
      ).readAsStringSync();
      // The only interpolations in the endpoint paths.
      final paths = RegExp(
        "'/v1/deliveries/[^']*'",
      ).allMatches(source).map((m) => m.group(0)!).toList();
      expect(paths, isNotEmpty);
      for (final p in paths) {
        expect(p.toLowerCase(), isNot(contains('code')));
        expect(p.toLowerCase(), isNot(contains('verification')));
      }
      // And no query parameters at all on these calls.
      expect(source, isNot(contains('queryParameters')));
    });
  });

  group('nothing that outlives the screen has a code field', () {
    test('the notifier state and the domain entity have no code', () {
      const notifierPath =
          'lib/features/customer/orders/presentation/notifiers/'
          'handover_delegation_notifier.dart';
      const entityPath =
          'lib/features/customer/orders/domain/entities/'
          'handover_delegation.dart';
      for (final path in <String>[notifierPath, entityPath]) {
        for (final line in File(path).readAsStringSync().split('\n')) {
          final code = line.trimLeft();
          if (code.startsWith('///') ||
              code.startsWith('//') ||
              code.startsWith('*')) {
            continue;
          }
          if (path.endsWith('handover_delegation.dart')) {
            // The entity file declares the single carrier type on purpose;
            // only `IssuedHandoverDelegation` may name the field.
            continue;
          }
          expect(
            code.contains('verificationCode'),
            isFalse,
            reason: '$path: $code',
          );
        }
      }
    });

    test('only IssuedHandoverDelegation declares verificationCode', () {
      final declarations = <String>[];
      for (final file in handoverSources()) {
        for (final line in file.readAsStringSync().split('\n')) {
          if (RegExp(r'final\s+String\s+verificationCode').hasMatch(line)) {
            declarations.add(file.path);
          }
        }
      }
      expect(declarations, hasLength(1));
      expect(declarations.single, endsWith('handover_delegation.dart'));
    });

    test('the sheet holds it in local State, not in a provider', () {
      final sheet = File(
        'lib/features/customer/orders/presentation/widgets/'
        'handover_delegation_sheet.dart',
      ).readAsStringSync();
      // The field exists...
      expect(sheet, contains('String? _issuedCode;'));
      // ...on the State class, and it is cleared on dispose.
      expect(sheet, contains('_issuedCode = null;'));
      // And the notifier is only ever told to go and look again — the issued
      // object is never handed to it.
      expect(sheet, isNot(contains('.refresh(issued')));
      expect(sheet, isNot(contains('adopt(issued')));
    });
  });

  test('the list surface never promises the code can be recovered', () {
    final card = File(
      'lib/features/customer/orders/presentation/widgets/'
      'handover_delegation_card.dart',
    ).readAsStringSync().toLowerCase();
    for (final phrase in <String>[
      'show code',
      'view code',
      'see the code',
      'resend',
      'code again',
    ]) {
      expect(card, isNot(contains(phrase)), reason: phrase);
    }
    // It does offer the honest alternative.
    final sheet = File(
      'lib/features/customer/orders/presentation/widgets/'
      'handover_delegation_sheet.dart',
    ).readAsStringSync().toLowerCase();
    expect(sheet, contains('revoke it and authorise someone again'));
  });
}
