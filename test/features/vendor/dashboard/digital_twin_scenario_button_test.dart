import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/simulated_figure.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/widgets/digital_twin_scenario_button.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/widgets/simulated_figure_tile.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

import '../../../shared/presentation/mall/mall_harness.dart';
import 'simulated_figure_fixtures.dart';

/// The measured Store Pulse numeral, copied from `_PulseMetric` in
/// `vendor_dashboard_screen.dart`. A test below fails if the dashboard's own
/// style drifts away from this copy.
final TextStyle storePulseNumeralStyle = DesignTokens.mediumSemibold.copyWith(
  fontSize: 21,
);

Future<void> pumpResult(
  WidgetTester tester,
  Map<String, dynamic> result, {
  double width = 390,
  double textScale = 1,
}) => pumpMall(
  tester,
  DigitalTwinScenarioResultDialog(result: result),
  width: width,
  textScale: textScale,
  inList: false,
);

/// Every string the tree actually puts on screen.
Iterable<String> renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((s) => s.isNotEmpty);

/// Source with `//` and `///` comments removed. Prose that explains why a
/// name is gone must not trip the check that it is gone — the same stripper
/// the product-photo guard uses.
String codeOf(String path) => File(path)
    .readAsLinesSync()
    .map((line) {
      final slash = line.indexOf('//');
      return slash == -1 ? line : line.substring(0, slash);
    })
    .join('\n');

