import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/data/voice_recognizer.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/domain/search_input_status.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/screens/voice_search_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../mall_home/mall_test_support.dart';
import 'search_input_test_support.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _pumpVoice(
  WidgetTester tester, {
  required FakeVoiceRecognizer recognizer,
  FakeAppSettingsLauncher? launcher,
  double width = 390,
  double textScale = 1,
}) async {
  await pumpMallApp(
    tester,
    location: RouteNames.searchVoice,
    width: width,
    textScale: textScale,
    routes: [
      GoRoute(
        path: RouteNames.searchVoice,
        builder: (_, _) => const VoiceSearchScreen(),
      ),
    ],
    overrides: [
      voiceRecognizerProvider.overrideWith((ref) => recognizer),
      cameraProbeProvider.overrideWith(
        (ref) =>
            () async => false,
      ),
      if (launcher != null)
        appSettingsLauncherProvider.overrideWith((ref) => launcher.call),
    ],
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('transcribes as it listens and stays editable before searching', (
    tester,
  ) async {
    final recognizer = FakeVoiceRecognizer();
    await _pumpVoice(tester, recognizer: recognizer);

    expect(recognizer.listening, isTrue);
    expect(find.text('Listening'), findsOneWidget);

    recognizer.hear('red sneekers');
    await tester.pump();

    final field = tester.widget<TextField>(_key('voice-search-transcript'));
    expect(field.controller?.text, 'red sneekers');
    // While the engine is still writing, the field is its own; typing would
    // fight the next partial.
    expect(field.readOnly, isTrue);

    recognizer.hear('red sneekers', isFinal: true);
    await tester.pump();

    // A final reading ends the session. It does not search.
    expect(find.text('Not listening'), findsOneWidget);
    expect(
      tester.widget<TextField>(_key('voice-search-transcript')).readOnly,
      isFalse,
    );

    await tester.enterText(_key('voice-search-transcript'), 'red sneakers');
    await tester.pump();
    expect(
      tester
          .widget<TextField>(_key('voice-search-transcript'))
          .controller
          ?.text,
      'red sneakers',
    );
  });

  testWidgets('the corrected words are what gets searched', (tester) async {
    final recognizer = FakeVoiceRecognizer();
    String? searched;

    await pumpMallApp(
      tester,
      location: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => searched = await context.push<String>(
                  RouteNames.searchVoice,
                ),
                child: const Text('speak'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RouteNames.searchVoice,
          builder: (_, _) => const VoiceSearchScreen(),
        ),
      ],
      overrides: [
        voiceRecognizerProvider.overrideWith((ref) => recognizer),
        cameraProbeProvider.overrideWith(
          (ref) =>
              () async => false,
        ),
      ],
    );

    await tester.tap(find.text('speak'));
    await settleTransition(tester);
    await tester.pump();

    recognizer.hear('red sneekers', isFinal: true);
    await tester.pump();
    expect(searched, isNull, reason: 'a final transcript must not submit');

    await tester.enterText(_key('voice-search-transcript'), 'red sneakers');
    await tester.pump();
    await tester.tap(_key('voice-search-submit'));
    await settleTransition(tester);

    expect(searched, 'red sneakers');
  });

  testWidgets('Search stays disabled while there is nothing to search', (
    tester,
  ) async {
    await _pumpVoice(tester, recognizer: FakeVoiceRecognizer());
    final button = tester.widget<ButtonStyleButton>(
      _key('voice-search-submit'),
    );
    expect(button.onPressed, isNull);
  });

  group('permission recovery', () {
    testWidgets('a refusal offers to ask again', (tester) async {
      final recognizer = FakeVoiceRecognizer(
        prepareStatus: SearchInputStatus.denied,
      );
      await _pumpVoice(tester, recognizer: recognizer);

      expect(_key('search-input-recovery'), findsOneWidget);
      expect(find.text('Allow microphone'), findsOneWidget);
      expect(find.text('Type your search instead'), findsOneWidget);

      recognizer.prepareStatus = SearchInputStatus.ready;
      await tester.tap(find.text('Allow microphone'));
      await tester.pump();
      await tester.pump();

      expect(recognizer.prepareCalls, 2);
      expect(_key('voice-search-transcript'), findsOneWidget);
    });

    testWidgets('a permanent refusal opens the system settings', (
      tester,
    ) async {
      final launcher = FakeAppSettingsLauncher();
      await _pumpVoice(
        tester,
        recognizer: FakeVoiceRecognizer(
          prepareStatus: SearchInputStatus.deniedForever,
        ),
        launcher: launcher,
      );

      expect(
        find.text('The microphone is switched off for StyleMint'),
        findsOneWidget,
      );
      await tester.tap(find.text('Open settings'));
      await tester.pump();
      await tester.pump();

      expect(launcher.opened, 1);
    });

    testWidgets('a restricted device still gets a route to settings', (
      tester,
    ) async {
      final launcher = FakeAppSettingsLauncher();
      await _pumpVoice(
        tester,
        recognizer: FakeVoiceRecognizer(
          prepareStatus: SearchInputStatus.restricted,
        ),
        launcher: launcher,
      );

      expect(find.text('Open settings'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await tester.pump();
      await tester.pump();
      expect(launcher.opened, 1);
    });

    testWidgets('an unsupported device is told to type instead', (
      tester,
    ) async {
      await _pumpVoice(
        tester,
        recognizer: FakeVoiceRecognizer(
          prepareStatus: SearchInputStatus.unsupported,
        ),
      );

      expect(
        find.text("Voice search isn't available on this device"),
        findsOneWidget,
      );
      // No dead end: the only action present is the one that works.
      expect(find.text('Type your search instead'), findsOneWidget);
      expect(find.text('Open settings'), findsNothing);
    });
  });

  testWidgets('a mishearing is a retry, not a permission screen', (
    tester,
  ) async {
    final recognizer = FakeVoiceRecognizer();
    await _pumpVoice(tester, recognizer: recognizer);

    recognizer.fail(
      const VoiceFailure(
        kind: VoiceFailureKind.transient,
        status: SearchInputStatus.ready,
        code: 'error_no_match',
      ),
    );
    await tester.pump();

    expect(_key('voice-search-note'), findsOneWidget);
    expect(_key('search-input-recovery'), findsNothing);
    expect(_key('voice-search-transcript'), findsOneWidget);
  });

  testWidgets('every control carries a semantics label', (tester) async {
    await _pumpVoice(tester, recognizer: FakeVoiceRecognizer());

    expect(find.bySemanticsLabel('Stop listening'), findsOneWidget);
    // The field keeps its name once the hint is replaced by spoken words.
    expect(find.bySemanticsLabel('What we heard'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Search for the words above'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Listening to you now'), findsOneWidget);
  });

  testWidgets('no overflow at 320dp and text scale 1.3', (tester) async {
    final recognizer = FakeVoiceRecognizer();
    await _pumpVoice(
      tester,
      recognizer: recognizer,
      width: 320,
      textScale: 1.3,
    );

    recognizer.hear(
      'a long spoken query about emerald green evening dresses',
      isFinal: true,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('no overflow on the recovery screen at 320dp and 1.3', (
    tester,
  ) async {
    await _pumpVoice(
      tester,
      recognizer: FakeVoiceRecognizer(
        prepareStatus: SearchInputStatus.deniedForever,
      ),
      width: 320,
      textScale: 1.3,
    );

    expect(_key('search-input-recovery'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
