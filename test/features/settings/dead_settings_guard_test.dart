import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **A settings control the customer can change must reach something.**
///
/// This repository has shipped the same defect more than once: a section of
/// switches that set a local `bool`, look saved, and change nothing. The
/// Appearance section was one. The Edit Profile "Preferences" block was
/// another — "Share my activity with creators I follow" is a consent control
/// that was never written anywhere, never read back, and reset to off on
/// every open, so a customer could refuse and be refused nothing.
///
/// A widget test pins one screen. This reads the source, so a removed control
/// cannot quietly come back somewhere else, and so the identifiers behind it
/// cannot be revived as "the field is still there, just unwired".
///
/// ## What is scanned
///
/// Every `.dart` file under `lib/`, with comments stripped first. Comments
/// are deliberately exempt: the doc comment that explains why a control was
/// removed has to be free to name it, and a comment renders nothing.
void main() {
  /// Labels that were rendered to customers by controls that reached nothing.
  const removedLabels = <String, String>{
    'Share my activity with creators I follow':
        'consent control with no endpoint, no write, no read-back',
    'Include me in beta testing programs':
        'no beta-programme endpoint exists anywhere in the backend',
    'Send me personalized product recommendations':
        'duplicated the marketing switch; its own field was one of six '
        'sharing a single PushMarketing column',
    'Login Alerts':
        'UpdateNotificationTogglesVm has no Security field and '
        'IsPushEnabled returns true for Security before reading any column',
    'Password Changes': 'same Security column as Login Alerts',
    'Price Drops': 'one of six switches over the single PushMarketing column',
    'Back in Stock': 'one of six switches over the single PushMarketing column',
    'Flash Sales': 'one of six switches over the single PushMarketing column',
    'New Arrivals': 'one of six switches over the single PushMarketing column',
    'Personalized Offers':
        'one of six switches over the single PushMarketing column',
    'Product Recommendations':
        'one of six switches over the single PushMarketing column',
    'Return Status':
        'wrote the Messages rollup, which gates partnership invites; '
        'refunds are OrderRefunded and roll up to OrderUpdates',
  };

  /// Identifiers that backed those controls. A field kept alive after its
  /// control is gone is the same defect one layer down.
  const removedIdentifiers = <String>[
    '_shareActivity',
    '_includeBeta',
    '_sendPersonalized',
    'personalizedOffers',
    'priceDrops',
    'backInStock',
    'flashSales',
    'newArrivals',
    'productRecommendations',
    'loginAlerts',
    'passwordChanges',
    'returnStatus',
    'commentReplies',
    'newOrderForVendor',
    'partnershipEvents',
    'ticketUpdates',
    'ordersDelivered',
  ];

  /// Removes `//` line comments and `/* */` block comments, leaving string
  /// literals intact. Good enough for a guard: it never *hides* source, it
  /// only ignores prose.
  String stripComments(String source) {
    final out = StringBuffer();
    var i = 0;
    String? quote;
    while (i < source.length) {
      final c = source[i];
      if (quote != null) {
        out.write(c);
        if (c == r'\') {
          if (i + 1 < source.length) out.write(source[i + 1]);
          i += 2;
          continue;
        }
        if (source.startsWith(quote, i)) {
          i += quote.length;
          quote = null;
          continue;
        }
        i += 1;
        continue;
      }
      for (final q in const ["'''", '"""', "'", '"']) {
        if (source.startsWith(q, i)) {
          quote = q;
          break;
        }
      }
      if (quote != null) {
        out.write(quote);
        i += quote.length;
        continue;
      }
      if (source.startsWith('//', i)) {
        final end = source.indexOf('\n', i);
        i = end == -1 ? source.length : end;
        continue;
      }
      if (source.startsWith('/*', i)) {
        final end = source.indexOf('*/', i + 2);
        i = end == -1 ? source.length : end + 2;
        continue;
      }
      out.write(c);
      i += 1;
    }
    return out.toString();
  }

  final sources = <String, String>{
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')))
      file.path.replaceAll(r'\', '/'): stripComments(file.readAsStringSync()),
  };

  test('lib/ contains at least one screen to scan', () {
    expect(sources.length, greaterThan(100));
  });

  test('no removed control label is rendered anywhere in lib/', () {
    final offenders = <String>[];
    removedLabels.forEach((label, why) {
      for (final entry in sources.entries) {
        if (entry.value.contains(label)) {
          offenders.add('${entry.key}: "$label" — removed because $why');
        }
      }
    });
    expect(
      offenders,
      isEmpty,
      reason:
          'These controls reached nothing and were removed. Do not bring the '
          'label back without an endpoint that stores it and a consumer that '
          'reads it:\n${offenders.join('\n')}',
    );
  });

  test('no removed control keeps a field behind it', () {
    final offenders = <String>[];
    for (final id in removedIdentifiers) {
      final pattern = RegExp('\\b$id\\b');
      for (final entry in sources.entries) {
        if (pattern.hasMatch(entry.value)) {
          offenders.add('${entry.key}: $id');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'A preference field with no control and no consumer is the same '
          'defect one layer down:\n${offenders.join('\n')}',
    );
  });
}
