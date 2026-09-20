import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/datasources/checkout_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/delivery_distance_note.dart';

import '../../codes/support/recording_api_client.dart';
import 'checkout_harness.dart';

/// Capability 32 on the client: `delivery-options` has returned a `distance`
/// on every choice for as long as the field has existed, and no client ever
/// read it. These tests pin the two halves of the contract that make the
/// figure safe to show — the state is read before the number, and the method
/// never travels separately from it.

// ── Server strings, copied verbatim ────────────────────────────────────────
//
// These are `DeliveryDistanceRules.MeasuredMethod`, `WithheldMethod`,
// `NoDeliveryJourneyMethod` and `NoDeliveryJourneyReason` as the server emits
// them. They are reproduced here rather than paraphrased because the whole
// point of the feature is that a shopper reads the server's sentence, not a
// client's summary of it.

const String measuredMethod =
    "Straight-line (great-circle) distance from each seller's recorded store "
    'address to your delivery address, added up across every delivery in this '
    'option and rounded to 0.1 km. It is a straight line, not a road route: a '
    'vehicle travels further than this.';

const String withheldMethod =
    "We measure straight-line distance from a seller's recorded store address "
    'to your delivery address, and we only show it when we hold both. We show '
    'nothing rather than guess, so an option with no distance is an option we '
    'could not measure — not a short one.';

const String singleOriginUnknownReason =
    "We can't show a distance for this option: this seller hasn't recorded a "
    "store location with coordinates, so we don't know where the parcel "
    'starts. That is unknown, not zero.';

const String noDeliveryJourneyMethod =
    'A count of delivery journeys this platform records, not a measurement. '
    'Zero journeys here means the parcel is not driven to you; it does not '
    'mean zero distance for you.';

const String noDeliveryJourneyReason =
    'Collecting means no delivery journey at all — nothing is driven to you. '
    "That is a count we record, not a distance we measured. We don't show how "
    "far you would travel to collect, because we don't know where you would "
    'set out from.';

// ── Fixtures ───────────────────────────────────────────────────────────────

const DeliveryDistanceSummary measuredTwoJourneys = DeliveryDistanceSummary(
  state: DeliveryDistanceState.measured,
  journeys: 2,
  journeysMeasured: 2,
  straightLineKm: 12.4,
  method: measuredMethod,
);

const DeliveryDistanceSummary originUnknown = DeliveryDistanceSummary(
  state: DeliveryDistanceState.originUnknown,
  journeys: 1,
  journeysMeasured: 0,
  method: withheldMethod,
  withheldReason: singleOriginUnknownReason,
);

const DeliveryDistanceSummary collection = DeliveryDistanceSummary(
  state: DeliveryDistanceState.noDeliveryJourney,
  journeys: 0,
  journeysMeasured: 0,
  method: noDeliveryJourneyMethod,
  withheldReason: noDeliveryJourneyReason,
);

DeliveryChoices _choicesWith(
  DeliveryDistanceSummary distance, {
  DeliveryEmissionsEstimate? emissions,
}) => DeliveryChoices(
  choices: [
    DeliveryChoice(
      kind: DeliveryChoiceKind.homeDelivery,
      title: 'Home delivery in one consolidated package',
      detail: 'Everything arrives together, two days after dispatch.',
      deliveries: 1,
      readyInDays: 2,
      selected: true,
      distance: distance,
      emissions: emissions,
    ),
  ],
  emissionsNote: longEmissionsNote,
  pickupNote: longPickupNote,
);

/// Every string rendered inside the distance block, and nothing outside it.
List<String> _noteText(WidgetTester tester) => tester
    .widgetList<Text>(
      find.descendant(
        of: find.byType(DeliveryDistanceNote),
        matching: find.byType(Text),
      ),
    )
    .map((text) => text.data ?? '')
    .toList(growable: false);

