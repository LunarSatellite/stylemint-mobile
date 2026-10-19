import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_fare_mapper.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_fare.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_profile.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_fare_breakdown.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_offer_card.dart';

import '../orders_test_harness.dart';

/// The example from the rider-fare contract v1, §2.
Map<String, dynamic> _roadJson() => {
  'version': 1,
  'method': 'road',
  'roadKm': 7.42,
  'straightLineKm': 5.31,
  'roadDurationSeconds': 1080,
  'detourFactor': null,
  'baseFare': 50.00,
  'perKm': 30.00,
  'distanceAmount': 222.60,
  'tier': 'Traveler',
  'tierMultiplier': 1.00,
  'tripAmount': 272.60,
  'minimumFare': 100.00,
  'minimumApplied': false,
  'extras': [
    {
      'code': 'heavy_parcel',
      'label': 'Heavy parcel (over 5 kg)',
      'amount': 50.00,
    },
    {'code': 'cash_collection', 'label': 'Cash collection', 'amount': 20.00},
    {'code': 'night', 'label': 'Night pick-up (21:00-06:00)', 'amount': 30.00},
  ],
  'extrasAmount': 100.00,
  'roundTo': 5.00,
  'rounding': 2.40,
  'total': 375.00,
  'currency': 'NPR',
  'computedUtc': '2026-10-18T15:30:00+00:00',
};

Map<String, dynamic> _estimatedNeighbourJson() => {
  'version': 1,
  'method': 'estimated',
  'roadKm': 2.0,
  'straightLineKm': 1.48,
  'detourFactor': 1.35,
  'baseFare': 50.0,
  'perKm': 30.0,
  'distanceAmount': 60.0,
  'tier': 'Neighbor',
  'tierMultiplier': 0.85,
  'tripAmount': 100.0,
  'minimumFare': 100.0,
  'minimumApplied': true,
  'extras': <Object>[],
  'extrasAmount': 0,
  'rounding': 0,
  'total': 100.0,
  'currency': 'NPR',
};

HopOffer _offer({FareBreakdown? fare}) {
  final now = DateTime.now().toUtc();
  return HopOffer(
    id: 'offer-1',
    packageId: 'pkg-1',
    tier: DeliveryTier.neighbor,
    hopIndex: 0,
    roundNumber: 1,
    proposedPayoutAmount: fare?.total ?? 120,
    proposedPayoutCurrency: 'NPR',
    fromGeohash: 'tuutv',
    toGeohash: 'tuutw',
    state: HopOfferState.pending,
    offeredUtc: now.subtract(const Duration(minutes: 1)),
    expiresUtc: now.add(const Duration(minutes: 10)),
    mode: OfferMode.auction,
    fare: fare,
  );
}

