import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/screenshot_picker.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/screenshot_search_outcome.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/screens/screenshot_search_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../mall_home/mall_test_support.dart';
import 'search_input_test_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

final Uint8List _bytes = tinyPngBytes;

Future<void> _pumpScreenshot(
  WidgetTester tester, {
  required FakeScreenshotPicker picker,
  required FakeScreenshotSearch search,
  Uint8List? sharedBytes,
  FakeAppSettingsLauncher? launcher,
  double width = 390,
  double textScale = 1,
  // Two flows in one test would otherwise land on the same slot in the
  // tree, and Flutter would reuse the first screen's State — so initState,
  // and with it the whole entry path, would never run the second time.
  String screenKey = 'screenshot-screen',
}) async {
  await pumpMallApp(
    tester,
    location: RouteNames.searchScreenshot,
    width: width,
    textScale: textScale,
    routes: [
      GoRoute(
        path: RouteNames.searchScreenshot,
        builder: (_, _) => ScreenshotSearchScreen(
          key: ValueKey(screenKey),
          sharedBytes: sharedBytes,
        ),
      ),
      GoRoute(
        path: RouteNames.searchResults,
        builder: (_, state) =>
            Scaffold(body: Center(child: Text('results:${state.uri.query}'))),
      ),
    ],
    overrides: [
      screenshotPickerProvider.overrideWith((ref) => picker.call),
      screenshotNormalizerProvider.overrideWith((ref) => fakeNormalize),
      screenshotSearchProvider.overrideWith((ref) => search),
      // Nothing in this screen should probe the camera or the server.
      cameraProbeProvider.overrideWith(
        (ref) =>
            () async => false,
      ),
      visualSearchProbeProvider.overrideWith(
        (ref) =>
            () async => SearchInputStatus.ready,
      ),
      if (launcher != null)
        appSettingsLauncherProvider.overrideWith((ref) => launcher.call),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('a picked screenshot', () {
    testWidgets('is shown, and its disclosure, before anything is sent', (
      tester,
    ) async {
      final picker = FakeScreenshotPicker(ScreenshotPicked(_bytes));
      final search = FakeScreenshotSearch(const ScreenshotNoMatch());
      await _pumpScreenshot(tester, picker: picker, search: search);

      expect(_key('screenshot-preview'), findsOneWidget);
      expect(_key('screenshot-privacy-notice'), findsOneWidget);
      // §5.9 and the privacy rule in one assertion: arriving on the screen
      // uploads nothing. Only the buyer's tap does.
      expect(search.searched, isEmpty);
    });

    testWidgets('is searched only on the explicit tap, and lands on results', (
      tester,
    ) async {
      final picker = FakeScreenshotPicker(ScreenshotPicked(_bytes));
      final search = FakeScreenshotSearch(
        ScreenshotMatches(fakeResults(['Green tote'])),
      );
      await _pumpScreenshot(tester, picker: picker, search: search);

      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      expect(search.searched.single, _bytes);
      expect(find.text('results:visual=1'), findsOneWidget);
    });

    testWidgets('that matches nothing says so, and offers no products at all', (
      tester,
    ) async {
      final picker = FakeScreenshotPicker(ScreenshotPicked(_bytes));
      final search = FakeScreenshotSearch(const ScreenshotNoMatch());
      await _pumpScreenshot(tester, picker: picker, search: search);

      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      expect(_key('screenshot-no-match'), findsOneWidget);
      expect(find.text('The Mall could not find this'), findsOneWidget);
      // Not a results screen, and not one product name, price or card
      // anywhere on it. An unrecognised screenshot sells nothing.
      expect(find.textContaining('results:'), findsNothing);
      expect(find.textContaining('Green tote'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      // Both ways forward are present.
      expect(_key('screenshot-try-another'), findsOneWidget);
      expect(_key('screenshot-type-instead'), findsOneWidget);
    });

    testWidgets('recognised but unstocked names what the Mall saw', (
      tester,
    ) async {
      final picker = FakeScreenshotPicker(ScreenshotPicked(_bytes));
      final search = FakeScreenshotSearch(
        const ScreenshotNoMatch(
          recognizedFeatures: ['tan', 'leather satchel'],
        ),
      );
      await _pumpScreenshot(tester, picker: picker, search: search);

      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      // The informative ending: the platform saw it and does not stock it.
      expect(find.text('The Mall does not stock this'), findsOneWidget);
      expect(_key('screenshot-features'), findsOneWidget);
      expect(find.text('tan'), findsOneWidget);
      expect(find.text('leather satchel'), findsOneWidget);
      // Still not a product in sight.
      expect(find.textContaining('results:'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    });

    testWidgets('an unreadable picture gets its own ending, not a no-match', (
      tester,
    ) async {
      final picker = FakeScreenshotPicker(ScreenshotPicked(_bytes));
      final search = FakeScreenshotSearch(const ScreenshotNotRecognized());
      await _pumpScreenshot(tester, picker: picker, search: search);

      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      expect(_key('screenshot-not-recognized'), findsOneWidget);
      expect(
        find.text('StyleMint could not read this picture'),
        findsOneWidget,
      );
      // The three endings stay distinct: this one claims nothing about
      // whether the Mall stocks the item, because nothing was searched for.
      expect(_key('screenshot-no-match'), findsNothing);
      expect(find.textContaining('does not stock'), findsNothing);
      expect(find.textContaining('results:'), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
      // Both ways forward are still offered.
      expect(_key('screenshot-try-another'), findsOneWidget);
      expect(_key('screenshot-type-instead'), findsOneWidget);
    });

    testWidgets('can be swapped for another one after a no-match', (
      tester,
    ) async {
      final picker = FakeScreenshotPicker(ScreenshotPicked(_bytes));
      final search = FakeScreenshotSearch(const ScreenshotNoMatch());
      await _pumpScreenshot(tester, picker: picker, search: search);
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      await tester.tap(_key('screenshot-try-another'));
      await tester.pumpAndSettle();

      expect(picker.calls, 2);
      expect(_key('screenshot-preview'), findsOneWidget);
    });

    testWidgets('reports an unavailable service without inventing matches', (
      tester,
    ) async {
      final picker = FakeScreenshotPicker(ScreenshotPicked(_bytes));
      final search = FakeScreenshotSearch(
        const ScreenshotSearchUnavailable(
          'Visual search is not switched on for the Mall yet. Typing still '
          'works.',
          detail: 'service_unavailable',
        ),
      );
      await _pumpScreenshot(tester, picker: picker, search: search);
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      expect(_key('screenshot-unavailable'), findsOneWidget);
      expect(find.textContaining('Typing still works'), findsOneWidget);
      expect(_key('screenshot-unavailable-type-instead'), findsOneWidget);
      expect(find.textContaining('results:'), findsNothing);
    });
  });

  group('a shared screenshot', () {
    testWidgets('never opens the picker and reaches the same confirm step', (
      tester,
    ) async {
      final picker = FakeScreenshotPicker(const ScreenshotPickCancelled());
      final search = FakeScreenshotSearch(
        ScreenshotMatches(fakeResults(['Green tote'])),
      );
      await _pumpScreenshot(
        tester,
        picker: picker,
        search: search,
        sharedBytes: _bytes,
      );

      expect(picker.calls, 0);
      expect(_key('screenshot-preview'), findsOneWidget);
      expect(_key('screenshot-privacy-notice'), findsOneWidget);
      expect(search.searched, isEmpty);
    });

    testWidgets('is searched exactly as a picked one is', (tester) async {
      // The parity assertion: one path, one request shape, one set of
      // endings, whichever door the screenshot came through.
      final shared = FakeScreenshotSearch(
        ScreenshotMatches(fakeResults(['Green tote'])),
      );
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(const ScreenshotPickCancelled()),
        search: shared,
        sharedBytes: _bytes,
        screenKey: 'shared-flow',
      );
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();
      final sharedDestination = find.text('results:visual=1').evaluate().length;

      // Unmount the first flow completely before the second one is pumped,
      // so nothing of it — state, router, or provider container — can be
      // reused and make the comparison meaningless.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final picked = FakeScreenshotSearch(
        ScreenshotMatches(fakeResults(['Green tote'])),
      );
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(ScreenshotPicked(_bytes)),
        search: picked,
        screenKey: 'picked-flow',
      );
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      expect(picked.searched, isNotEmpty);
      expect(shared.searched, picked.searched);
      expect(shared.queries, picked.queries);
      expect(
        sharedDestination,
        find.text('results:visual=1').evaluate().length,
      );
    });
  });

  group('when the gallery is blocked', () {
    Future<void> pumpBlocked(
      WidgetTester tester,
      SearchInputStatus status, {
      FakeAppSettingsLauncher? launcher,
      double width = 390,
      double textScale = 1,
    }) => _pumpScreenshot(
      tester,
      picker: FakeScreenshotPicker(ScreenshotPickBlocked(status)),
      search: FakeScreenshotSearch(const ScreenshotNoMatch()),
      launcher: launcher,
      width: width,
      textScale: textScale,
    );

    testWidgets('a refusal for this attempt can be asked again', (
      tester,
    ) async {
      await pumpBlocked(tester, SearchInputStatus.denied);

      expect(_key('search-input-recovery'), findsOneWidget);
      expect(find.text('Allow photos'), findsOneWidget);
      expect(_key('search-input-type-instead'), findsOneWidget);
    });

    testWidgets('a permanent refusal sends the buyer to system settings', (
      tester,
    ) async {
      final launcher = FakeAppSettingsLauncher();
      await pumpBlocked(
        tester,
        SearchInputStatus.deniedForever,
        launcher: launcher,
      );

      expect(find.text('Open settings'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await tester.pumpAndSettle();
      expect(launcher.opened, 1);
    });

    testWidgets('a restricted device points at settings too', (tester) async {
      await pumpBlocked(tester, SearchInputStatus.restricted);

      expect(
        find.text('The camera is restricted on this device'),
        findsNothing,
      );
      expect(
        find.text('Photo access is restricted on this device'),
        findsOneWidget,
      );
      expect(find.text('Open settings'), findsOneWidget);
    });

    testWidgets('an unsupported chooser still offers typing', (tester) async {
      await pumpBlocked(tester, SearchInputStatus.unsupported);

      expect(find.text('Type your search instead'), findsWidgets);
    });
  });

  group('at 320dp and text scale 1.3', () {
    const narrow = 320.0;
    const scale = 1.3;

    testWidgets('the confirm step does not overflow', (tester) async {
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(ScreenshotPicked(_bytes)),
        search: FakeScreenshotSearch(const ScreenshotNoMatch()),
        width: narrow,
        textScale: scale,
      );

      expect(tester.takeException(), isNull);
      expect(_key('screenshot-search'), findsOneWidget);
    });

    testWidgets('the no-match state does not overflow', (tester) async {
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(ScreenshotPicked(_bytes)),
        search: FakeScreenshotSearch(const ScreenshotNoMatch()),
        width: narrow,
        textScale: scale,
      );
      // Short screen: the confirm step scrolls. Scrolling is the designed
      // behaviour; an overflow would have thrown before this line.
      await tester.ensureVisible(_key('screenshot-search'));
      await tester.pumpAndSettle();
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_key('screenshot-no-match'), findsOneWidget);
    });

    testWidgets('the recovery state does not overflow', (tester) async {
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(
          const ScreenshotPickBlocked(SearchInputStatus.deniedForever),
        ),
        search: FakeScreenshotSearch(const ScreenshotNoMatch()),
        width: narrow,
        textScale: scale,
      );

      expect(tester.takeException(), isNull);
      expect(_key('search-input-recovery'), findsOneWidget);
    });

    testWidgets('the unavailable state does not overflow', (tester) async {
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(ScreenshotPicked(_bytes)),
        search: FakeScreenshotSearch(
          const ScreenshotSearchUnavailable('Long enough to wrap twice over.'),
        ),
        width: narrow,
        textScale: scale,
      );
      // Short screen: the confirm step scrolls. Scrolling is the designed
      // behaviour; an overflow would have thrown before this line.
      await tester.ensureVisible(_key('screenshot-search'));
      await tester.pumpAndSettle();
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_key('screenshot-unavailable'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('every control on the confirm step is named', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(ScreenshotPicked(_bytes)),
        search: FakeScreenshotSearch(const ScreenshotNoMatch()),
      );

      expect(
        find.bySemanticsLabel('Search the Mall with this'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Choose a different screenshot'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Close screenshot search'),
        findsWidgets,
      );
      // The picture itself is described rather than announced as an
      // unlabelled image.
      expect(
        find.bySemanticsLabel(
          RegExp('screenshot you are about to search with'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('every control on the no-match state is named', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(ScreenshotPicked(_bytes)),
        search: FakeScreenshotSearch(const ScreenshotNoMatch()),
      );
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Try another screenshot'), findsWidgets);
      expect(
        find.bySemanticsLabel('Type your search instead'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('retention', () {
    testWidgets('a completed search leaves nothing in storage', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final picker = FakeScreenshotPicker(ScreenshotPicked(_bytes));
      final search = FakeScreenshotSearch(
        ScreenshotMatches(fakeResults(['Green tote'])),
      );
      await _pumpScreenshot(tester, picker: picker, search: search);
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      // No screenshot, no data URI, no "recent visual search" — not even a
      // key naming the feature.
      expect(prefs.getKeys(), isEmpty);
    });

    testWidgets('a no-match leaves nothing in storage either', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(ScreenshotPicked(_bytes)),
        search: FakeScreenshotSearch(const ScreenshotNoMatch()),
      );
      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    testWidgets('the picture is released as soon as the answer is in', (
      tester,
    ) async {
      await _pumpScreenshot(
        tester,
        picker: FakeScreenshotPicker(ScreenshotPicked(_bytes)),
        search: FakeScreenshotSearch(const ScreenshotNoMatch()),
      );
      expect(_key('screenshot-preview'), findsOneWidget);

      await tester.tap(_key('screenshot-search'));
      await tester.pumpAndSettle();

      // The preview is gone because the bytes are gone, not because a
      // different screen is merely drawn on top of them.
      expect(_key('screenshot-preview'), findsNothing);
    });
  });
}
