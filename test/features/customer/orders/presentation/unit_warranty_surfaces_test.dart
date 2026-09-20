import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/warranty_claim_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/warranty_eligibility_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_care_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/unit_warranty_list.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _orderNumber = 'NK2026-00042';
const _lineId = 'line-1';

/// The order was placed a month before anything else here. It exists in these
/// tests for one reason: to be the date that must never appear on screen when
/// a unit has no recorded start.
final _orderedUtc = DateTime.utc(2026, 8, 20);

final _careItem = CareItem(
  subOrderId: 'sub-1',
  subOrderLineId: _lineId,
  productVariantId: 'variant-1',
  title: 'Linen shirt',
  variantLabel: 'M / White',
  stage: CareStage.returnWindowClosed,
  actions: const [],
  guidance: 'Delivered. Your warranty runs from delivery.',
  warrantyEligible: true,
  warrantyEndsUtc: DateTime.utc(2027, 9, 11),
);

final _plan = OrderCarePlan(orderNumber: _orderNumber, items: [_careItem]);

WarrantyUnitEligibility _unit({
  required String reference,
  DateTime? startsUtc,
  DateTime? endsUtc,
  WarrantyClockBasis? basis,
  bool hasOpenClaim = false,
  String explanation = '',
}) => WarrantyUnitEligibility(
  unitMarkerBindingId: 'binding-$reference',
  markerReference: reference,
  inServiceSinceUtc: startsUtc,
  isEligible: true,
  statusExplanation: explanation,
  hasOpenClaim: hasOpenClaim,
  coverageStartsUtc: startsUtc,
  coverageEndsUtc: endsUtc,
  clockBasis: basis,
);

WarrantyEligibility _eligibility(List<WarrantyUnitEligibility> units) =>
    WarrantyEligibility(
      orderNumber: _orderNumber,
      items: [
        WarrantyEligibilityItem(
          subOrderId: 'sub-1',
          subOrderLineId: _lineId,
          productVariantId: 'variant-1',
          title: 'Linen shirt',
          isEligible: true,
          statusExplanation: '',
          hasOpenClaim: false,
          units: units,
        ),
      ],
    );

