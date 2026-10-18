import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/courier/data/courier_payouts_repository.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_payout.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/entities/courier_work.dart';
import 'package:stylemint_mobile_frontend/features/courier/domain/repositories/courier_repository.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/screens/courier_balance_screen.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_fare_breakdown.dart';
import 'package:stylemint_mobile_frontend/features/courier/presentation/widgets/courier_payout_request_sheet.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/payout_providers.dart';
import 'package:stylemint_mobile_frontend/features/courier/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/datasources/payout_destinations_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/payouts/data/models/payout_destination_dto.dart';
import 'package:stylemint_mobile_frontend/features/payouts/shared/providers.dart';

import '../orders_test_harness.dart';

class _MockCourierRepository extends Mock implements CourierRepository {}

class _MockDestinations extends Mock
    implements PayoutDestinationsRemoteDataSource {}

/// Rider-payout contract v1 §3 examples.
Map<String, dynamic> _balanceJson({
  double net = 650,
  double cash = 2500,
  Map<String, dynamic>? inFlight,
}) => {
  'pendingEarnings': 420.0,
  'onHoldEarnings': 0.0,
  'availableEarnings': 3150.0,
  'cashToRemit': cash,
  'netPayable': net,
  'lifetimeEarnings': 18200.0,
  'currency': 'NPR',
  'settleAfterHours': 24,
  'onDemandMinAmount': 10000.0,
  'onDemandMaxAmount': 70000.0,
  'onDemandFeePercent': 2.0,
  'hasDefaultDestination': true,
  'inFlightPayout': inFlight,
};

Map<String, dynamic> _payoutJson({
  required String id,
  required int state,
  String? reference,
  String? failure,
  double net = 650,
}) => {
  'id': id,
  'payeeProfileId': 'p1',
  'payeeKind': 3,
  'mode': 1,
  'destination': 4,
  'destinationRef': '******7890',
  'requestedAmountValue': net,
  'requestedAmountCurrency': 'NPR',
  'feeAmountValue': 0.0,
  'feeAmountCurrency': 'NPR',
  'netAmountValue': net,
  'netAmountCurrency': 'NPR',
  'requestedUtc': '2026-10-16T06:00:00+00:00',
  'pendingUntilUtc': '2026-10-19T06:00:00+00:00',
  'state': state,
  'providerPayoutId': reference,
  'failureCode': failure == null ? null : 'bank.rejected',
  'failureMessage': failure,
  'paidUtc': state == 3 ? '2026-10-17T06:00:00+00:00' : null,
};

Map<String, dynamic> _earningJson({int status = 1, Object? fare}) => {
  'entryId': 'e1',
  'hopId': 'h1',
  'packageId': 'pk1',
  'subOrderId': null,
  'trackingNumber': 'SMD-8F2K1Q',
  'amount': 375.0,
  'currency': 'NPR',
  'status': status,
  'holdReason': status == 2 ? 'Buyer reported an issue' : null,
  'completedUtc': '2026-10-18T09:12:00+00:00',
  'settleAfterUtc': '2026-10-19T09:12:00+00:00',
  'settledUtc': null,
  'reversedUtc': null,
  'cashCollected': 2500.0,
  'fareBreakdown': fare,
};

Map<String, dynamic> _fareJson() => {
  'method': 'road',
  'roadKm': 7.42,
  'baseFare': 50.0,
  'perKm': 30.0,
  'distanceAmount': 222.6,
  'tier': 'Traveler',
  'tierMultiplier': 1.0,
  'tripAmount': 272.6,
  'minimumApplied': false,
  'extras': [
    {'code': 'night', 'label': 'Night pick-up (21:00-06:00)', 'amount': 30.0},
  ],
  'rounding': 2.4,
  'total': 375.0,
  'currency': 'NPR',
};

class _FakePayouts implements CourierPayoutsRepository {
  Either<NetworkExceptions, CourierBalance> balance = right(
    CourierPayoutMapper.balance(_balanceJson()),
  );
  Either<NetworkExceptions, CourierPage<CourierPayoutEarning>> earnings =
      right(
        CourierPage(
          items: [CourierPayoutMapper.earning(_earningJson(fare: _fareJson()))],
        ),
      );
  Either<NetworkExceptions, CourierPage<CourierPayout>> payouts = right(
    CourierPage(
      items: [
        CourierPayoutMapper.payout(_payoutJson(id: 'a', state: 6)),
        CourierPayoutMapper.payout(
          _payoutJson(id: 'b', state: 3, reference: 'NIMB-778812'),
        ),
        CourierPayoutMapper.payout(
          _payoutJson(id: 'c', state: 4, failure: 'Account closed'),
        ),
      ],
    ),
  );
  Either<NetworkExceptions, CourierPayout> requestResult = right(
    CourierPayoutMapper.payout(_payoutJson(id: 'new', state: 1, net: 12000)),
  );
  final requests = <({String destinationId, double? amount})>[];