/// Every node in the semantics subtree under [from].
///
/// A `Slider`'s configuration lives on a render object well below the widget,
/// so `tester.getSemantics(find.byType(Slider))` lands on an ancestor with no
/// value on it. Walking down is the honest way to ask what a screen reader
/// would actually meet.
List<SemanticsData> semanticsUnder(WidgetTester tester, Finder from) {
  final found = <SemanticsData>[];
  void visit(SemanticsNode node) {
    found.add(node.getSemanticsData());
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(tester.getSemantics(from));
  return found;
}

void expectLabelledAndTappable(
  WidgetTester tester,
  Finder finder,
  String label,
) {
  final data = tester.getSemantics(finder).getSemanticsData();
  expect(data.label, label, reason: 'control "$label" is not labelled');
  expect(
    data.hasAction(SemanticsAction.tap),
    isTrue,
    reason: 'control "$label" cannot be activated',
  );
}

void main() {
  testWidgets('opens bounded calibrated scenario controls', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: DigitalTwinScenarioButton())),
      ),
    );

    await tester.tap(find.byKey(DigitalTwinScenarioButton.runKey));
    await tester.pumpAndSettle();

    expect(find.text('Stress-test your store'), findsOneWidget);
    expect(find.text('Demand surge'), findsOneWidget);
    expect(find.text('Inventory loss'), findsOneWidget);
    expect(find.text('Capacity loss'), findsOneWidget);
    expect(find.text('Run calibrated scenario'), findsOneWidget);
  });

  group('every figure is marked at the figure', () {
    testWidgets("the word and the glyph share the numeral's own line", (
      tester,
    ) async {
      await pumpResult(tester, scenarioJson());

      final tiles = find.byType(SimulatedFigureTile);
      expect(tiles, findsNWidgets(4));

      const expected = {
        'Conversion': '12.5%',
        'Stockouts': '8%',
        'On-time fulfilment': '91.25%',
        'Gross merchandise value': '48,210.5',
      };
      for (var i = 0; i < 4; i++) {
        final tile = tiles.at(i);
        final label = tester.widget<SimulatedFigureTile>(tile).label;

        // The marker sits in the SAME Wrap as the numeral, so a vendor
        // cannot land on the number without the word entering the same
        // glance. Not a footnote, not a heading above the group.
        final line = find.descendant(of: tile, matching: find.byType(Wrap));
        expect(
          find.descendant(of: line, matching: find.text('Simulated')),
          findsOneWidget,
          reason: '"$label" has no provenance word beside its number',
        );
        expect(
          find.descendant(
            of: line,
            matching: find.byIcon(SimulatedFigureTile.simulatedGlyph),
          ),
          findsOneWidget,
          reason: '"$label" has no provenance glyph beside its number',
        );
        final value = find.descendant(
          of: line,
          matching: find.byKey(SimulatedFigureTile.valueKey),
        );
        expect(value, findsOneWidget);
        expect(tester.widget<Text>(value).data, expected[label]);
      }
    });

    testWidgets('each tile names the model it came out of', (tester) async {
      await pumpResult(tester, scenarioJson());
      expect(
        find.textContaining('Produced by a seeded model'),
        findsNWidgets(4),
      );
    });
  });

  group('a figure that did not arrive renders nothing', () {
    testWidgets('unreadable figures are dropped, not zeroed', (tester) async {
      await pumpResult(
        tester,
        scenarioJson(
          // The three ways this goes wrong: an object with no value, the old
          // bare-decimal shape, and an explicit null.
          conversion: <String, dynamic>{},
          stockout: 8.4,
          onTime: figureJson(simulatedValue: null),
        ),
      );

      expect(find.byType(SimulatedFigureTile), findsOneWidget);
      expect(find.text('Conversion'), findsNothing);
      expect(find.text('Stockouts'), findsNothing);
      expect(find.text('On-time fulfilment'), findsNothing);
      expect(find.text('Gross merchandise value'), findsOneWidget);

      for (final text in renderedText(tester)) {
        expect(
          text,
          isNot(anyOf(equals('0%'), equals('0'), equals('—'), equals('-'))),
          reason:
              'A missing simulated figure is not a measurement of zero, and a '
              'dash in a numeral slot reads as one.',
        );
      }
    });

    testWidgets('a response with nothing readable shows no number at all', (
      tester,
    ) async {
      await pumpResult(tester, <String, dynamic>{});

      expect(find.byType(SimulatedFigureTile), findsNothing);
      expect(find.byKey(SimulatedFigureTile.valueKey), findsNothing);
      expect(
        find.byKey(DigitalTwinScenarioResultDialog.emptyKey),
        findsOneWidget,
      );
      for (final text in renderedText(tester)) {
        expect(
          RegExp('[0-9]').hasMatch(text),
          isFalse,
          reason: 'the empty dialog rendered a digit: "$text"',
        );
      }
    });
  });

  group('units are rendered honestly', () {
    testWidgets('GMV carries no currency symbol', (tester) async {
      await pumpResult(tester, scenarioJson());

      final gmv = find.descendant(
        of: find.widgetWithText(SimulatedFigureTile, 'Gross merchandise value'),
        matching: find.byKey(SimulatedFigureTile.valueKey),
      );
      expect(tester.widget<Text>(gmv).data, '48,210.5');

      for (final text in renderedText(tester)) {
        for (final symbol in ['NPR', 'Rs.', 'Rs ', '₨', r'$', '€', '£', '₹']) {
          expect(
            text.contains(symbol),
            isFalse,
            reason:
                'The engine invents prices and declares no currency '
                '(unit: currency_unstated). "$symbol" in "$text" is the '
                'client naming one.',
          );
        }
      }
      expect(
        find.textContaining('currency not stated'),
        findsOneWidget,
        reason: 'the tile must say why there is no symbol',
      );
    });
  });

  group('provenance', () {
    testWidgets('an unknown token is drawn as simulated, not measured', (
      tester,
    ) async {
      await pumpResult(
        tester,
        scenarioJson(
          conversion: figureJson(provenance: 'Projected'),
          stockout: figureJson(provenance: null, simulatedValue: 8),
          onTime: figureJson(provenance: 'Blended', simulatedValue: 91.25),
          gmv: figureJson(
            provenance: 'SomethingNew',
            simulatedValue: 48210.5,
            unit: 'currency_unstated',
          ),
        ),
      );

      final tiles = find.byType(SimulatedFigureTile);
      expect(find.text('Simulated'), findsNWidgets(4));
      expect(find.text('Measured'), findsNothing);
      expect(
        find.descendant(
          of: tiles,
          matching: find.byIcon(SimulatedFigureTile.simulatedGlyph),
        ),
        findsNWidgets(4),
      );
      expect(find.byIcon(SimulatedFigureTile.measuredGlyph), findsNothing);
      expect(
        find.textContaining('is not a recognised measurement'),
        findsNWidgets(4),
        reason: 'the unknown token must be named, not swallowed',
      );
    });

    testWidgets('a recognised measured token is not dressed as simulated', (
      tester,
    ) async {
      // This endpoint never takes that branch today. The test exists so the
      // simulated default is provably a *decision*, not the only path the
      // widget knows how to draw.
      await pumpResult(
        tester,
        scenarioJson(conversion: figureJson(provenance: 'Measured')),
      );

      final tile = find.widgetWithText(SimulatedFigureTile, 'Conversion');
      expect(
        find.descendant(of: tile, matching: find.text('Measured')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text('Simulated')),
        findsNothing,
      );
      expect(find.text('Simulated'), findsNWidgets(3));
    });
  });

  group('greyscale', () {
    testWidgets('a simulated figure and a measured Store Pulse figure are '
        'told apart without colour', (tester) async {
      const measuredValueKey = Key('store-pulse-numeral');
      await pumpMall(
        tester,
        Column(
          children: [
            SimulatedFigureTile(
              label: 'Conversion',
              figure: SimulatedFigure.tryParse(figureJson())!,
            ),
            // The Store Pulse language, reproduced: a large numeral centred
            // over a tiny caption, no pill, no glyph, no frame.
            Column(
              children: [
                Text('12.5', key: measuredValueKey,
                    style: storePulseNumeralStyle),
                Text(
                  'Conversion',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
        inList: false,
      );

      final simulated = find.byType(SimulatedFigureTile);

      // Carrier 1 — the word, inside the simulated figure only.
      expect(
        find.descendant(of: simulated, matching: find.text('Simulated')),
        findsOneWidget,
      );
      // Carrier 2 — the glyph.
      expect(
        find.descendant(
          of: simulated,
          matching: find.byIcon(SimulatedFigureTile.simulatedGlyph),
        ),
        findsOneWidget,
      );
      // Carrier 3 — the broken frame. Nothing else on this dashboard is
      // drawn with a dashed border.
      expect(
        find.descendant(of: simulated, matching: find.byType(CustomPaint)),
        findsWidgets,
      );

      // And the two numerals are not the same type, so a reader seeing only
      // shapes still sees two different kinds of thing.
      final simulatedStyle = tester
          .widget<Text>(
            find.descendant(
              of: simulated,
              matching: find.byKey(SimulatedFigureTile.valueKey),
            ),
          )
          .style!;
      final measuredStyle = tester
          .widget<Text>(find.byKey(measuredValueKey))
          .style!;
      expect(simulatedStyle.fontSize, isNot(measuredStyle.fontSize));
      expect(simulatedStyle.fontWeight, isNot(measuredStyle.fontWeight));
    });

    test('the Store Pulse numeral this test mirrors is still the real one', () {
      const path =
          'lib/features/vendor/dashboard/presentation/screens/'
          'vendor_dashboard_screen.dart';
      final source = codeOf(path);

      expect(
        source.contains('DesignTokens.mediumSemibold.copyWith(fontSize: 21)'),
        isTrue,
        reason:
            'The greyscale test reproduces the measured Store Pulse numeral. '
            'If the dashboard changed it, update `storePulseNumeralStyle` so '
            'the comparison stays real.',
      );
      // And Store Pulse itself must not start wearing simulated markings.
      expect(source.contains('SimulatedFigureTile'), isFalse);
    });
  });

  group('layout', () {
    for (final scale in [1.0, 1.3]) {
      testWidgets('the result dialog fits 320dp at text x$scale', (
        tester,
      ) async {
        await pumpResult(tester, scenarioJson(), width: 320, textScale: scale);
        expectNoLayoutErrors(tester);
        expect(find.byType(SimulatedFigureTile), findsNWidgets(4));
      });

      testWidgets(
        'the longest copy this dialog can produce fits 320dp at text x$scale',
        (tester) async {
          const token = 'ProjectedFromBlendedBaseline';
          await pumpResult(
            tester,
            scenarioJson(
              conversion: figureJson(provenance: token),
              stockout: figureJson(provenance: token, simulatedValue: 8),
              onTime: figureJson(provenance: token, simulatedValue: 91.25),
              gmv: figureJson(
                provenance: token,
                simulatedValue: 48210.5,
                unit: 'currency_unstated',
              ),
            ),
            width: 320,
            textScale: scale,
          );
          expectNoLayoutErrors(tester);
        },
      );
    }

    testWidgets('the scenario sheet fits 320dp at text x1.3', (tester) async {
      tester.view
        ..physicalSize = const Size(320, 568)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, app) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: app ?? const SizedBox.shrink(),
            ),
            home: const Scaffold(body: DigitalTwinScenarioButton()),
          ),
        ),
      );
      await tester.tap(find.byKey(DigitalTwinScenarioButton.runKey));
      await tester.pumpAndSettle();
      expectNoLayoutErrors(tester);
    });
  });

  group('controls speak and respond', () {
    testWidgets('the scenario controls are labelled and operable', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: DigitalTwinScenarioButton())),
        ),
      );

      expectLabelledAndTappable(
        tester,
        find.byKey(DigitalTwinScenarioButton.runKey),
        'Test a future scenario',
      );

      await tester.tap(find.byKey(DigitalTwinScenarioButton.runKey));
      await tester.pumpAndSettle();

      expectLabelledAndTappable(
        tester,
        find.widgetWithText(FilledButton, 'Run calibrated scenario'),
        'Run calibrated scenario',
      );

      // Each slider says what it is and what it is set to, and can be driven
      // from assistive technology. Material's Slider puts no label on its own
      // node — the name has to ride in the announced value, which is what
      // `semanticFormatterCallback` is for. A slider that announces only
      // "25%" names no control.
      final sliders = semanticsUnder(tester, find.byType(MaterialApp))
          .where((n) => n.hasAction(SemanticsAction.increase))
          .toList();
      expect(sliders, hasLength(3));
      for (final label in ['Demand surge', 'Inventory loss', 'Capacity loss']) {
        expect(find.text(label), findsOneWidget, reason: 'no visible name');
        final node = sliders.singleWhere((n) => n.value.startsWith(label));
        expect(node.value, contains('percent'));
        expect(node.hasAction(SemanticsAction.decrease), isTrue);
      }
      handle.dispose();
    });

    testWidgets('the dialog dismiss control is labelled and tappable', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpResult(tester, scenarioJson());

      expectLabelledAndTappable(
        tester,
        find.byKey(DigitalTwinScenarioResultDialog.doneKey),
        'Done',
      );
      handle.dispose();
    });

    testWidgets('each figure speaks its provenance before its number', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpResult(tester, scenarioJson());

      final label = tester
          .getSemantics(find.widgetWithText(SimulatedFigureTile, 'Conversion'))
          .label;
      expect(label, startsWith('Conversion. Simulated figure.'));
      expect(label, contains('12.5 percent'));
      expect(label.indexOf('Simulated'), lessThan(label.indexOf('12.5')));
      handle.dispose();
    });
  });

  group('the removed calibration drift fields', () {
    // The contract dropped `calibrationConversionDriftPoints` and its two
    // siblings. A drift point folds a simulated figure and a recorded
    // baseline into one number with no provenance;
    // `CalibrationComparisonDto` states the two side by side instead.
    const removed = [
      'calibrationConversionDriftPoints',
      'calibrationStockoutDriftPoints',
      'calibrationOnTimeDriftPoints',
      'DriftPoints',
    ];

    test('are referenced nowhere in lib/', () {
      final offenders = <String>[];
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in files) {
        final path = file.path.replaceAll(r'\', '/');
        final lines = codeOf(file.path).split('\n');
        for (var i = 0; i < lines.length; i++) {
          for (final name in removed) {
            if (lines[i].contains(name)) offenders.add('$path:${i + 1} $name');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'A drift point is a simulated figure and a recorded baseline '
            'folded into one number with no provenance. The backend removed '
            'them; do not reconstruct one client-side. The calibration '
            'comparison contract states the two side by side instead.',
      );
    });

    test('the scenario dialog keeps no zero fallback', () {
      final source = codeOf(
        'lib/features/vendor/dashboard/presentation/widgets/'
        'digital_twin_scenario_button.dart',
      );

      // `result['conversionPercent'] ?? 0` is the original defect: absent
      // figure in, fabricated measurement out.
      expect(RegExp(r'\?\?\s*0\b').hasMatch(source), isFalse);
      expect(source.contains("result['conversionPercent']"), isFalse);
      expect(source.contains('NPR'), isFalse);
    });

    test('the figure entity has no fallback value anywhere', () {
      final source = codeOf(
        'lib/features/vendor/dashboard/domain/entities/simulated_figure.dart',
      );
      expect(RegExp(r'\?\?\s*0\b').hasMatch(source), isFalse);
    });
  });
}
