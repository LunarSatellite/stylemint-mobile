import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/search_input_actions.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../mall_home/mall_test_support.dart';
import 'search_input_test_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<List<String>> _pumpActions(
  WidgetTester tester, {
  required SearchInputCapabilities capabilities,
  double width = 390,
  double textScale = 1,
}) async {
  final submitted = <String>[];
  await pumpMallApp(
    tester,
    location: '/',
    width: width,
    textScale: textScale,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Center(
            child: SearchInputActions(
              currentQuery: () => 'half typed',
              onQuery: submitted.add,
            ),
          ),
        ),
      ),
      GoRoute(
        path: RouteNames.searchVoice,
        builder: (_, state) => Scaffold(
          body: Center(child: Text('voice:${state.extra}')),
        ),
      ),
      GoRoute(
        path: RouteNames.searchBarcode,
        builder: (_, _) => const Scaffold(body: Center(child: Text('scan'))),
      ),
    ],
    overrides: [
      searchInputCapabilitiesProvider.overrideWith(
        () => FixedCapabilities(capabilities),
      ),
    ],
  );
  return submitted;
}

void main() {
  testWidgets('offers both inputs while both can lead somewhere', (
    tester,
  ) async {
    await _pumpActions(
      tester,
      capabilities: const SearchInputCapabilities(
        voice: SearchInputStatus.ready,
        barcode: SearchInputStatus.ready,
      ),
    );

    expect(_key('discover-voice-search'), findsOneWidget);
    expect(_key('discover-barcode-search'), findsOneWidget);
    expect(find.bySemanticsLabel('Search by voice'), findsOneWidget);
    expect(find.bySemanticsLabel('Scan a product barcode'), findsOneWidget);
  });

  testWidgets('a device with no speech engine is offered no mic', (
    tester,
  ) async {
    await _pumpActions(
      tester,
      capabilities: const SearchInputCapabilities(
        voice: SearchInputStatus.unsupported,
        barcode: SearchInputStatus.ready,
      ),
    );

    expect(_key('discover-voice-search'), findsNothing);
    expect(_key('discover-barcode-search'), findsOneWidget);
  });

  testWidgets('a device with no camera is offered no scanner', (tester) async {
    await _pumpActions(
      tester,
      capabilities: const SearchInputCapabilities(
        voice: SearchInputStatus.ready,
        barcode: SearchInputStatus.unsupported,
      ),
    );

    expect(_key('discover-barcode-search'), findsNothing);
    expect(_key('discover-voice-search'), findsOneWidget);
  });

  testWidgets('a blocked permission keeps its button, so it can be undone', (
    tester,
  ) async {
    await _pumpActions(
      tester,
      capabilities: const SearchInputCapabilities(
        voice: SearchInputStatus.deniedForever,
        barcode: SearchInputStatus.denied,
      ),
    );

    expect(_key('discover-voice-search'), findsOneWidget);
    expect(_key('discover-barcode-search'), findsOneWidget);
  });

  testWidgets('voice carries the half-typed query into its screen', (
    tester,
  ) async {
    await _pumpActions(
      tester,
      capabilities: const SearchInputCapabilities(
        voice: SearchInputStatus.ready,
        barcode: SearchInputStatus.unsupported,
      ),
    );

    await tester.tap(_key('discover-voice-search'));
    await settleTransition(tester);

    expect(find.text('voice:half typed'), findsOneWidget);
  });

  testWidgets('a query handed back runs through the caller submit path', (
    tester,
  ) async {
    final submitted = await _pumpActions(
      tester,
      capabilities: const SearchInputCapabilities(
        voice: SearchInputStatus.unsupported,
        barcode: SearchInputStatus.ready,
      ),
    );

    await tester.tap(_key('discover-barcode-search'));
    await settleTransition(tester);
    expect(find.text('scan'), findsOneWidget);

    Navigator.of(tester.element(find.text('scan'))).pop('5901234123457');
    await settleTransition(tester);

    expect(submitted, ['5901234123457']);
  });

  testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
    await _pumpActions(
      tester,
      capabilities: const SearchInputCapabilities(
        voice: SearchInputStatus.ready,
        barcode: SearchInputStatus.ready,
      ),
      width: 320,
      textScale: 1.3,
    );

    expect(tester.takeException(), isNull);
  });
}
