import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Source-level guards for screenshot search.
///
/// Widget tests prove the screens behave today. These prove the *shape* of
/// the code stays honest: five fabrications have reached or nearly reached
/// customers on this codebase, and every one of them was a reasonable-looking
/// line added later to a feature that was correct when it shipped.
const String _feature = 'lib/features/customer/search_input';

Iterable<File> _dartFilesUnder(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'));

String _posix(String path) => path.replaceAll(r'\', '/');

/// Comments are where these rules are explained; code is where they are
/// broken. Scanning only code lets the source document the constraint.
Iterable<String> _codeLines(File file) => file
    .readAsStringSync()
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('//'));

void main() {
  test('a screenshot is never written anywhere that outlives the search', () {
    // The retention promise is made to the buyer on the confirm step. It
    // holds only while no one in this feature learns to persist.
    const forbidden = {
      'SharedPreferences': 'a screenshot must not reach key-value storage',
      'getApplicationDocumentsDirectory':
          'a screenshot must not be copied into app storage',
      'getTemporaryDirectory': 'a screenshot must not be spooled to disk',
      'getExternalStorageDirectory':
          'a screenshot must not reach shared storage',
      'writeAsBytes': 'a screenshot must not be written to a file',
      'writeAsString': 'a screenshot must not be written to a file',
      'Hive': 'a screenshot must not reach a local database',
      'path_provider': 'nothing here needs a place to put files',
      'DefaultCacheManager': 'a screenshot must not be cached',
    };

    final offenders = <String>[];
    for (final file in _dartFilesUnder(_feature)) {
      for (final line in _codeLines(file)) {
        for (final entry in forbidden.entries) {
          if (line.contains(entry.key)) {
            offenders.add('${_posix(file.path)}: ${entry.value}');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'Screenshot search keeps the picture in memory for the length of '
          'one request and no longer. The confirm step tells the buyer so.',
    );
  });

  test(
    'the only File use in this feature is deleting the picker temp file',
    () {
      // `image_picker` writes the chosen image to a temp file before handing
      // it over; that file is the one copy this feature does not create, and
      // it is deleted the moment the bytes are read.
      final users = <String>[
        for (final file in _dartFilesUnder(_feature))
          if (file.readAsStringSync().contains('dart:io')) _posix(file.path),
      ];

      expect(users, ['$_feature/data/screenshot_picker.dart']);
      final picker = File(
        '$_feature/data/screenshot_picker.dart',
      ).readAsStringSync();
      expect(picker, contains('file.delete()'));
    },
  );

  test(
    'an unrecognised screenshot cannot borrow another search for results',
    () {
      // The fabrication this feature would be tempted into: when visual
      // search finds nothing, quietly run a popular/trending/recommended
      // query and present the answer as recognition.
      const forbidden = [
        'trending',
        'Trending',
        'recommend',
        'Recommend',
        'popular',
        'Popular',
        'bestsell',
        'Bestsell',
        'fallback',
        'Fallback',
      ];

      final offenders = <String>[];
      for (final file in _dartFilesUnder(_feature)) {
        final path = _posix(file.path);
        if (!path.contains('screenshot')) continue;
        final lines = file.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          // Comments are where the rule is explained; code is where it is
          // broken.
          final trimmed = line.trimLeft();
          if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
          for (final word in forbidden) {
            if (line.contains(word)) offenders.add('$path:${i + 1} — $word');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'No match is a no match. Never substitute a generic listing for '
            'recognition the server did not achieve.',
      );
    },
  );

  test('screenshot search takes no §5.9 action of its own', () {
    // Searching is all it does. Nothing here may price, reserve, add to a
    // cart or move money, with or without a tap.
    const forbidden = [
      'addToCart',
      'cartProvider',
      'checkout',
      'reserve',
      'placeOrder',
      'payment',
    ];

    final offenders = <String>[];
    for (final file in _dartFilesUnder(_feature)) {
      final path = _posix(file.path);
      if (!path.contains('screenshot')) continue;
      final source = file.readAsStringSync();
      for (final word in forbidden) {
        if (source.contains(word)) offenders.add('$path — $word');
      }
    }

    expect(offenders, isEmpty);
  });
}
