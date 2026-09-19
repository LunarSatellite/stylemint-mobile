import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/screens/buy_it_again_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';

import '../../../orders_test_harness.dart';
import 'refill_plan_test_doubles.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

const _suggestions = [
  ReorderSuggestionDto(
    productId: 'p-1',
    productName: 'Aloe Face Wash',
    suggestedQuantity: 2,
    reason: 'Based on your typical 30-day restock cycle',
    price: 450,
    currency: 'NPR',
    daysUntilExpected: 4,
    confidence: 0.72,
  ),
];

/// The way from "Buy it again" to the refill basket.
///
/// The one rule this widget exists to keep: **it must never dangle.** A link
/// that could only lead to "you're paused", "you're switched off" or an empty
/// room is a link that should not be drawn at all.
void main() {
  late _MockOrdersRepository orders;
  late FakeRefillPlanDataSource data;

  setUp(() {
    orders = _MockOrdersRepository();
    data = FakeRefillPlanDataSource()..preferenceValue = preparingPreference;
    when(
      orders.getReplenishmentPreference,
    ).thenAnswer((_) async => right(true));
    when(
      orders.getReorderSuggestions,
    ).thenAnswer((_) async => right(_suggestions));
  });

  Widget app({bool personalizationAllowed = true, double textScale = 1}) =>
      ProviderScope(
        overrides: [
          ordersRepositoryProvider.overrideWithValue(orders),
          refillPlanDataSourceProvider.overrideWithValue(data),
          personalizationAllowedProvider.overrideWith(
            (ref) async => personalizationAllowed,
          ),
        ],
        child: ordersTestApp(
          const BuyItAgainScreen(),
          textScale: textScale,
          wrapInScaffold: false,
        ),
      );

  testWidgets('offers the basket and the rules when the rules allow it', (
    tester,
  ) async {
    setTallPhoneView(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('refill-plan-entry')), findsOneWidget);
    expect(find.byKey(const ValueKey('refill-plan-open')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('refill-plan-open-rules')),
      findsOneWidget,
    );
    // It sits with the existing Buy-It-Again list, not instead of it.
    expect(find.text('Aloe Face Wash'), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets('offers only the rules at the reminders-only level', (
    tester,
  ) async {
    data.preferenceValue = preparingPreference.copyWith(
      automationLevel: 'remindOnly',
    );
    setTallPhoneView(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // No link to a basket that would answer 204 by design.
    expect(find.byKey(const ValueKey('refill-plan-open')), findsNothing);
    expect(
      find.byKey(const ValueKey('refill-plan-open-rules')),
      findsOneWidget,
    );
  });

  testWidgets('draws nothing at all for a refused customer', (tester) async {
    setTallPhoneView(tester);
    await tester.pumpWidget(app(personalizationAllowed: false));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('refill-plan-entry')), findsNothing);
    expect(find.byKey(const ValueKey('refill-plan-open')), findsNothing);
    expect(
      find.byKey(const ValueKey('refill-plan-open-rules')),
      findsNothing,
    );
    expect(data.preferenceCalls, 0, reason: 'rules were read without consent');
  });

  testWidgets('draws nothing while the customer is inside their own pause', (
    tester,
  ) async {
    data.preferenceValue = preparingPreference.copyWith(
      paused: true,
      pausedUntilUtc: DateTime.utc(2026, 10, 20),
    );
    setTallPhoneView(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('refill-plan-entry')), findsNothing);
  });

  testWidgets('draws nothing when the rules cannot be read', (tester) async {
    data.failEverything = true;
    setTallPhoneView(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('refill-plan-entry')), findsNothing);
  });

  testWidgets('stays reachable when there is nothing to suggest', (
    tester,
  ) async {
    when(orders.getReorderSuggestions).thenAnswer(
      (_) async => right(const <ReorderSuggestionDto>[]),
    );
    setTallPhoneView(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Nothing to suggest right now'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('refill-plan-open-rules')),
      findsOneWidget,
    );
    expectNoLayoutErrors(tester);
  });

  testWidgets('does not overflow at 320dp with text scale 1.3', (
    tester,
  ) async {
    setPhoneView(tester, width: 320);
    await tester.pumpWidget(app(textScale: 1.3));
    await tester.pumpAndSettle();
    expectNoLayoutErrors(tester);
  });

  testWidgets('both entry controls are labelled and tappable', (tester) async {
    final handle = tester.ensureSemantics();
    setTallPhoneView(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expectLabelledAndTappable(
      tester,
      const ValueKey('refill-plan-open'),
      'Open your refill basket',
    );
    expectLabelledAndTappable(
      tester,
      const ValueKey('refill-plan-open-rules'),
      'Open your restock rules',
    );

    handle.dispose();
  });
}