  @override
  Future<Either<NetworkExceptions, CourierBalance>> getBalance() async =>
      balance;

  @override
  Future<Either<NetworkExceptions, CourierPage<CourierPayoutEarning>>>
  listEarnings({String? cursor, int pageSize = 25}) async => earnings;

  @override
  Future<Either<NetworkExceptions, CourierPage<CourierPayout>>> listPayouts({
    String? cursor,
    int pageSize = 25,
  }) async => payouts;

  @override
  Future<Either<NetworkExceptions, CourierPayout>> requestPayout({
    required String destinationId,
    double? amount,
  }) async {
    requests.add((destinationId: destinationId, amount: amount));
    return requestResult;
  }

  @override
  Future<Either<NetworkExceptions, Unit>> cancelPayout(String payoutId) async =>
      right(unit);
}

const _notFound = NetworkExceptions.notFound();

void main() {
  late _FakePayouts payouts;
  late _MockCourierRepository courier;
  late _MockDestinations destinations;

  setUp(() {
    payouts = _FakePayouts();
    courier = _MockCourierRepository();
    destinations = _MockDestinations();

    when(() => courier.getEarnings()).thenAnswer(
      (_) async => right<NetworkExceptions, CourierEarnings>(
        const CourierEarnings(
          totalEarned: 4200,
          last7Days: 900,
          last30Days: 4200,
          completedHops: 21,
          currency: 'NPR',
        ),
      ),
    );
    when(
      () => courier.listEarningsHistory(
        skip: any(named: 'skip'),
        take: any(named: 'take'),
      ),
    ).thenAnswer(
      (_) async => right<NetworkExceptions, List<CourierEarningRow>>(const [
        CourierEarningRow(
          hopId: 'h9',
          packageId: 'p9',
          hopIndex: 1,
          amount: 180,
          currency: 'NPR',
          fromGeohash: 'tuutv',
          toGeohash: 'tuutw',
        ),
      ]),
    );
    when(() => courier.getEscrowBalance(any())).thenAnswer(
      (_) async => right<NetworkExceptions, CourierMoney>(
        const CourierMoney(amount: 1500, currency: 'NPR'),
      ),
    );
    when(() => destinations.list(3)).thenAnswer(
      (_) async => [
        PayoutDestinationDto.fromJson(const {
          'id': 'd1',
          'kind': 4,
          'label': 'My eSewa',
          'accountIdentifierMasked': '98******10',
          'isDefault': true,
          'verified': true,
        }),
      ],
    );
  });

  Future<void> pump(WidgetTester tester) async {
    // Tall, so the whole list is built without scrolling.
    tester.view
      ..physicalSize = const Size(390, 3200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          courierPayoutsRepositoryProvider.overrideWithValue(payouts),
          courierRepositoryProvider.overrideWithValue(courier),
          payoutDestinationsDataSourceProvider.overrideWithValue(destinations),
        ],
        child: ordersTestApp(
          const CourierBalanceScreen(courierProfileId: 'cp1'),
          wrapInScaffold: false,
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  testWidgets('balance, methods, payouts in each state, deliveries', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('You can be paid'), findsOneWidget);
    expect(find.byKey(CourierBalanceScreen.netPayableKey), findsOneWidget);
    expect(find.text('Rs 650.00'), findsWidgets);
    expect(find.text('Rs 3,150.00'), findsOneWidget);
    expect(find.text('Rs 420.00'), findsOneWidget);
    expect(find.text('Cash to hand in'), findsOneWidget);
    expect(find.text('Rs 2,500.00'), findsOneWidget);

    // Masked, never the full number.
    expect(find.text('My eSewa'), findsOneWidget);
    expect(find.text('eSewa · 98******10'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);

    expect(find.text('Awaiting transfer'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
    expect(find.textContaining('Ref NIMB-778812'), findsOneWidget);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.textContaining('Account closed'), findsOneWidget);

    expect(find.text('SMD-8F2K1Q'), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.textContaining('collected Rs 2,500.00 cash'), findsOneWidget);
    expect(find.byType(CourierFareBreakdown), findsNothing);

    await tester.tap(find.text('SMD-8F2K1Q'));
    await tester.pump();
    expect(find.byType(CourierFareBreakdown), findsOneWidget);
    expect(find.text('Night pick-up (21:00-06:00)'), findsOneWidget);

    // The deposit is its own section, apart from earnings.
    expect(find.text('Your deposit'), findsOneWidget);
    expect(find.text('Rs 1,500.00'), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets("the ledger's line form (contract v2) shows how it was priced", (
    tester,
  ) async {
    payouts.earnings = right(
      CourierPage(
        items: [
          CourierPayoutMapper.earning(
            _earningJson(
              status: 3,
              fare: {
                'ref': null,
                'method': 'estimated',
                'distanceKm': 2.0,
                'tier': 'Neighbor',
                'lines': [
                  {
                    'code': 'trip',
                    'label': 'Base Rs 50 + 2.0 km × Rs 30',
                    'amount': 100.0,
                  },
                  {'code': 'night', 'label': 'Night pick-up', 'amount': 30.0},
                ],
              },
            ),
          ),
        ],
      ),
    );
    await pump(tester);

    expect(find.byKey(CourierEarningTile.linesKey), findsNothing);
    await tester.tap(find.text('SMD-8F2K1Q'));
    await tester.pump();
    expect(find.byKey(CourierEarningTile.linesKey), findsOneWidget);
    expect(find.text('2.0 km, estimated · Neighbour tier'), findsOneWidget);
    expect(find.text('Base Rs 50 + 2.0 km × Rs 30'), findsOneWidget);
    expect(find.text('Night pick-up'), findsOneWidget);
    expect(find.text('Available'), findsWidgets);
  });

  testWidgets('not deployed (404): "being set up", with the old totals', (
    tester,
  ) async {
    payouts
      ..balance = left(_notFound)
      ..earnings = left(_notFound)
      ..payouts = left(_notFound);
    when(() => destinations.list(3)).thenThrow(_notFound);
    await pump(tester);

    expect(find.byKey(CourierBalanceScreen.settingUpKey), findsOneWidget);
    expect(find.text(CourierBalanceScreen.settingUpTitle), findsOneWidget);
    // The delivery module's figures still show.
    expect(find.text('Rs 4,200.00'), findsOneWidget);
    expect(find.text('Leg 2'), findsOneWidget);
    // Never "none" for "could not load".
    expect(find.text('No payouts yet.'), findsNothing);
    expect(find.textContaining('No payout method yet'), findsNothing);
    expect(find.text('Rs 0.00'), findsNothing);
    expect(find.byKey(CourierBalanceScreen.requestKey), findsNothing);
    expect(find.byKey(CourierBalanceScreen.balanceErrorKey), findsNothing);
    expectNoLayoutErrors(tester);
  });

  testWidgets('a real failure says it could not load, not zero', (
    tester,
  ) async {
    payouts.balance = left(const NetworkExceptions.serverUnavailable());
    await pump(tester);

    expect(find.byKey(CourierBalanceScreen.balanceErrorKey), findsOneWidget);
    expect(find.byKey(CourierBalanceScreen.settingUpKey), findsNothing);
    expect(find.byKey(CourierBalanceScreen.netPayableKey), findsNothing);
  });

  testWidgets('owing cash: says so and cannot request', (tester) async {
    payouts.balance = right(
      CourierPayoutMapper.balance(_balanceJson(net: -500, cash: 3650)),
    );
    await pump(tester);

    expect(find.text('You owe'), findsOneWidget);
    expect(find.text('Rs 500.00'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(CourierBalanceScreen.requestKey),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('an in-flight payout replaces the request button', (
    tester,
  ) async {
    payouts.balance = right(
      CourierPayoutMapper.balance(
        _balanceJson(net: 12000, inFlight: _payoutJson(id: 'x', state: 6)),
      ),
    );
    await pump(tester);

    expect(find.byKey(CourierBalanceScreen.requestKey), findsNothing);
    expect(find.textContaining('is awaiting transfer'), findsOneWidget);
  });

  group('request payout', () {
    setUp(() {
      payouts.balance = right(
        CourierPayoutMapper.balance(_balanceJson(net: 12000, cash: 0)),
      );
    });

    Future<void> openSheet(WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(CourierBalanceScreen.requestKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CourierPayoutRequestSheet), findsOneWidget);
    }

    testWidgets('the whole net payable to the default method', (
      tester,
    ) async {
      await openSheet(tester);
      // 2% on-demand fee shown before confirming.
      expect(find.textContaining('On-demand fee Rs 240.00'), findsOneWidget);

      await tester.tap(find.byKey(CourierPayoutRequestSheet.submitKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(payouts.requests.single.destinationId, 'd1');
      expect(payouts.requests.single.amount, isNull);
      expect(find.byType(CourierPayoutRequestSheet), findsNothing);
      expect(find.textContaining('Payout of Rs 12,000.00 requested'), findsOneWidget);
    });

    testWidgets('below the on-demand minimum is caught before sending', (
      tester,
    ) async {
      await openSheet(tester);
      await tester.enterText(
        find.byKey(CourierPayoutRequestSheet.amountKey),
        '5000',
      );
      await tester.tap(find.byKey(CourierPayoutRequestSheet.submitKey));
      await tester.pump();

      expect(find.byKey(CourierPayoutRequestSheet.errorKey), findsOneWidget);
      expect(find.textContaining('starts at Rs 10,000'), findsOneWidget);
      expect(payouts.requests, isEmpty);
    });

    testWidgets("the server's refusal stays on the sheet in plain words", (
      tester,
    ) async {
      payouts.requestResult = left(
        const NetworkExceptions.validation(
          code: 'rule.violation',
          field: 'PAYOUT_IN_FLIGHT',
        ),
      );
      await openSheet(tester);
      await tester.tap(find.byKey(CourierPayoutRequestSheet.submitKey));
      await tester.pump();
      await tester.pump();

      expect(find.byType(CourierPayoutRequestSheet), findsOneWidget);
      expect(find.textContaining('already on its way'), findsOneWidget);
    });

    testWidgets('no payout method yet: nothing is sent', (tester) async {
      when(() => destinations.list(3)).thenAnswer((_) async => const []);
      await pump(tester);
      expect(find.textContaining('No payout method yet'), findsOneWidget);
    });
  });

  group('courierPayoutRequestError', () {
    final balance = CourierPayoutMapper.balance(_balanceJson());

    String message(NetworkExceptions failure) =>
        courierPayoutRequestError(failure, balance);

    test('maps the contract refusals', () {
      expect(
        message(
          const NetworkExceptions.validation(
            code: 'rule.violation',
            field: 'CASH_EXCEEDS_EARNINGS',
          ),
        ),
        contains('Hand it in first'),
      );
      expect(
        message(
          const NetworkExceptions.validation(
            code: 'rule.violation',
            field: 'rule.insufficient_balance',
          ),
        ),
        contains('more than you can be paid'),
      );
      expect(
        message(
          const NetworkExceptions.validation(
            code: 'validation.out_of_range',
            field: 'RequestedAmount',
          ),
        ),
        contains('between Rs 10,000 and Rs 70,000'),
      );
      expect(message(_notFound), contains('not found'));
    });
  });

  group('CourierPayoutMapper', () {
    test('balance and an in-flight payout', () {
      final b = CourierPayoutMapper.balance(
        _balanceJson(inFlight: _payoutJson(id: 'x', state: 6)),
      );
      expect(b.netPayable, 650);
      expect(b.cashToRemit, 2500);
      expect(b.inFlightPayout?.state, CourierPayoutState.awaitingTransfer);
      expect(b.canRequest, isFalse);
      expect(b.feeFor(12000), 240);
    });

    test('earning: status, cash, and either breakdown shape', () {
      final withFare = CourierPayoutMapper.earning(
        _earningJson(status: 2, fare: _fareJson()),
      );
      expect(withFare.status, CourierEarningStatus.onHold);
      expect(withFare.holdReason, 'Buyer reported an issue');
      expect(withFare.cashCollected, 2500);
      expect(withFare.fare?.total, 375);

      final withLines = CourierPayoutMapper.earning(
        _earningJson(
          fare: {
            'ref': null,
            'lines': [
              {'code': 'fare', 'label': 'Delivery fare', 'amount': 180.0},
            ],
          },
        ),
      );
      expect(withLines.fare, isNull);
      expect(withLines.lines.single.label, 'Delivery fare');
    });

    test('payout states by number', () {
      expect(CourierPayoutState.fromWire(6), CourierPayoutState.awaitingTransfer);
      expect(CourierPayoutState.fromWire(3), CourierPayoutState.paid);
      expect(CourierPayoutState.fromWire(99), CourierPayoutState.unknown);
      expect(
        CourierPayoutMapper.payout(
          _payoutJson(id: 'b', state: 3, reference: 'R1'),
        ).reference,
        'R1',
      );
    });
  });
}
