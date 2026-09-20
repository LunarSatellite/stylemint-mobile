import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/buy_it_again_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import '../../../orders_test_harness.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

/// The restock area had one durable way in and it was conditional on the
/// very thing it was meant to lead to.
///
/// The Buy-It-Again rail carries the only See all link, and the rail draws
/// nothing until the server returns at least one suggestion. A fresh account
/// has no purchase rhythm to read, so it got no rail, so /orders/buy-it-again
/// could not be opened - and with it went the refill basket and the restock
/// rules, which nothing else links to.
///
/// The fix is a door, not a forecast. These pump the real widget against an
/// empty server and assert over the rendered tree: the way in is there, and
/// it still says nothing about what is behind it.
void main() {
  late _MockOrdersRepository orders;

  setUp(() {
    orders = _MockOrdersRepository();
    when(
      orders.getReplenishmentPreference,
    ).thenAnswer((_) async => right(true));
    when(
      orders.getReorderSuggestions,
    ).thenAnswer((_) async => right(<ReorderSuggestionDto>[]));
  });

  /// Buy it again is a stub here: reaching it is the assertion, and the real
  /// screen would only pull in its own dependencies.
  Widget app() {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: BuyItAgainSection()),
        ),
        GoRoute(
          path: RouteNames.buyItAgain,
          builder: (_, _) =>
              const Scaffold(body: Center(child: Text('buy it again'))),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        ordersRepositoryProvider.overrideWithValue(orders),
        personalizationAllowedProvider.overrideWith((ref) async => true),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  Future<void> pump(WidgetTester tester) async {
    setPhoneView(tester);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
  }

  testWidgets('an empty forecast still leads to the restock screens', (
    tester,
  ) async {
    await pump(tester);

    final entry = find.byKey(const ValueKey('restock-entry'));
    expect(entry, findsOneWidget);

    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.text('buy it again'), findsOneWidget);
  });

  testWidgets('a customer who has not opted in still has the way in', (
    tester,
  ) async {
    when(
      orders.getReplenishmentPreference,
    ).thenAnswer((_) async => right(false));
    await pump(tester);

    expect(find.byKey(const ValueKey('restock-enable')), findsOneWidget);
    expect(find.byKey(const ValueKey('restock-entry')), findsOneWidget);
    expectNoLayoutErrors(tester);
  });

  testWidgets('the way in claims nothing about what is behind it', (
    tester,
  ) async {
    await pump(tester);

    // An empty forecast reads as empty. A count, a due date or a nudge here
    // would be a figure no payload contained - the defect this repo keeps
    // shipping - so the row carries none.
    final digits = RegExp(r'\d+');
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final value = text.data ?? '';
      expect(
        digits.hasMatch(value),
        isFalse,
        reason: value,
      );
    }
    expect(find.textContaining('due'), findsNothing);
    expect(find.textContaining('out of'), findsNothing);
  });

  testWidgets('a forecast with rows keeps its own See all link', (
    tester,
  ) async {
    when(orders.getReorderSuggestions).thenAnswer(
      (_) async => right(const [
        ReorderSuggestionDto(
          productId: 'p-1',
          productName: 'Aloe Face Wash',
          suggestedQuantity: 2,
          reason: 'you may be out',
          price: 450,
          currency: 'NPR',
          daysUntilExpected: 4,
        ),
      ]),
    );
    await pump(tester);

    expect(find.byKey(const ValueKey('restock-see-all')), findsOneWidget);
    expect(find.byKey(const ValueKey('restock-entry')), findsNothing);
  });
}