void main() {
  late _MockOrdersRepository repository;

  setUp(() {
    repository = _MockOrdersRepository();
    when(
      () => repository.getOrderCarePlan(_orderNumber),
    ).thenAnswer((_) async => right(_plan));
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    WarrantyEligibility? eligibility,
    Size surface = const Size(400, 900),
    double textScale = 1,
  }) async {
    when(() => repository.getWarrantyEligibility(_orderNumber)).thenAnswer(
      (_) async => eligibility == null
          ? left(const NetworkExceptions.notFound())
          : right(eligibility),
    );
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: surface,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: OrderCareCard(orderNumber: _orderNumber),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // ------------------------------------------- the path that must not move

  group('a line with no marker', () {
    /// The whole safety case in one test. Almost all stock carries no marker
    /// and never will, so if this drifts, real buyers lose the surface their
    /// real cover is shown on.
    testWidgets('renders the line-level chip exactly as before', (
      tester,
    ) async {
      await pumpCard(tester, eligibility: _eligibility(const []));

      expect(find.text('Warranty to Sep 11, 2027'), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
      expect(find.byType(UnitWarrantyList), findsNothing);
    });

    testWidgets('renders the line-level chip when eligibility fails too', (
      tester,
    ) async {
      // A 404 or an outage must not remove a warranty from the screen.
      await pumpCard(tester);

      expect(find.text('Warranty to Sep 11, 2027'), findsOneWidget);
      expect(find.byType(UnitWarrantyList), findsNothing);
    });
  });

  // --------------------------------------- three items, three warranties

  group('three tagged items on one line', () {
    final threeUnits = [
      _unit(
        reference: 'UM7ZK3Q8R2VD',
        startsUtc: DateTime.utc(2026, 9, 10),
        endsUtc: DateTime.utc(2027, 9, 10),
        basis: WarrantyClockBasis.subOrderDelivery,
      ),
      _unit(
        reference: 'UM4BN6X1W9TC',
        startsUtc: DateTime.utc(2026, 9, 10),
        endsUtc: DateTime.utc(2027, 9, 10),
        basis: WarrantyClockBasis.subOrderDelivery,
        hasOpenClaim: true,
      ),
      _unit(
        reference: 'UM2QD8V5L3HM',
        startsUtc: DateTime.utc(2026, 9, 12),
        endsUtc: DateTime.utc(2027, 9, 12),
        basis: WarrantyClockBasis.unitHandover,
      ),
    ];

    testWidgets('reads as three separate warranties, not one', (tester) async {
      await pumpCard(tester, eligibility: _eligibility(threeUnits));

      expect(find.text('Item 1 of 3'), findsOneWidget);
      expect(find.text('Item 2 of 3'), findsOneWidget);
      expect(find.text('Item 3 of 3'), findsOneWidget);
      // Each names its own tag, so two garments can never be read as one.
      expect(find.text('UM7ZK3Q8R2VD'), findsOneWidget);
      expect(find.text('UM4BN6X1W9TC'), findsOneWidget);
      expect(find.text('UM2QD8V5L3HM'), findsOneWidget);
      // The merged line-level chip is gone, because it would be a merge of
      // three different answers.
      expect(find.text('Warranty to Sep 11, 2027'), findsNothing);
      expect(
        find.textContaining('has its own warranty'),
        findsOneWidget,
        reason: 'the screen must say the claims are separate, not imply it',
      );
    });

    testWidgets('an open claim is shown against that item only', (
      tester,
    ) async {
      await pumpCard(tester, eligibility: _eligibility(threeUnits));

      expect(find.text('A claim is open on this item only.'), findsOneWidget);
    });

    /// Scoped to the new widget rather than to the whole card. The card's
    /// own header row and its line-level chips used to overflow at this size
    /// too; they are fixed now, and `order_care_card_overflow_test.dart`
    /// covers the whole card at 320dp x 1.3.
    testWidgets('no overflow at 320dp with text at 1.3x', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 1400),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: UnitWarrantyList(
                  units: threeUnits,
                  onOpenUnit: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('an unrecorded start does not overflow at 320dp either', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 1400),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: UnitWarrantyList(
                  units: [_unit(reference: 'UM7ZK3Q8R2VD')],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ------------------------------------------------ absent stays absent

  group('a unit with no recorded clock basis', () {
    testWidgets('says the start is not recorded and names no date', (
      tester,
    ) async {
      await pumpCard(
        tester,
        eligibility: _eligibility([
          _unit(reference: 'UM7ZK3Q8R2VD'),
        ]),
      );

      expect(find.textContaining('Start date not recorded'), findsOneWidget);
      expect(find.textContaining('Counted from'), findsNothing);
      expect(find.textContaining('Cover runs to'), findsNothing);
      // The order date is right there in the fixture and must not be used.
      expect(find.textContaining('Aug 20, 2026'), findsNothing);
      expect(find.textContaining('${_orderedUtc.year}'), findsNothing);
    });

    testWidgets('a start with no basis is still treated as unrecorded', (
      tester,
    ) async {
      // Half a fact is not a fact: without knowing what a date was counted
      // from, "covered until" means nothing.
      await pumpCard(
        tester,
        eligibility: _eligibility([
          _unit(
            reference: 'UM7ZK3Q8R2VD',
            startsUtc: DateTime.utc(2026, 9, 10),
            endsUtc: DateTime.utc(2027, 9, 10),
          ),
        ]),
      );

      expect(find.textContaining('Start date not recorded'), findsOneWidget);
      expect(find.textContaining('Sep 10, 2027'), findsNothing);
    });

    testWidgets('names the handover when that is what the clock used', (
      tester,
    ) async {
      await pumpCard(
        tester,
        eligibility: _eligibility([
          _unit(
            reference: 'UM7ZK3Q8R2VD',
            startsUtc: DateTime.utc(2026, 9, 12),
            endsUtc: DateTime.utc(2027, 9, 12),
            basis: WarrantyClockBasis.unitHandover,
          ),
        ]),
      );

      expect(find.textContaining('Counted from handover'), findsOneWidget);
      expect(find.textContaining('Start date not recorded'), findsNothing);
    });
  });

  // ------------------------------------------------------- wire parsing

  group('WarrantyEligibilityDto', () {
    test('a line with no units parses to an empty list, never a null unit', () {
      final dto = WarrantyEligibilityDto.fromJson({
        'orderNumber': _orderNumber,
        'items': [
          {'subOrderLineId': _lineId, 'title': 'Linen shirt'},
        ],
      });

      expect(dto.toDomain().items.single.units, isEmpty);
      expect(dto.toDomain().items.single.isUnitBound, isFalse);
    });

    test('a null clock basis stays null rather than defaulting', () {
      final dto = WarrantyUnitEligibilityDto.fromJson({
        'unitMarkerBindingId': 'binding-1',
        'markerReference': 'UM7ZK3Q8R2VD',
        'clockBasis': null,
        'coverageStartsUtc': null,
      });

      expect(dto.clockBasis, isNull);
      expect(dto.coverageStartsUtc, isNull);
      expect(dto.toDomain().hasRecordedStart, isFalse);
    });

    test('an unparseable date is null, not the epoch', () {
      final dto = WarrantyUnitEligibilityDto.fromJson({
        'unitMarkerBindingId': 'binding-1',
        'coverageStartsUtc': 'not a date',
      });

      expect(dto.coverageStartsUtc, isNull);
    });

    test('both clock bases parse by name', () {
      expect(
        WarrantyClockBasis.fromJson('SubOrderDelivery'),
        WarrantyClockBasis.subOrderDelivery,
      );
      expect(
        WarrantyClockBasis.fromJson('UnitHandover'),
        WarrantyClockBasis.unitHandover,
      );
      expect(
        WarrantyClockBasis.fromJson('SomethingNewer'),
        WarrantyClockBasis.unrecognised,
      );
    });
  });

  group('WarrantyClaimDto', () {
    test('a line-level claim carries no unit', () {
      final claim = WarrantyClaimDto.fromJson({
        'id': 'claim-1',
        'claimNumber': 'SM-W-20260901-ABCDEF',
        'state': 1,
      }).toDomain();

      expect(claim.unitMarkerBindingId, isNull);
      expect(claim.unit, isNull);
      expect(claim.isUnitBound, isFalse);
    });

    test(
      'a superseded binding reports the correction rather than hiding it',
      () {
        final claim = WarrantyClaimDto.fromJson({
          'id': 'claim-1',
          'claimNumber': 'SM-W-20260902-BCDEFA',
          'state': 1,
          'unitMarkerBindingId': 'binding-old',
          'unit': {
            'bindingId': 'binding-old',
            'markerReference': 'UM7ZK3Q8R2VD',
            'isLive': false,
            'supersededUtc': '2026-09-16T00:00:00Z',
            'supersededByBindingId': 'binding-new',
          },
        }).toDomain();

        // The claim still names the binding it was filed against.
        expect(claim.unitMarkerBindingId, 'binding-old');
        expect(claim.unit!.isLive, isFalse);
        expect(claim.unit!.supersededByBindingId, 'binding-new');
      },
    );

    test('an absent isLive is not read as superseded', () {
      final claim = WarrantyClaimDto.fromJson({
        'id': 'claim-1',
        'state': 1,
        'unit': {'bindingId': 'binding-1', 'markerReference': 'UM7ZK3Q8R2VD'},
      }).toDomain();

      expect(claim.unit!.isLive, isTrue);
    });
  });
}
