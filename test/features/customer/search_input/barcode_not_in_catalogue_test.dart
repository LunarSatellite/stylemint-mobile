import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/barcode_not_in_catalogue.dart';

import '../mall_home/mall_test_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<Map<String, int>> _pumpNotFound(
  WidgetTester tester, {
  String code = '5901234123457',
  double width = 390,
  double textScale = 1,
}) async {
  final taps = <String, int>{'again': 0, 'search': 0, 'type': 0};
  await pumpMallApp(
    tester,
    location: '/',
    width: width,
    textScale: textScale,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: BarcodeNotInCatalogue(
            code: code,
            onScanAgain: () => taps['again'] = taps['again']! + 1,
            onSearchCode: () => taps['search'] = taps['search']! + 1,
            onTypeInstead: () => taps['type'] = taps['type']! + 1,
          ),
        ),
      ),
    ],
  );
  return taps;
}

void main() {
  testWidgets('an unmatched code lands on a named state, not a blank screen', (
    tester,
  ) async {
    await _pumpNotFound(tester);

    expect(_key('barcode-not-in-catalogue'), findsOneWidget);
    expect(
      find.text('No StyleMint product carries this code'),
      findsOneWidget,
    );
    // The digits are shown so a misread can be told from a genuine miss.
    expect(find.text('Scanned code 5901234123457'), findsOneWidget);
  });

  testWidgets('it offers three ways on, and each one fires', (tester) async {
    final taps = await _pumpNotFound(tester);

    await tester.tap(find.text('Scan another code'));
    await tester.pump();
    await tester.tap(_key('barcode-search-code'));
    await tester.pump();
    await tester.tap(_key('barcode-type-instead'));
    await tester.pump();

    expect(taps, {'again': 1, 'search': 1, 'type': 1});
  });

  testWidgets('every control carries a semantics label', (tester) async {
    await _pumpNotFound(tester);

    expect(
      find.bySemanticsLabel('Search the Mall for the code 5901234123457'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Type your search instead'), findsOneWidget);
    expect(find.text('Scan another code'), findsOneWidget);
  });

  testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
    await _pumpNotFound(
      tester,
      code: 'SM-2026-LONGER-CODE-0001',
      width: 320,
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });
}