void main() {
  group('a measured distance', () {
    testCheckoutLayouts('renders the figure with its method', (
      tester,
      width,
      textScale,
    ) async {
      final repository = MockCheckoutRepository();
      stubCheckout(repository, delivery: _choicesWith(measuredTwoJourneys));
      await pumpCheckout(
        tester,
        repository,
        width: width,
        textScale: textScale,
      );

      expect(find.text('12.4 km in a straight line'), findsOneWidget);
      // The method is not optional decoration. A great-circle number shown
      // without the sentence that says a vehicle travels further is a
      // travelled distance nobody measured.
      expect(find.text(measuredMethod), findsOneWidget);
      expect(find.text('2 delivery journeys, added together.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('a withheld distance', () {
    testCheckoutLayouts('renders its reason and no numeral at all', (
      tester,
      width,
      textScale,
    ) async {
      final repository = MockCheckoutRepository();
      stubCheckout(repository, delivery: _choicesWith(originUnknown));
      await pumpCheckout(
        tester,
        repository,
        width: width,
        textScale: textScale,
      );

      expect(find.text('Distance not shown'), findsOneWidget);
      expect(find.text(singleOriginUnknownReason), findsOneWidget);
      expect(find.text(withheldMethod), findsOneWidget);

      // Not "0 km", not "— km", not a journey count standing in for a
      // distance. Unknown must not appear anywhere near a number line.
      for (final line in _noteText(tester)) {
        expect(
          RegExp(r'\d').hasMatch(line),
          isFalse,
          reason: 'A withheld distance rendered a digit: "$line"',
        );
      }
      expect(find.textContaining('km'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('collection', () {
    testCheckoutLayouts('renders zero journeys, never zero distance', (
      tester,
      width,
      textScale,
    ) async {
      final repository = MockCheckoutRepository();
      stubCheckout(repository, delivery: _choicesWith(collection));
      await pumpCheckout(
        tester,
        repository,
        width: width,
        textScale: textScale,
      );

      // The count, in words, so a zero journey count can never be misread as
      // a measured zero distance.
      expect(find.text('No delivery journey'), findsOneWidget);
      expect(find.text(noDeliveryJourneyReason), findsOneWidget);
      expect(find.text(noDeliveryJourneyMethod), findsOneWidget);
      for (final line in _noteText(tester)) {
        expect(
          RegExp(r'\d').hasMatch(line),
          isFalse,
          reason: 'Collection rendered a digit: "$line"',
        );
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('emissions', () {
    testCheckoutLayouts('render nothing when the platform holds no factor', (
      tester,
      width,
      textScale,
    ) async {
      final repository = MockCheckoutRepository();
      stubCheckout(repository, delivery: _choicesWith(measuredTwoJourneys));
      await pumpCheckout(
        tester,
        repository,
        width: width,
        textScale: textScale,
      );

      // No reviewed factor is configured anywhere, so no mass exists to show.
      // Absent renders as absent: no "0 kg", no "—", no placeholder row.
      expect(find.textContaining('CO₂e'), findsNothing);
      expect(find.textContaining('kg '), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testCheckoutLayouts('render nothing when the citation is incomplete', (
      tester,
      width,
      textScale,
    ) async {
      final repository = MockCheckoutRepository();
      stubCheckout(
        repository,
        delivery: _choicesWith(
          measuredTwoJourneys,
          // A mass with no factor version, no source and no method is an
          // unsourced number. It is not shown bare; it is not shown at all.
          emissions: const DeliveryEmissionsEstimate(
            kgCo2e: 0.842,
            factorVersion: '',
            factorSourceUri: '',
            method: '',
          ),
        ),
      );
      await pumpCheckout(
        tester,
        repository,
        width: width,
        textScale: textScale,
      );

      expect(find.textContaining('CO₂e'), findsNothing);
      expect(find.textContaining('0.842'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('the wire', () {
    CheckoutRemoteDataSource dataSourceOver(RecordingApiClient client) =>
        CheckoutRemoteDataSource(apiClient: client);

    Future<DeliveryChoice> firstChoiceFrom(
      Map<String, dynamic> distanceJson,
    ) async {
      final client = RecordingApiClient(
        (call) => call.uri.contains('delivery-options')
            ? {
                'choices': [
                  {
                    'kind': 'HomeDelivery',
                    'title': 'Home delivery',
                    'detail': '',
                    'deliveries': 1,
                    'readyInDays': 2,
                    'selected': true,
                    'distance': distanceJson,
                  },
                ],
                'emissionsNote': '',
              }
            : {'id': 'sess-1'},
      );
      final choices = await dataSourceOver(client).getDeliveryChoices();
      return choices.choices.single;
    }

    test('reads the state as a word', () async {
      final choice = await firstChoiceFrom({
        'state': 'Measured',
        'journeys': 2,
        'journeysMeasured': 2,
        'straightLineKm': 12.4,
        'method': measuredMethod,
        'withheldReason': null,
      });

      expect(choice.distance?.state, DeliveryDistanceState.measured);
      expect(choice.distance?.straightLineKm, 12.4);
      expect(choice.distance?.hasFigure, isTrue);
    });

    test('drops a figure that arrives beside a withheld state', () async {
      // A distance escaping its state is the one defect this shape exists to
      // prevent, so the client re-imposes the invariant rather than trusting
      // it. A partial sum shown as a whole reads shorter than the truth.
      final choice = await firstChoiceFrom({
        'state': 'OriginUnknown',
        'journeys': 3,
        'journeysMeasured': 2,
        'straightLineKm': 8.1,
        'method': withheldMethod,
        'withheldReason': singleOriginUnknownReason,
      });

      expect(choice.distance?.state, DeliveryDistanceState.originUnknown);
      expect(choice.distance?.straightLineKm, isNull);
      expect(choice.distance?.hasFigure, isFalse);
      expect(choice.distance?.withheldReason, singleOriginUnknownReason);
    });

    test('keeps collection as zero journeys with no distance', () async {
      final choice = await firstChoiceFrom({
        'state': 'NoDeliveryJourney',
        'journeys': 0,
        'journeysMeasured': 0,
        'straightLineKm': null,
        'method': noDeliveryJourneyMethod,
        'withheldReason': noDeliveryJourneyReason,
      });

      expect(
        choice.distance?.state,
        DeliveryDistanceState.noDeliveryJourney,
      );
      expect(choice.distance?.journeys, 0);
      expect(choice.distance?.straightLineKm, isNull);
    });

    test('drops a summary whose state this build cannot read', () async {
      // An unrecognised word is not evidence that something was measured.
      final choice = await firstChoiceFrom({
        'state': 'RoadRouted',
        'journeys': 1,
        'journeysMeasured': 1,
        'straightLineKm': 4.2,
        'method': measuredMethod,
      });

      expect(choice.distance, isNull);
    });

    test('drops a summary that arrives without its method', () async {
      final choice = await firstChoiceFrom({
        'state': 'Measured',
        'journeys': 1,
        'journeysMeasured': 1,
        'straightLineKm': 4.2,
        'method': '   ',
      });

      expect(choice.distance, isNull);
    });

    test('carries no distance when the server sends none', () async {
      final client = RecordingApiClient(
        (call) => call.uri.contains('delivery-options')
            ? {
                'choices': [
                  {
                    'kind': 'HomeDelivery',
                    'title': 'Home delivery',
                    'detail': '',
                    'deliveries': 1,
                    'readyInDays': 2,
                    'selected': true,
                  },
                ],
                'emissionsNote': '',
              }
            : {'id': 'sess-1'},
      );
      final choices = await dataSourceOver(client).getDeliveryChoices();

      // Null is what every response carried before the field existed, and it
      // means the same thing a withheld figure does: unknown, never zero.
      expect(choices.choices.single.distance, isNull);
    });
  });
}
