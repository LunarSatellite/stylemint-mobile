import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_care_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_care_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _orderNumber = 'NK2026-00042';

/// One line carrying every chip the card can draw at once: the "Care &
/// returns" header, a line-level warranty chip with a full date, and a
/// days-left chip. Each of the three overflowed at 320dp x 1.3 before the
/// fix (69px, 126px and 95px respectively).
final _item = CareItem(
  subOrderId: 'sub-1',
  subOrderLineId: 'line-1',
  productVariantId: 'variant-1',
  title: 'Hand-loomed pashmina overcoat',
  variantLabel: 'L / Charcoal',
  stage: CareStage.returnWindowOpen,
  daysLeftToReturn: 12,
  actions: const [CareAction.returnItem, CareAction.warrantyClaim],
  guidance: 'Delivered. Your warranty runs from delivery.',
  warrantyEligible: true,
  warrantyEndsUtc: DateTime.utc(2027, 9, 11),
);

final _plan = OrderCarePlan(orderNumber: _orderNumber, items: [_item]);

void main() {
  testWidgets('OrderCareCard does not overflow at 320dp with text at 1.3x', (
    tester,
  ) async {
    final repository = _MockOrdersRepository();
    when(
      () => repository.getOrderCarePlan(_orderNumber),
    ).thenAnswer((_) async => right(_plan));
    when(
      () => repository.getWarrantyEligibility(_orderNumber),
    ).thenAnswer((_) async => left(const NetworkExceptions.notFound()));

    await tester.binding.setSurfaceSize(const Size(320, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [ordersRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(320, 1400),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                child: OrderCareCard(orderNumber: _orderNumber),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The chips wrap rather than shrink, so both values stay readable.
    expect(find.textContaining('Warranty to'), findsOneWidget);
    expect(find.textContaining('12 days left to return'), findsOneWidget);
  });
}
