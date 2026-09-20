import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_care_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/unit_warranty_list.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/app_theme.dart';

/// The state an audit classed as "will look broken": an order line with no
/// tagged units *and* no coverage date rendered absolutely nothing, so a buyer
/// who had been shown the warranty surface saw a blank where it should be.
///
/// A blank is indistinguishable from a bug. It now renders the server's own
/// sentence about that line, which is the answer the report has been carrying
/// all along and which no client ever read.
class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _orderNumber = 'NK2026-00042';
const _lineId = 'line-1';

/// `WarrantyService` writes this, verbatim, for a line nobody attached a
/// policy to. Copied rather than paraphrased: a client that rephrases a
/// warranty position is a client that eventually states one that is not true.
const String noPolicyExplanation =
    'No seller warranty was attached when this item was purchased.';

/// The other reading of "no end date": a policy exists but the clock has not
/// started, which is a different fact and must not read as "no warranty".
const String notStartedExplanation =
    'Warranty coverage starts when delivery is confirmed.';

/// A line with no coverage date. This is the ordinary shape for anything a
/// seller never attached a policy to.
final _uncoveredItem = CareItem(
  subOrderId: 'sub-1',
  subOrderLineId: _lineId,
  productVariantId: 'variant-1',
  title: 'Linen shirt',
  variantLabel: 'M / White',
  stage: CareStage.returnWindowClosed,
  actions: const [],
  guidance: 'Delivered.',
  warrantyEligible: false,
);

final _plan = OrderCarePlan(orderNumber: _orderNumber, items: [_uncoveredItem]);

WarrantyEligibility _eligibilitySaying(String explanation) =>
    WarrantyEligibility(
      orderNumber: _orderNumber,
      items: [
        WarrantyEligibilityItem(
          subOrderId: 'sub-1',
          subOrderLineId: _lineId,
          productVariantId: 'variant-1',
          title: 'Linen shirt',
          isEligible: false,
          statusExplanation: explanation,
          hasOpenClaim: false,
          units: const [],
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
    Size surface = const Size(320, 900),
    double textScale = 1.3,
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
          theme: AppTheme.dark,
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

  group('a line with no units and no coverage date', () {
    testWidgets('says the platform looked and found no warranty', (
      tester,
    ) async {
      await pumpCard(
        tester,
        eligibility: _eligibilitySaying(noPolicyExplanation),
      );

      expect(find.text(noPolicyExplanation), findsOneWidget);
      // Reported, not badged: no shield, because this is not cover.
      expect(find.byIcon(Icons.shield_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps "not started yet" distinct from "no warranty"', (
      tester,
    ) async {
      // Both lines have no end date. Flattening them into one message would
      // tell a buyer with cover that they have none.
      await pumpCard(
        tester,
        eligibility: _eligibilitySaying(notStartedExplanation),
      );

      expect(find.text(notStartedExplanation), findsOneWidget);
      expect(find.text(noPolicyExplanation), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('says nothing when the report has not arrived', (tester) async {
      // A 404 or an outage is a fact about the request, not about the goods.
      // Rendering "no warranty" here would invent an answer nobody gave.
      await pumpCard(tester);

      expect(find.text(noPolicyExplanation), findsNothing);
      expect(find.text(notStartedExplanation), findsNothing);
      expect(find.byType(UnitWarrantyList), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders nothing for a blank explanation', (tester) async {
      // An empty sentence is not an answer either, and an empty row reads as
      // the same blank this whole state exists to remove.
      await pumpCard(tester, eligibility: _eligibilitySaying('   '));

      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('UnitWarrantyList handed no units', () {
    testWidgets('reports the lookup instead of collapsing to nothing', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 400),
              textScaler: TextScaler.linear(1.3),
            ),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: UnitWarrantyList(units: []),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(UnitWarrantyList.noTaggedItemsNote), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
