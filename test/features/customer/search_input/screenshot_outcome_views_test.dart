import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/search_input/presentation/widgets/screenshot_no_match.dart';

/// The two dead ends a screenshot search can land on, and the rule they both
/// exist to enforce: neither shows a product, and neither says anything the
/// server did not.
Widget _host(Widget child, {double width = 320, double textScale = 1}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 640),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(body: child),
      ),
    );

void main() {
  group('RecognizedNoMatch', () {
    testWidgets('names what was seen and offers no product', (tester) async {
      await tester.pumpWidget(
        _host(
          ScreenshotNoMatchView(
            recognizedFeatures: const ['tan', 'leather satchel'],
            onTryAnother: () {},
            onTypeInstead: () {},
          ),
        ),
      );

      // The informative half: the Mall saw it and does not stock it.
      expect(find.text('The Mall does not stock this'), findsOneWidget);
      expect(find.byKey(const ValueKey('screenshot-features')), findsOneWidget);
      expect(find.text('tan'), findsOneWidget);
      expect(find.text('leather satchel'), findsOneWidget);

      // Nothing that could be mistaken for a result.
      expect(find.byType(Image), findsNothing);
      expect(find.textContaining('you might also like'), findsNothing);
    });

    testWidgets('reads the features out as one label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          ScreenshotNoMatchView(
            recognizedFeatures: const ['tan', 'leather satchel'],
            onTryAnother: () {},
            onTypeInstead: () {},
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('What StyleMint saw: tan, leather satchel'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('with no features it stays general, never blank', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ScreenshotNoMatchView(onTryAnother: () {}, onTypeInstead: () {}),
        ),
      );

      // The multimodal endpoint reports the outcome but not the features.
      // The heading must not promise a list that is not there.
      expect(find.text('The Mall could not find this'), findsOneWidget);
      expect(find.byKey(const ValueKey('screenshot-features')), findsNothing);
      expect(
        find.byKey(const ValueKey('screenshot-features-heading')),
        findsNothing,
      );
    });

    testWidgets('blank feature strings are dropped, not rendered', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ScreenshotNoMatchView(
            recognizedFeatures: const ['  ', '', 'tan'],
            onTryAnother: () {},
            onTypeInstead: () {},
          ),
        ),
      );

      expect(find.text('tan'), findsOneWidget);
      // One chip, not three: an empty chip is an empty label.
      expect(find.byType(DecoratedBox), findsWidgets);
      expect(find.text(''), findsNothing);
    });
  });

  group('NotRecognized', () {
    testWidgets('is worded differently and claims nothing about stock', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          ScreenshotNotRecognizedView(
            onTryAnother: () {},
            onTypeInstead: () {},
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('screenshot-not-recognized')),
        findsOneWidget,
      );
      expect(
        find.text('StyleMint could not read this picture'),
        findsOneWidget,
      );
      // Distinct from the no-match wording, and no claim about the catalogue.
      expect(find.text('The Mall does not stock this'), findsNothing);
      expect(find.textContaining('does not stock'), findsNothing);
      expect(find.byType(Image), findsNothing);
    });
  });

  group('both dead ends', () {
    for (final (name, build) in <(String, Widget Function())>[
      (
        'no match',
        () => ScreenshotNoMatchView(
          recognizedFeatures: const ['tan', 'leather satchel', 'brass buckle'],
          onTryAnother: () {},
          onTypeInstead: () {},
        ),
      ),
      (
        'not recognized',
        () => ScreenshotNotRecognizedView(
          onTryAnother: () {},
          onTypeInstead: () {},
        ),
      ),
    ]) {
      testWidgets('$name: no overflow at 320dp and text scale 1.3', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_host(build(), textScale: 1.3));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });

      testWidgets('$name: every control carries a semantics label', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_host(build()));

        expect(
          find.bySemanticsLabel('Try another screenshot'),
          findsAtLeastNWidgets(1),
        );
        expect(
          find.bySemanticsLabel('Type your search instead'),
          findsAtLeastNWidgets(1),
        );
        handle.dispose();
      });

      testWidgets('$name: both ways forward are wired', (tester) async {
        var tried = 0;
        var typed = 0;
        final widget = name == 'no match'
            ? ScreenshotNoMatchView(
                onTryAnother: () => tried++,
                onTypeInstead: () => typed++,
              )
            : ScreenshotNotRecognizedView(
                onTryAnother: () => tried++,
                onTypeInstead: () => typed++,
              );

        await tester.pumpWidget(_host(widget));
        await tester.tap(find.byKey(const ValueKey('screenshot-try-another')));
        await tester.tap(find.byKey(const ValueKey('screenshot-type-instead')));

        expect(tried, 1);
        expect(typed, 1);
      });
    }
  });
}
