import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one rule this feature cannot get wrong.
///
/// The mandate credential is returned exactly once, on creation, and is never
/// retrievable again. It is what lets somebody else's software act as this
/// customer, so it must not reach any store the app — or anything else on the
/// device — can read back: `shared_preferences`, secure storage, the
/// clipboard, a log line, a crash breadcrumb, an analytics event, a route
/// argument or a URL.
///
/// These are source scans rather than behaviour tests on purpose: the risk is
/// a future edit quietly adding a `Clipboard.setData` or a `debugPrint`, and a
/// behaviour test would only catch it on the one path it happens to drive.
/// `connected_assistants_flow_test.dart` covers the runtime half by inspecting
/// `SharedPreferences`, the platform channels and the logs after a real
/// creation. Both halves are deliberately kept, exactly as delegated parcel
/// handover does for its one-time code.
void main() {
  final root = Directory('lib/features/customer/agent_commerce');

  List<File> featureSources() => root
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList(growable: false);

  bool isComment(String line) {
    final code = line.trimLeft();
    return code.startsWith('///') ||
        code.startsWith('//') ||
        code.startsWith('*');
  }

  setUpAll(() {
    expect(
      featureSources(),
      isNotEmpty,
      reason: 'the scan must actually find the feature files',
    );
  });

  group('the credential never reaches a store the app can read', () {
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

    test('no forbidden sink appears in any agent-commerce source file', () {
      final offences = <String>[];
      for (final file in featureSources()) {
        for (final line in file.readAsStringSync().split('\n')) {
          if (isComment(line)) continue;
          for (final entry in forbidden.entries) {
            if (line.contains(entry.key)) {
              offences.add('${file.path}: ${entry.key} — ${entry.value}');
            }
          }
        }
      }
      expect(offences, isEmpty, reason: offences.join('\n'));
    });

    test('print() is never called in the feature', () {
      for (final file in featureSources()) {
        for (final line in file.readAsStringSync().split('\n')) {
          if (isComment(line)) continue;
          expect(
            RegExp(r'(^|[^a-zA-Z.])print\s*\(').hasMatch(line.trimLeft()),
            isFalse,
            reason: '${file.path}: $line',
          );
        }
      }
    });
  });

  group('the credential never becomes a URL or a route', () {
    test('no route, deep link or query string carries it', () {
      for (final file in featureSources()) {
        for (final line in file.readAsStringSync().split('\n')) {
          if (isComment(line)) continue;
          final code = line.trimLeft();
          // Issuing is a modal sheet precisely so the credential never
          // becomes navigator state.
          expect(
            code.contains('pushNamed') ||
                code.contains('context.push(') ||
                code.contains('stylemint://'),
            isFalse,
            reason: '${file.path}: $code',
          );
        }
      }
    });

    test('the mandate id, not the credential, is what goes in a path', () {
      final source = File(
        'lib/features/customer/agent_commerce/data/datasources/'
        'agent_commerce_datasource.dart',
      ).readAsStringSync();
      final paths = RegExp(
        "'/v1/agent-commerce[^']*'",
      ).allMatches(source).map((m) => m.group(0)!).toList();
      expect(paths, isNotEmpty);
      for (final p in paths) {
        expect(p.toLowerCase(), isNot(contains('token')));
        expect(p.toLowerCase(), isNot(contains('credential')));
      }
      // Exactly one query parameter exists on this feature, and it is a count.
      final queries = RegExp(
        r'queryParameters: <String, dynamic>\{([^}]*)\}',
      ).allMatches(source).map((m) => m.group(1)!).toList();
      expect(queries, hasLength(1));
      expect(queries.single, contains("'limit'"));
      expect(queries.single.toLowerCase(), isNot(contains('token')));
    });

    test('the route the screen lives on carries nothing', () {
      final routes = File('lib/routes/route_names.dart').readAsStringSync();
      expect(routes, contains("'/settings/connected-assistants'"));
      // No path parameters at all on this route.
      expect(routes, isNot(contains('/settings/connected-assistants/:')));
    });
  });

  group('nothing that outlives the sheet has a credential field', () {
    const entityPath =
        'lib/features/customer/agent_commerce/domain/entities/'
        'agent_mandate.dart';
    const notifierPath =
        'lib/features/customer/agent_commerce/presentation/notifiers/'
        'agent_commerce_notifier.dart';
    const providersPath =
        'lib/features/customer/agent_commerce/shared/providers.dart';
    const sheetPath =
        'lib/features/customer/agent_commerce/presentation/widgets/'
        'agent_mandate_issue_sheet.dart';

    test('the notifier, its state and the providers never name one', () {
      for (final path in <String>[notifierPath, providersPath]) {
        for (final line in File(path).readAsStringSync().split('\n')) {
          if (isComment(line)) continue;
          expect(
            line.contains('credential'),
            isFalse,
            reason: '$path: $line',
          );
        }
      }
    });

    test(
      'only two files declare a credential field, and both are transient',
      () {
        final declarations = <String>[];
        for (final file in featureSources()) {
          for (final line in file.readAsStringSync().split('\n')) {
            if (RegExp(r'final\s+String\s+credential\s*;').hasMatch(line)) {
              declarations.add(file.path.replaceAll(r'\', '/'));
            }
          }
        }
        expect(declarations, hasLength(2));
        // 1. The create-response carrier, built and dropped inside one call.
        expect(
          declarations.any((p) => p.endsWith('agent_mandate.dart')),
          isTrue,
          reason: declarations.join(', '),
        );
        // 2. The panel that draws it, a StatelessWidget that dies with the
        //    sheet's frame.
        expect(
          declarations.any((p) => p.endsWith('agent_mandate_issue_sheet.dart')),
          isTrue,
          reason: declarations.join(', '),
        );
      },
    );

    test('the listed mandate type cannot carry one', () {
      final lines = File(entityPath).readAsStringSync().split('\n');
      final start = lines.indexWhere(
        (l) => l.startsWith('class AgentMandate {'),
      );
      final end = lines.indexWhere(
        (l) => l.startsWith('class IssuedAgentMandate'),
      );
      expect(start, greaterThan(-1));
      expect(end, greaterThan(start));
      for (final line in lines.sublist(start, end)) {
        if (isComment(line)) continue;
        expect(line.contains('credential'), isFalse, reason: line);
      }
    });

    test('the sheet holds it in local State, not in a provider', () {
      final sheet = File(sheetPath).readAsStringSync();
      // The field exists...
      expect(sheet, contains('String? _issuedCredential;'));
      // ...on the State class, and it is cleared on dispose and on close.
      expect(sheet, contains('_issuedCredential = null;'));
      // And the notifier is only ever told to go and look again — the issued
      // object is never handed to it.
      expect(sheet, contains('.refresh()'));
      expect(sheet, isNot(contains('.refresh(issued')));
      expect(sheet, isNot(contains('adopt(issued')));
      // The credential is not routed anywhere: issuing is a modal sheet.
      expect(sheet, contains('showModalBottomSheet'));
    });
  });

  test('no surface promises the credential can be recovered', () {
    const screen =
        'lib/features/customer/agent_commerce/presentation/screens/'
        'connected_assistants_screen.dart';
    const issueSheet =
        'lib/features/customer/agent_commerce/presentation/widgets/'
        'agent_mandate_issue_sheet.dart';
    const surfaces = <String>[screen, issueSheet];
    for (final path in surfaces) {
      final text = File(path).readAsStringSync().toLowerCase();
      for (final phrase in <String>[
        'show credential',
        'view credential',
        'see the credential',
        'show it again',
        'credential again',
        'reveal the credential',
        'copy it',
        'copy the credential',
      ]) {
        expect(text, isNot(contains(phrase)), reason: '$path: $phrase');
      }
    }
    // It does offer the honest alternative instead.
    final sheet = File(
      'lib/features/customer/agent_commerce/presentation/widgets/'
      'agent_mandate_issue_sheet.dart',
    ).readAsStringSync().toLowerCase();
    expect(sheet, contains('revoke it and connect the assistant'));
    expect(sheet, contains('we cannot show it or resend it'));
  });

  test('no product photograph is drawn anywhere in this feature', () {
    // The consent surfaces name products in words. The widened guard in
    // `product_photo_guard_test.dart` scans all of `lib/`; this keeps the
    // reason next to the feature it applies to.
    for (final file in featureSources()) {
      for (final line in file.readAsStringSync().split('\n')) {
        if (isComment(line)) continue;
        for (final sink in <String>[
          'Image.network',
          'MallNetworkImage',
          'MallProductCard',
          'imageUrl',
          'thumbnailUrl',
        ]) {
          expect(line.contains(sink), isFalse, reason: '${file.path}: $line');
        }
      }
    }
  });
}
