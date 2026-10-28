import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_job_mapper.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_job.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/repositories/courier_repository.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_offer_card.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_return_collect_sheet.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';

import '../orders_test_harness.dart';

class _MockCourierRepository extends Mock implements CourierRepository {}

HopOffer _offer({
  OfferKind kind = OfferKind.returnPickup,
  OfferInterestState interest = OfferInterestState.none,
}) {
  final now = DateTime.now().toUtc();
  return HopOffer(
    id: 'offer-1',
    packageId: 'pkg-1',
    tier: DeliveryTier.neighbor,
    hopIndex: 0,
    roundNumber: 1,
    proposedPayoutAmount: 150,
    proposedPayoutCurrency: 'NPR',
    fromGeohash: 'tuutv',
    toGeohash: 'tuutw',
    state: HopOfferState.pending,
    offeredUtc: now.subtract(const Duration(minutes: 1)),
    expiresUtc: now.add(const Duration(minutes: 10)),
    mode: OfferMode.vendorSelect,
    interestState: interest,
    kind: kind,
    pickup: const DeliveryPlace(
      latitude: 27.715,
      longitude: 85.31,
      label: 'Baluwatar',
    ),
    dropoff: const DeliveryPlace(
      latitude: 27.73,
      longitude: 85.33,
      label: 'Thamel shop',
    ),
    distanceToPickupKm: 1.4,
  );
}

void main() {
  group('return offers', () {
    Future<void> pumpCard(WidgetTester tester, HopOffer offer) async {
      setPhoneView(tester);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CourierOfferCard(
              offer: offer,
              now: DateTime.now().toUtc(),
              busy: false,
              onAccept: () {},
              onDecline: () {},
              onWithdraw: () {},
              onOpenMap: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('labelled "Return pickup", with an approximate area', (
      tester,
    ) async {
      await pumpCard(tester, _offer());

      expect(find.text(CourierOfferCard.returnBadgeText), findsOneWidget);
      expect(find.text('Collect near: Baluwatar'), findsOneWidget);
      expect(find.text('Bring to: Thamel shop'), findsOneWidget);
      expect(find.text(CourierOfferCard.approximateText), findsOneWidget);
      expect(find.text('1.4 km to the buyer'), findsOneWidget);
      expect(find.byKey(CourierOfferCard.interestedKey), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('once chosen, the address is no longer approximate', (
      tester,
    ) async {
      await pumpCard(tester, _offer(interest: OfferInterestState.selected));

      expect(find.text('Collect from: Baluwatar'), findsOneWidget);
      expect(find.text(CourierOfferCard.approximateText), findsNothing);
    });

    testWidgets('a delivery offer has no return badge', (tester) async {
      await pumpCard(tester, _offer(kind: OfferKind.delivery));

      expect(find.text(CourierOfferCard.returnBadgeText), findsNothing);
      expect(find.text('Pick up: Baluwatar'), findsOneWidget);
    });

    test('kind reads Return and defaults to a delivery', () {
      expect(OfferKind.fromWire('Return'), OfferKind.returnPickup);
      expect(OfferKind.fromWire(null), OfferKind.delivery);
      expect(OfferKind.fromWire('Teleport'), OfferKind.delivery);
    });
  });

  group('return jobs', () {
    test('a Return job is collected, never "Picked up"', () {
      final job = CourierJobMapper.job({
        'hopId': 'hop-1',
        'packageNumber': 'SM-R-00000042',
        'status': 'Assigned',
        'kind': 'Return',
        'returnRequestId': 'ret-1',
        'cashToCollect': null,
      });
      expect(job.isReturn, isTrue);
      expect(job.returnRequestId, 'ret-1');
      expect(job.awaitingReturnCollection, isTrue);
      expect(job.cashToCollect, isNull);

      final atBuyer = CourierJobMapper.job({
        'hopId': 'hop-1',
        'status': 'AwaitingConfirmation',
        'kind': 'Return',
      });
      expect(atBuyer.awaitingReturnCollection, isTrue);

      final toSeller = CourierJobMapper.job({
        'hopId': 'hop-1',
        'status': 'PickedUp',
        'kind': 'Return',
        'pickedUpUtc': '2026-10-28T09:00:00Z',
      });
      expect(toSeller.awaitingReturnCollection, isFalse);
      expect(toSeller.status, CourierJobStatus.pickedUp);
    });

    test('an old job without kind is a delivery', () {
      final job = CourierJobMapper.job({'hopId': 'h', 'status': 'Assigned'});
      expect(job.isReturn, isFalse);
      expect(job.awaitingReturnCollection, isFalse);
    });

    test('the pickup proof is marked by its purpose', () {
      expect(
        CourierJobMapper.proof({'purpose': 'ReturnPickup'}).isReturnPickup,
        isTrue,
      );
      expect(CourierJobMapper.proof({}).isReturnPickup, isFalse);
    });

    test("can't collect offers 3, 4 and 9; 9 is never a delivery problem", () {
      expect(DeliveryExceptionCode.cantCollect.map((c) => c.wire), [3, 4, 9]);
      expect(DeliveryExceptionCode.handoverRefused.returnPickupOnly, isTrue);
      expect(DeliveryExceptionCode.buyerUnreachable.returnPickupOnly, isFalse);
    });
  });

  group('collect sheet', () {
    late _MockCourierRepository repo;
    late List<ReturnCollectResult?> results;

    Future<void> pumpSheet(
      WidgetTester tester, {
      required Future<String?> Function() pickPhoto,
    }) async {
      setPhoneView(tester);
      results = [];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [courierRepositoryProvider.overrideWithValue(repo)],
          child: ordersTestApp(
            Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async => results.add(
                    await showCourierReturnCollectSheet(
                      context,
                      pickPhoto: pickPhoto,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    FilledButton collectButton(WidgetTester tester) => tester.widget(
      find.ancestor(
        of: find.text('Collect and show my code'),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );

    setUp(() => repo = _MockCourierRepository());

    testWidgets('collect needs at least one photo', (tester) async {
      await pumpSheet(tester, pickPhoto: () async => null);

      expect(collectButton(tester).onPressed, isNull);
      // Backing out of the camera adds nothing.
      await tester.tap(find.byKey(CourierReturnCollectSheet.addPhotoKey));
      await tester.pump();
      expect(collectButton(tester).onPressed, isNull);
      verifyNever(() => repo.uploadProofPhoto(any()));
    });

    testWidgets('a photo uploaded enables collect, which returns it', (
      tester,
    ) async {
      when(
        () => repo.uploadProofPhoto('/tmp/item.jpg'),
      ).thenAnswer((_) async => right('https://cdn/item.jpg'));
      await pumpSheet(tester, pickPhoto: () async => '/tmp/item.jpg');

      await tester.tap(find.byKey(CourierReturnCollectSheet.addPhotoKey));
      await tester.pump();
      await tester.pump();

      expect(collectButton(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(CourierReturnCollectSheet.collectKey));
      await tester.pumpAndSettle();

      expect(results.single?.photoUrls, ['https://cdn/item.jpg']);
      expect(results.single?.note, isNull);
    });
  });
}