void main() {
  group('CourierFareMapper', () {
    test('reads the contract example', () {
      final fare = CourierFareMapper.breakdown(_roadJson())!;
      expect(fare.total, 375);
      expect(fare.currency, 'NPR');
      expect(fare.roadPriced, isTrue);
      expect(fare.km, 7.42);
      expect(fare.tierLabel, 'Traveller');
      expect(fare.tierAdjustment, 0);
      expect(fare.extras.map((e) => e.kind), [
        FareExtraKind.heavy,
        FareExtraKind.cashCollection,
        FareExtraKind.night,
      ]);
      expect(fare.isItemised, isTrue);
    });

    test('accepts the event form, a JSON string', () {
      final fare = CourierFareMapper.breakdown(jsonEncode(_roadJson()));
      expect(fare?.total, 375);
    });

    test('absent, malformed or total-less is null, not zeros', () {
      expect(CourierFareMapper.breakdown(null), isNull);
      expect(CourierFareMapper.breakdown(''), isNull);
      expect(CourierFareMapper.breakdown('{not json'), isNull);
      expect(CourierFareMapper.breakdown({'baseFare': 50}), isNull);
      expect(CourierFareMapper.breakdown(<Object>[]), isNull);
    });

    test('an unknown extra code keeps its label and amount', () {
      final json = _roadJson()
        ..['extras'] = [
          {'code': 'rain', 'label': 'Monsoon', 'amount': 15},
        ];
      final fare = CourierFareMapper.breakdown(json)!;
      expect(fare.extras.single.kind, FareExtraKind.other);
      expect(fare.extras.single.label, 'Monsoon');
    });

    test('Neighbour multiplier is a negative adjustment', () {
      final json = _roadJson()
        ..['tier'] = 'Neighbor'
        ..['tierMultiplier'] = 0.85
        ..['tripAmount'] = 231.71;
      final fare = CourierFareMapper.breakdown(json)!;
      expect(fare.tierLabel, 'Neighbour');
      expect(fare.tierAdjustment, closeTo(-40.89, 0.01));
    });
  });

  group('CourierFareBreakdown', () {
    Future<void> pump(WidgetTester tester, Widget child, {double width = 390}) async {
      setPhoneView(tester, width: width);
      await tester.pumpWidget(
        ordersTestApp(
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      );
    }

    testWidgets('road fare: base, distance, tier, each extra, total', (
      tester,
    ) async {
      final fare = CourierFareMapper.breakdown(_roadJson())!;
      await pump(tester, CourierFareBreakdown(fare: fare));

      expect(find.text('Base fare'), findsOneWidget);
      expect(find.text('Rs 50.00'), findsOneWidget);
      expect(find.text('Distance · 7.4 km by road × Rs 30/km'), findsOneWidget);
      expect(find.text('Rs 222.60'), findsOneWidget);
      expect(find.text('Traveller tier ×1'), findsOneWidget);
      expect(find.text('Heavy parcel (over 5 kg)'), findsOneWidget);
      expect(find.text('+ Rs 50.00'), findsOneWidget);
      expect(find.text('Cash collection'), findsOneWidget);
      expect(find.text('+ Rs 20.00'), findsOneWidget);
      expect(find.text('Night pick-up (21:00-06:00)'), findsOneWidget);
      expect(find.text('+ Rs 30.00'), findsOneWidget);
      expect(find.text('Rounded to the nearest Rs 5'), findsOneWidget);
      expect(find.text('Rs 375.00'), findsOneWidget);
      expect(find.byKey(CourierFareBreakdown.estimatedKey), findsNothing);
      expect(find.text(CourierFareBreakdown.estimateNote), findsNothing);
    });

    testWidgets('estimated distance says so, and the minimum fare shows', (
      tester,
    ) async {
      final fare = CourierFareMapper.breakdown(_estimatedNeighbourJson())!;
      await pump(tester, CourierFareBreakdown(fare: fare));

      expect(find.byKey(CourierFareBreakdown.estimatedKey), findsOneWidget);
      expect(find.textContaining('2.0 km, estimated'), findsOneWidget);
      expect(find.text(CourierFareBreakdown.estimateNote), findsOneWidget);
      expect(find.text('Neighbour tier ×0.85'), findsOneWidget);
      expect(find.text('Minimum fare applied'), findsOneWidget);
      // Zero rounding is not drawn as a line.
      expect(find.text('Rounded to the nearest Rs 5'), findsNothing);
    });

    testWidgets('fits at 320dp', (tester) async {
      final fare = CourierFareMapper.breakdown(_roadJson())!;
      await pump(tester, CourierFareCard(fare: fare), width: 320);
      expectNoLayoutErrors(tester);
    });
  });

  group('offer card', () {
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

    testWidgets('shows the breakdown before Accept', (tester) async {
      await pumpCard(
        tester,
        _offer(fare: CourierFareMapper.breakdown(_estimatedNeighbourJson())),
      );
      expect(find.byKey(CourierFareBreakdown.viewKey), findsOneWidget);
      expect(find.byKey(CourierFareBreakdown.estimatedKey), findsOneWidget);
      expect(find.byKey(CourierOfferCard.acceptKey), findsOneWidget);
      expectNoLayoutErrors(tester);
    });

    testWidgets('an older offer without a breakdown shows only the payout', (
      tester,
    ) async {
      await pumpCard(tester, _offer());
      expect(find.byKey(CourierFareBreakdown.viewKey), findsNothing);
      expect(find.text('Rs 120.00'), findsOneWidget);
    });
  });
}
