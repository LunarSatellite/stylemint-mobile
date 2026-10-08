import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/repositories/courier_repository.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_offers_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_offer_card.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';

import '../orders_test_harness.dart';

class _MockCourierRepository extends Mock implements CourierRepository {}

class _MockApiClient extends Mock implements ApiClient {}

HopOffer _offer({
  OfferMode mode = OfferMode.vendorSelect,
  OfferInterestState interest = OfferInterestState.none,
  Duration left = const Duration(minutes: 10),
  bool labels = true,
}) {
  final now = DateTime.now().toUtc();
  return HopOffer(
    id: 'offer-1',
    packageId: 'pkg-1',
    tier: DeliveryTier.neighbor,
    hopIndex: 0,
    roundNumber: 1,
    proposedPayoutAmount: 120,
    proposedPayoutCurrency: 'NPR',
    fromGeohash: 'tuutv',
    toGeohash: 'tuutw',
    state: HopOfferState.pending,
    offeredUtc: now.subtract(const Duration(minutes: 1)),
    expiresUtc: now.add(left),
    mode: mode,
    interestState: interest,
    pickup: labels
        ? const DeliveryPlace(
            latitude: 27.715,
            longitude: 85.31,
            label: 'Thamel',
          )
        : null,
    dropoff: labels
        ? const DeliveryPlace(
            latitude: 27.73,
            longitude: 85.33,
            label: 'Baluwatar',
          )
        : null,
    distanceToPickupKm: 1.4,
  );
}

