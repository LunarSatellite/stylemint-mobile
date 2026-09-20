import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/simulated_figure.dart';

import 'simulated_figure_fixtures.dart';

void main() {
  group('SimulatedFigure.tryParse', () {
    test('reads the object form the engine now sends', () {
      final figure = SimulatedFigure.tryParse(figureJson())!;

      expect(figure.value, 12.5);
      expect(figure.provenance, 'Simulated');
      expect(figure.unit, 'percent');
      expect(figure.measureKey, 'synthetic.conversion_percent');
      expect(figure.derivedFrom, 'demand_shock,inventory_loss');
      expect(figure.isSimulated, isTrue);
      expect(figure.hasUnrecognisedProvenance, isFalse);
    });

    test('refuses a bare number — it carries no provenance to label it', () {
      // This is the OLD wire shape. Accepting it would be the whole bug back:
      // a number with nothing attached is indistinguishable from a
      // measurement, so there is nothing honest to draw.
      expect(SimulatedFigure.tryParse(12.5), isNull);
      expect(SimulatedFigure.tryParse(0), isNull);
      expect(SimulatedFigure.tryParse('12.5'), isNull);
    });

    test('a missing or unreadable value yields null, never zero', () {
      for (final raw in <Object?>[
        null,
        <String, dynamic>{},
        figureJson(simulatedValue: null),
        figureJson(simulatedValue: 'not a number'),
        figureJson(simulatedValue: <String, dynamic>{}),
        figureJson(simulatedValue: double.nan),
        figureJson(simulatedValue: double.infinity),
        <String, dynamic>{'provenance': 'Simulated', 'unit': 'percent'},
      ]) {
        expect(
          SimulatedFigure.tryParse(raw),
          isNull,
          reason:
              'A figure that did not arrive must render nothing. Returning a '
              'zero-valued figure here is how "Conversion 0%" gets on screen.',
        );
      }
    });

    test('a numeric string value is read', () {
      // System.Text.Json can be configured to write decimals as strings.
      expect(
        SimulatedFigure.tryParse(figureJson(simulatedValue: '48.25'))!.value,
        48.25,
      );
    });
  });

  group('provenance', () {
    test('the engine token reads as simulated', () {
      final figure = SimulatedFigure.tryParse(figureJson())!;
      expect(figure.isSimulated, isTrue);
      expect(figure.provenanceWord, 'Simulated');
    });

    test('an unknown future token is read as simulated, not measured', () {
      for (final token in [
        'Projected',
        'Blended',
        'Estimated',
        'SIMULATED_V2',
        'measured-ish',
        '',
        null,
      ]) {
        final figure = SimulatedFigure.tryParse(
          figureJson(provenance: token),
        )!;
        expect(
          figure.isSimulated,
          isTrue,
          reason:
              'Provenance "$token" is not on the measured allowlist, so the '
              'cautious reading applies. A denylist would let a token the '
              'backend invents next year be drawn as a measurement.',
        );
        expect(figure.provenanceWord, 'Simulated');
        expect(figure.hasUnrecognisedProvenance, isTrue);
        expect(figure.provenanceSentence, contains('not a recognised'));
      }
    });

    test('only the named measured tokens read as measured', () {
      for (final token in SimulatedFigure.kMeasuredProvenances) {
        final figure = SimulatedFigure.tryParse(
          figureJson(provenance: token.toUpperCase()),
        )!;
        expect(figure.isSimulated, isFalse);
        expect(figure.provenanceWord, 'Measured');
        expect(figure.hasUnrecognisedProvenance, isFalse);
      }
    });
  });

  group('units', () {
    test('a percent figure carries its percent sign', () {
      final figure = SimulatedFigure.tryParse(figureJson())!;
      expect(figure.displayValue, '12.5%');
      expect(figure.spokenValue, '12.5 percent');
    });

    test('currency_unstated carries no currency symbol at all', () {
      final figure = SimulatedFigure.tryParse(
        figureJson(
          simulatedValue: 48210.5,
          unit: 'currency_unstated',
          measureKey: 'synthetic.gross_merchandise_value',
        ),
      )!;

      expect(figure.currencyIsUnstated, isTrue);
      expect(figure.displayValue, '48,210.5');
      for (final symbol in ['NPR', 'Rs', '₨', r'$', '€', '£', '₹']) {
        expect(
          figure.displayValue.contains(symbol),
          isFalse,
          reason:
              'The engine invents prices and declares no currency. Naming one '
              'here is the client fabricating the unit.',
        );
      }
      expect(figure.unitSentence, contains('currency not stated'));
    });

    test('counts read plainly, with no trailing zeros', () {
      final figure = SimulatedFigure.tryParse(
        figureJson(simulatedValue: 1204, unit: 'count'),
      )!;
      expect(figure.displayValue, '1,204');
    });

    test('an unknown unit is named rather than assumed', () {
      final figure = SimulatedFigure.tryParse(
        figureJson(simulatedValue: 7, unit: 'journeys_per_agent_day'),
      )!;
      expect(figure.displayValue, '7');
      expect(figure.unitSentence, contains('journeys_per_agent_day'));
    });

    test('a missing unit says so instead of guessing', () {
      final figure = SimulatedFigure.tryParse(
        figureJson(simulatedValue: 7, unit: null),
      )!;
      expect(figure.unitSentence, 'Unit: not stated.');
    });
  });

  test('the spoken sentence names the provenance before the number', () {
    final figure = SimulatedFigure.tryParse(figureJson())!;
    final sentence = figure.semanticsSentence('Conversion');

    expect(
      sentence.indexOf('Simulated'),
      lessThan(sentence.indexOf('12.5')),
      reason:
          'A screen reader must hear what kind of number this is before it '
          'hears the number.',
    );
    expect(sentence, contains('synthetic.conversion_percent'));
  });
}
