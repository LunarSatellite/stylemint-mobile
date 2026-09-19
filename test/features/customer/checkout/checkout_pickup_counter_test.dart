import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'checkout_harness.dart';

/// Checkout could already switch an order to collection, but only ever "from
/// this seller" — it never said *which counter*, so every collection order
/// placed from the app recorded `FulfillmentLocationId == null` and the counter
/// name was legitimately absent everywhere downstream.
///
/// These tests pin the picker that closes that, and — just as importantly —
/// pin the two paths it must not disturb: a seller with no registered counter,
/// and home delivery.
void main() {
  late MockCheckoutRepository repository;

  setUp(() => repository = MockCheckoutRepository());

  // ── The gap this closes ───────────────────────────────────────────────────

  group('choosing a counter', () {
    testWidgets('sends the chosen counter and its seller to the checkout API', (
      tester,
    ) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: countersAvailableChoices,
      );
      await pumpCheckout(tester, repository);

      await tester.tap(find.text(fullCounter.name!));
      await tester.pumpAndSettle();

      // The counter id is what the order records; the seller id is what the
      // endpoint has always required alongside it.
      verify(
        () => repository.selectPickupLocation(
          sellerId: 'seller-1',
          locationId: 'loc-1',
        ),
      ).called(1);
    });

    testWidgets('marks only the tapped counter as chosen', (tester) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: countersAvailableChoices,
      );
      await pumpCheckout(tester, repository);

      // Nothing is chosen before the tap.
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      await tester.tap(find.text(counterWithoutHours.name!));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });

    testWidgets('does not record a counter when the call fails', (
      tester,
    ) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: countersAvailableChoices,
      );
      when(
        () => repository.selectPickupLocation(
          sellerId: any(named: 'sellerId'),
          locationId: any(named: 'locationId'),
        ),
      ).thenAnswer((_) async => left(checkoutFailure));
      await pumpCheckout(tester, repository);

      await tester.tap(find.text(fullCounter.name!));
      await tester.pumpAndSettle();

      // Showing a counter as chosen when the server never recorded it would put
      // a counter name on an order that has none.
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });
  });

  // ── A single counter is not chosen for the shopper ────────────────────────

  group('a seller with exactly one counter', () {
    testWidgets('does not preselect it', (tester) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: const DeliveryChoices(
          choices: pickupSelectedChoiceList,
          emissionsNote: longEmissionsNote,
          pickupLocations: [fullCounter],
        ),
      );
      await pumpCheckout(tester, repository);

      // The order records this as the counter the shopper chose. Filling it in
      // because there is only one would write a choice nobody made.
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      verifyNever(
        () => repository.selectPickupLocation(
          sellerId: any(named: 'sellerId'),
          locationId: any(named: 'locationId'),
        ),
      );
    });

    testWidgets('still records it on one tap', (tester) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: const DeliveryChoices(
          choices: pickupSelectedChoiceList,
          emissionsNote: longEmissionsNote,
          pickupLocations: [fullCounter],
        ),
      );
      await pumpCheckout(tester, repository);

      await tester.tap(find.text(fullCounter.name!));
      await tester.pumpAndSettle();

      verify(
        () => repository.selectPickupLocation(
          sellerId: 'seller-1',
          locationId: 'loc-1',
        ),
      ).called(1);
    });
  });

  // ── The path that must not change ─────────────────────────────────────────

  group('a seller with no registered counter', () {
    testWidgets('sells for collection exactly as before', (tester) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: noCounterChoices,
      );
      await pumpCheckout(tester, repository);

      // No picker, no empty section, no prompt — the screen is what it was.
      expect(find.text('Where you’ll collect'), findsNothing);
      expect(
        find.text('Pick a counter, or place the order without one.'),
        findsNothing,
      );

      // Collection is still the selected choice and the order can still be
      // placed; nothing gates on having a counter.
      expect(find.text('Pick up from $longVendorName'), findsOneWidget);
      verifyNever(
        () => repository.selectPickupLocation(
          sellerId: any(named: 'sellerId'),
          locationId: any(named: 'locationId'),
        ),
      );
    });

    testWidgets('never invents a counter to stand in for the missing one', (
      tester,
    ) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: noCounterChoices,
      );
      await pumpCheckout(tester, repository);

      expect(find.text('Store'), findsNothing);
      expect(find.text('Main counter'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });
  });

  group('home delivery', () {
    testWidgets('is untouched by the picker', (tester) async {
      // The default fixture has home delivery selected and carries counters,
      // so if the picker leaked outside collection it would show up here.
      stubCheckout(
        repository,
        delivery: const DeliveryChoices(
          choices: longDeliveryChoiceList,
          emissionsNote: longEmissionsNote,
          pickupLocations: [fullCounter, counterWithoutHours],
          pickupLocationsNote: pickupLocationsNote,
        ),
      );
      await pumpCheckout(tester, repository);

      expect(find.text('Where you’ll collect'), findsNothing);
      expect(find.text(fullCounter.name!), findsNothing);

      // The delivery screen still shows the shipping address card it always
      // showed.
      expect(find.text(typedAddressLabel), findsOneWidget);
    });
  });

  // ── Absent renders as absent ──────────────────────────────────────────────

  group('what the registry did not record', () {
    testWidgets('an unnamed counter is not given a name', (tester) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: const DeliveryChoices(
          choices: pickupSelectedChoiceList,
          emissionsNote: longEmissionsNote,
          pickupLocations: [unnamedCounter],
        ),
      );
      await pumpCheckout(tester, repository);

      // Not "Store", not the seller's name, not "Counter 1".
      expect(find.text('Store'), findsNothing);
      expect(find.text(longVendorName), findsNothing);
      expect(find.text('Counter 1'), findsNothing);

      // The address it does have leads instead, and it is still choosable.
      expect(find.text(unnamedCounter.addressLine!), findsOneWidget);
      await tester.tap(find.text(unnamedCounter.addressLine!));
      await tester.pumpAndSettle();
      verify(
        () => repository.selectPickupLocation(
          sellerId: 'seller-1',
          locationId: 'loc-3',
        ),
      ).called(1);
    });

    testWidgets('a counter with nothing recorded says so', (tester) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: const DeliveryChoices(
          choices: pickupSelectedChoiceList,
          emissionsNote: longEmissionsNote,
          pickupLocations: [bareCounter],
        ),
      );
      await pumpCheckout(tester, repository);

      expect(
        find.text('This counter’s details aren’t recorded'),
        findsOneWidget,
      );
    });

    testWidgets('unrecorded opening hours are no line at all', (tester) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: const DeliveryChoices(
          choices: pickupSelectedChoiceList,
          emissionsNote: longEmissionsNote,
          pickupLocations: [counterWithoutHours],
        ),
      );
      await pumpCheckout(tester, repository);

      expect(find.textContaining('Hours as listed'), findsNothing);
      expect(find.textContaining('Hours'), findsNothing);
    });

    testWidgets('recorded hours are repeated, never interpreted', (
      tester,
    ) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: countersAvailableChoices,
      );
      await pumpCheckout(tester, repository);

      expect(
        find.text('Hours as listed by the seller: ${fullCounter.openingHours}'),
        findsOneWidget,
      );

      // No clock is consulted, so no claim about now is made.
      expect(find.textContaining('Open now'), findsNothing);
      expect(find.textContaining('Closed now'), findsNothing);
      expect(find.textContaining('Closes in'), findsNothing);
    });

    testWidgets('no distance or stock figure is shown', (tester) async {
      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: countersAvailableChoices,
      );
      await pumpCheckout(tester, repository);

      // Distance would need the shopper's coordinates and stock is not
      // recorded per location; neither may be estimated into existence.
      expect(find.textContaining('km'), findsNothing);
      expect(find.textContaining('away'), findsNothing);
      expect(find.textContaining('in stock'), findsNothing);
      expect(find.textContaining('Unknown'), findsNothing);
    });
  });

  // ── Personal data ─────────────────────────────────────────────────────────

  group('device location', () {
    testWidgets('is never requested by the counter picker', (tester) async {
      // Nothing the picker shows depends on where the shopper is, so nothing
      // may ask. Any geolocator traffic at all fails this.
      final calls = <String>[];
      const channels = [
        MethodChannel('flutter.baseflow.com/geolocator'),
        MethodChannel('flutter.baseflow.com/geolocator_android'),
        MethodChannel('flutter.baseflow.com/geolocator_apple'),
      ];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final channel in channels) {
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add('${channel.name}.${call.method}');
          return null;
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      }

      stubCheckout(
        repository,
        summary: pickupCheckoutSummary,
        delivery: countersAvailableChoices,
      );
      await pumpCheckout(tester, repository);

      await tester.tap(find.text(fullCounter.name!));
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });
  });

  // ── Layout ────────────────────────────────────────────────────────────────

  testCheckoutLayouts('counter picker lays out', (
    tester,
    width,
    textScale,
  ) async {
    stubCheckout(
      repository,
      summary: pickupCheckoutSummary,
      delivery: const DeliveryChoices(
        choices: pickupSelectedChoiceList,
        emissionsNote: longEmissionsNote,
        pickupLocations: [
          fullCounter,
          counterWithoutHours,
          unnamedCounter,
          bareCounter,
        ],
        pickupLocationsNote: pickupLocationsNote,
      ),
    );
    await pumpCheckout(
      tester,
      repository,
      width: width,
      textScale: textScale,
    );

    expect(find.text('Where you’ll collect'), findsOneWidget);
    expectNoLayoutErrors(tester);
  });
}