void main() {
  group('CourierOfferCard', () {
    late List<String> calls;

    Future<void> pumpCard(
      WidgetTester tester,
      HopOffer offer, {
      OfferInterestState? override,
      double width = 390,
    }) async {
      setPhoneView(tester, width: width);
      calls = [];
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CourierOfferCard(
              offer: offer,
              now: DateTime.now().toUtc(),
              busy: false,
              interestState: override,
              onAccept: () => calls.add('accept'),
              onDecline: () => calls.add('decline'),
              onWithdraw: () => calls.add('withdraw'),
              onOpenMap: () => calls.add('map'),
            ),
          ),
        ),
      );
    }

    testWidgets('vendor-select, not yet answered: "I\'m interested"', (
      tester,
    ) async {
      await pumpCard(tester, _offer());

      expect(find.byKey(CourierOfferCard.interestedKey), findsOneWidget);
      expect(find.byKey(CourierOfferCard.acceptKey), findsNothing);
      expect(find.text('Pick up: Thamel'), findsOneWidget);
      expect(find.text('Drop off: Baluwatar'), findsOneWidget);
      expect(find.text('1.4 km to the pick-up'), findsOneWidget);

      await tester.tap(find.byKey(CourierOfferCard.interestedKey));
      expect(calls, ['accept']);
    });

    testWidgets('interested: waiting, with Withdraw', (tester) async {
      await pumpCard(tester, _offer(interest: OfferInterestState.interested));

      expect(find.text(CourierOfferCard.waitingText), findsOneWidget);
      expect(find.byKey(CourierOfferCard.interestedKey), findsNothing);

      await tester.tap(find.byKey(CourierOfferCard.withdrawKey));
      expect(calls, ['withdraw']);
    });

    testWidgets('the optimistic override wins until the re-read lands', (
      tester,
    ) async {
      await pumpCard(
        tester,
        _offer(),
        override: OfferInterestState.interested,
      );
      expect(find.text(CourierOfferCard.waitingText), findsOneWidget);
    });

    testWidgets('selected: "You\'ve got it!" and a way to the map', (
      tester,
    ) async {
      await pumpCard(tester, _offer(interest: OfferInterestState.selected));

      expect(find.text(CourierOfferCard.selectedText), findsOneWidget);
      await tester.tap(find.byKey(CourierOfferCard.openMapKey));
      expect(calls, ['map']);
    });

    testWidgets('not selected: says so, greyed', (tester) async {
      await pumpCard(tester, _offer(interest: OfferInterestState.notSelected));

      expect(find.text(CourierOfferCard.notSelectedText), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text(CourierOfferCard.notSelectedText),
          matching: find.byWidgetPredicate(
            (w) => w is Opacity && w.opacity == 0.5,
          ),
        ),
        findsOneWidget,
      );
      expect(find.byKey(CourierOfferCard.withdrawKey), findsNothing);
    });

    testWidgets('expired by the server, or by the clock while waiting', (
      tester,
    ) async {
      await pumpCard(tester, _offer(interest: OfferInterestState.expired));
      expect(find.text(CourierOfferCard.expiredText), findsOneWidget);

      await pumpCard(
        tester,
        _offer(
          interest: OfferInterestState.interested,
          left: const Duration(seconds: -5),
        ),
      );
      expect(find.text(CourierOfferCard.expiredText), findsOneWidget);
      expect(find.byKey(CourierOfferCard.withdrawKey), findsNothing);
    });

    testWidgets('auction offers keep Pass / Accept', (tester) async {
      await pumpCard(tester, _offer(mode: OfferMode.auction));

      expect(find.byKey(CourierOfferCard.acceptKey), findsOneWidget);
      expect(find.byKey(CourierOfferCard.interestedKey), findsNothing);
      await tester.tap(find.byKey(CourierOfferCard.acceptKey));
      await tester.tap(find.byKey(CourierOfferCard.passKey));
      expect(calls, ['accept', 'decline']);
    });

    testWidgets('no labels falls back to the geohash cells', (tester) async {
      await pumpCard(tester, _offer(labels: false));
      expect(find.text('tuutv → tuutw · Neighbour'), findsOneWidget);
    });

    testWidgets('no overflow at 320dp in any state', (tester) async {
      for (final interest in OfferInterestState.values) {
        await pumpCard(tester, _offer(interest: interest), width: 320);
        expectNoLayoutErrors(tester);
      }
    });
  });

  group('OfferMode / OfferInterestState parsing', () {
    test('mode: VendorSelect, anything else is an auction', () {
      expect(OfferMode.fromWire('VendorSelect'), OfferMode.vendorSelect);
      expect(OfferMode.fromWire('vendor_select'), OfferMode.vendorSelect);
      expect(OfferMode.fromWire('Auction'), OfferMode.auction);
      expect(OfferMode.fromWire(null), OfferMode.auction);
      expect(OfferMode.fromWire('Lottery'), OfferMode.auction);
    });

    test('interest state: contract strings, unknown is none', () {
      expect(
        OfferInterestState.fromWire('Interested'),
        OfferInterestState.interested,
      );
      expect(
        OfferInterestState.fromWire('NotSelected'),
        OfferInterestState.notSelected,
      );
      expect(
        OfferInterestState.fromWire('Selected'),
        OfferInterestState.selected,
      );
      expect(OfferInterestState.fromWire('Expired'), OfferInterestState.expired);
      expect(OfferInterestState.fromWire(null), OfferInterestState.none);
      expect(OfferInterestState.fromWire('Pondering'), OfferInterestState.none);
    });
  });

  group('CourierOffersScreen', () {
    late _MockCourierRepository repo;
    late DeliveryPushBus bus;
    late List<HopOffer> answer;
    late int listCalls;

    setUp(() {
      repo = _MockCourierRepository();
      bus = DeliveryPushBus();
      listCalls = 0;
      answer = [_offer(interest: OfferInterestState.interested)];
      when(() => repo.listOffers()).thenAnswer((_) async {
        listCalls++;
        return right<NetworkExceptions, List<HopOffer>>(answer);
      });
      when(
        () => repo.withdrawInterest(any()),
      ).thenAnswer((_) async => right<NetworkExceptions, Unit>(unit));
    });

    tearDown(() => bus.dispose());

    Future<void> pumpScreen(WidgetTester tester, {bool pushed = false}) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courierRepositoryProvider.overrideWithValue(repo),
            courierRemoteDataSourceProvider.overrideWithValue(
              CourierRemoteDataSource(apiClient: _MockApiClient()),
            ),
            courierAccountIdProvider.overrideWithValue(''),
            deliveryPushBusProvider.overrideWithValue(bus),
          ],
          child: ordersTestApp(
            pushed
                ? Builder(
                    builder: (context) => Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CourierOffersScreen(),
                          ),
                        ),
                        child: const Text('dashboard'),
                      ),
                    ),
                  )
                : const CourierOffersScreen(),
            wrapInScaffold: pushed,
          ),
        ),
      );
      if (pushed) {
        await tester.tap(find.text('dashboard'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pump();
      await tester.pump();
    }

    testWidgets('withdraw calls the server and the card goes back', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.text(CourierOfferCard.waitingText), findsOneWidget);

      answer = [_offer()];
      await tester.tap(find.byKey(CourierOfferCard.withdrawKey));
      await tester.pump();
      await tester.pump();

      verify(() => repo.withdrawInterest('offer-1')).called(1);
      expect(find.byKey(CourierOfferCard.interestedKey), findsOneWidget);
      expect(find.text(CourierOfferCard.waitingText), findsNothing);
    });

    testWidgets('polls every 10 s, and not while in the background', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(listCalls, 1);

      await tester.pump(const Duration(seconds: 10));
      await tester.pump();
      expect(listCalls, 2);

      final binding = tester.binding;
      binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(listCalls, 2, reason: 'paused in the background');

      binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden)
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(listCalls, 3, reason: 're-read on return');
    });

    testWidgets('a delivery push refreshes at once', (tester) async {
      await pumpScreen(tester);
      expect(listCalls, 1);

      bus.publish(
        const DeliveryPushEvent(
          type: DeliveryPushType.notSelected,
          offerId: 'offer-1',
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(listCalls, 2);
    });

    testWidgets('being chosen while waiting goes to the map', (tester) async {
      await pumpScreen(tester, pushed: true);
      expect(find.text(CourierOfferCard.waitingText), findsOneWidget);

      answer = [_offer(interest: OfferInterestState.selected)];
      bus.publish(
        const DeliveryPushEvent(
          type: DeliveryPushType.selected,
          hopId: 'hop-1',
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CourierOffersScreen), findsNothing);
      expect(find.text('dashboard'), findsOneWidget);
    });

    testWidgets('a "not chosen" card fades out', (tester) async {
      answer = [_offer(interest: OfferInterestState.notSelected)];
      await pumpScreen(tester);
      expect(find.text(CourierOfferCard.notSelectedText), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text(CourierOfferCard.notSelectedText), findsNothing);
    });
  });
}
