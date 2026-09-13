import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_scenarios.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/repositories/cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/basket_scenarios_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/screens/cart_scenarios_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class _MockCartRepository extends Mock implements CartRepository {}

typedef _ScenariosResult = Either<NetworkExceptions, BasketScenarios>;

const _cart = Cart(
  id: 'cart-1',
  items: [
    CartItem(
      id: 'line-1',
      productId: 'prod-1',
      productName: 'Linen shirt',
      productImageUrl: 'https://example.test/shirt.jpg',
      variantName: 'M / White',
      quantity: 2,
      unitPrice: Money(amount: 2500, currency: 'NPR'),
      isInStock: true,
    ),
    CartItem(
      id: 'line-2',
      productId: 'prod-2',
      productName: 'Canvas tote',
      productImageUrl: 'https://example.test/tote.jpg',
      variantName: '',
      quantity: 1,
      unitPrice: Money(amount: 1200, currency: 'NPR'),
      isInStock: true,
    ),
  ],
  subtotal: Money(amount: 6200, currency: 'NPR'),
  shippingTotal: Money(amount: 0, currency: 'NPR'),
  taxTotal: Money(amount: 806, currency: 'NPR'),
  total: Money(amount: 7006, currency: 'NPR'),
);

BasketScenario _scenario({
  required BasketScenarioKind kind,
  required String title,
  required double total,
  required double difference,
  bool feasible = true,
  String summary = '',
  List<String> changes = const [],
  int sellers = 2,
  int days = 3,
  int stockRisk = 0,
}) => BasketScenario(
  kind: kind,
  title: title,
  feasible: feasible,
  summary: summary,
  changes: changes,
  lines: const [],
  subtotal: Money(amount: total, currency: 'NPR'),
  tax: const Money(amount: 0, currency: 'NPR'),
  grandTotal: Money(amount: total, currency: 'NPR'),
  difference: Money(amount: difference, currency: 'NPR'),
  sellerCount: sellers,
  dispatchDays: days,
  itemsAtStockRisk: stockRisk,
);

final BasketScenario _asItIs = _scenario(
  kind: BasketScenarioKind.asItIs,
  title: 'Your cart as it is',
  summary: 'Everything you picked, unchanged.',
  total: 7006,
  difference: 0,
);

final BasketScenario _withinBudget = _scenario(
  kind: BasketScenarioKind.withinBudget,
  title: 'Within your budget',
  feasible: false,
  summary: 'The items you keep already cost more than your budget.',
  total: 7119,
  difference: 113,
);

final BasketScenario _lowerCost = _scenario(
  kind: BasketScenarioKind.lowerCost,
  title: 'Lower cost',
  summary: 'A similar shirt from another seller.',
  changes: ['Linen shirt swapped for Cotton shirt'],
  total: 5876,
  difference: -1130,
  sellers: 1,
  days: 1,
  stockRisk: 1,
);

final BasketScenarios _result = BasketScenarios(
  currency: 'NPR',
  scenarios: [_asItIs, _withinBudget, _lowerCost],
);

BasketScenarios? _successOf(BasketScenariosState state) =>
    state.maybeWhen(loadSuccess: (r) => r, orElse: () => null);

void main() {
  late _MockCartRepository repository;

  /// Each getScenarios call as `[budget, keepLineIds]`, in call order.
  late List<List<Object?>> sent;

  setUpAll(() => registerFallbackValue(<String>[]));

  setUp(() {
    repository = _MockCartRepository();
    sent = [];
    when(() => repository.getCart()).thenAnswer((_) async => right(_cart));
  });

  void answerScenarios(
    Future<_ScenariosResult> Function(double? budget) reply,
  ) {
    when(
      () => repository.getScenarios(
        budget: any(named: 'budget'),
        keepLineIds: any(named: 'keepLineIds'),
      ),
    ).thenAnswer((invocation) {
      final budget = invocation.namedArguments[#budget] as double?;
      sent.add([budget, invocation.namedArguments[#keepLineIds]]);
      return reply(budget);
    });
  }

  group('BasketScenariosNotifier', () {
    test('loads once with no budget and nothing kept on creation', () async {
      answerScenarios((_) async => right(_result));

      final notifier = BasketScenariosNotifier(repository);
      addTearDown(notifier.dispose);
      await pumpEventQueue();

      expect(_successOf(notifier.state), same(_result));
      expect(sent, [
        [null, isEmpty],
      ]);
    });

    test('moves to loadFailure on a repository error', () async {
      answerScenarios(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      final notifier = BasketScenariosNotifier(repository);
      addTearDown(notifier.dispose);
      await pumpEventQueue();

      expect(
        notifier.state,
        const BasketScenariosState.loadFailure(
          NetworkExceptions.serverUnavailable(),
        ),
      );
    });

    test('load forwards the budget and the lines to keep', () async {
      answerScenarios((_) async => right(_result));

      final notifier = BasketScenariosNotifier(repository);
      addTearDown(notifier.dispose);
      await notifier.load(budget: 4500, keepLineIds: ['line-2']);

      expect(notifier.state, BasketScenariosState.loadSuccess(_result));
      expect(sent, [
        [null, isEmpty],
        [
          4500.0,
          ['line-2'],
        ],
      ]);
    });

    test('a late reply to an earlier request is discarded', () async {
      final firstReply = Completer<_ScenariosResult>();
      final budgeted = BasketScenarios(
        currency: 'NPR',
        budget: 4500,
        scenarios: [_lowerCost],
      );
      answerScenarios(
        (budget) => budget == null
            ? firstReply.future
            : Future.value(right<NetworkExceptions, BasketScenarios>(budgeted)),
      );

      final notifier = BasketScenariosNotifier(repository); // first pending
      addTearDown(notifier.dispose);
      await notifier.load(budget: 4500);
      firstReply.complete(right(_result));
      await pumpEventQueue();

      expect(_successOf(notifier.state), same(budgeted));
    });
  });

  group('budgetErrorOf', () {
    test('uses the message of a 400 on budget', () {
      expect(
        budgetErrorOf(
          const NetworkExceptions.validation(
            code: 'validation.invalid',
            message: 'Budget is too small for this cart.',
            field: 'budget',
          ),
        ),
        'Budget is too small for this cart.',
      );
    });

    test('reads a budget entry in errors[]', () {
      expect(
        budgetErrorOf(
          const NetworkExceptions.validation(
            code: 'validation.multiple_errors',
            errors: [
              FieldErrorVm(
                field: 'Budget',
                code: 'validation.out_of_range',
                message: 'Enter a budget above zero.',
              ),
            ],
          ),
        ),
        'Enter a budget above zero.',
      );
    });

    test('falls back to plain wording when the message is empty', () {
      expect(
        budgetErrorOf(
          const NetworkExceptions.validation(
            code: 'validation.invalid',
            field: 'budget',
          ),
        ),
        budgetAboveZeroMessage,
      );
    });

    test('is null for failures that are not about the budget', () {
      expect(
        budgetErrorOf(
          const NetworkExceptions.validation(
            code: 'validation.out_of_range',
            message: 'Too many exclusions.',
            field: 'excludedProductIds',
          ),
        ),
        isNull,
      );
      expect(
        budgetErrorOf(const NetworkExceptions.serverUnavailable()),
        isNull,
      );
    });
  });

  group('CartScenariosScreen', () {
    const budgetField = ValueKey('scenario-budget-field');

    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [cartRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: CartScenariosScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Finder dimmingOf(String text) =>
        find.ancestor(of: find.text(text), matching: find.byType(Opacity));

    testWidgets('loads once on open and shows each basket with its facts', (
      tester,
    ) async {
      answerScenarios((_) async => right(_result));

      await pumpScreen(tester);

      expect(
        find.textContaining(
          'Nothing changes in your cart until you do it yourself.',
        ),
        findsOneWidget,
      );
      expect(find.text('Your budget (Rs)'), findsOneWidget);
      expect(find.text('Must keep'), findsOneWidget);
      expect(find.byKey(const ValueKey('keep-line-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('keep-line-2')), findsOneWidget);

      expect(find.text('Your cart as it is'), findsOneWidget);
      expect(find.text('Rs 7,006.00'), findsOneWidget);
      expect(find.text('Same as your cart now'), findsOneWidget);

      expect(find.text('Lower cost'), findsOneWidget);
      expect(find.text('Rs 5,876.00'), findsOneWidget);
      expect(find.text('Rs 1,130.00 less'), findsOneWidget);
      expect(find.text('Rs 113.00 more'), findsOneWidget);

      expect(find.text('Ready to ship in 3 days'), findsNWidgets(2));
      expect(find.text('Ready to ship in 1 day'), findsOneWidget);
      expect(find.text('2 sellers'), findsNWidgets(2));
      expect(find.text('1 seller'), findsOneWidget);
      expect(find.text('1 item may not have enough stock'), findsOneWidget);
      expect(find.text('Linen shirt swapped for Cotton shirt'), findsOneWidget);

      // Read-only: the only button is "Show options".
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Show options'), findsOneWidget);
      expect(sent, [
        [null, isEmpty],
      ]);
    });

    testWidgets('an infeasible basket is muted and says so', (tester) async {
      answerScenarios((_) async => right(_result));

      await pumpScreen(tester);

      expect(dimmingOf('Within your budget'), findsOneWidget);
      expect(
        tester.widget<Opacity>(dimmingOf('Within your budget')).opacity,
        0.55,
      );
      expect(find.text('Not possible'), findsOneWidget);
      expect(dimmingOf('Lower cost'), findsNothing);
      expect(dimmingOf('Your cart as it is'), findsNothing);
    });

    testWidgets('Show options sends the budget and the lines to keep', (
      tester,
    ) async {
      answerScenarios((_) async => right(_result));

      await pumpScreen(tester);
      await tester.enterText(find.byKey(budgetField), '4,500');
      await tester.tap(find.byKey(const ValueKey('keep-line-2')));
      await tester.pump();
      await tester.tap(find.text('Show options'));
      await tester.pumpAndSettle();

      expect(sent, [
        [null, isEmpty],
        [
          4500.0,
          ['line-2'],
        ],
      ]);
    });

    testWidgets('a budget of zero is flagged without asking again', (
      tester,
    ) async {
      answerScenarios((_) async => right(_result));

      await pumpScreen(tester);
      await tester.enterText(find.byKey(budgetField), '0');
      await tester.tap(find.text('Show options'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a budget above zero.'), findsOneWidget);
      expect(sent, [
        [null, isEmpty],
      ]);
    });

    testWidgets('a budget the server rejects is shown on the field', (
      tester,
    ) async {
      answerScenarios(
        (budget) async => budget == null
            ? right<NetworkExceptions, BasketScenarios>(_result)
            : left<NetworkExceptions, BasketScenarios>(
                const NetworkExceptions.validation(
                  code: 'validation.invalid',
                  message: 'Budget is too small for this cart.',
                  field: 'budget',
                ),
              ),
      );

      await pumpScreen(tester);
      await tester.enterText(find.byKey(budgetField), '100');
      await tester.tap(find.text('Show options'));
      await tester.pumpAndSettle();

      expect(find.text('Budget is too small for this cart.'), findsOneWidget);
      expect(find.text('Lower cost'), findsNothing);
      expect(
        find.text('Could not build other baskets right now.'),
        findsNothing,
      );
    });

    testWidgets('a failed load offers a retry', (tester) async {
      answerScenarios(
        (_) async => left(const NetworkExceptions.serverUnavailable()),
      );

      await pumpScreen(tester);
      expect(
        find.text('Could not build other baskets right now.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(sent, [
        [null, isEmpty],
        [null, isEmpty],
      ]);
    });
  });

  group('scenario labels', () {
    test('difference against the cart as it is now', () {
      expect(
        scenarioDifferenceLabel(const Money(amount: -1130, currency: 'NPR')),
        'Rs 1,130.00 less',
      );
      expect(
        scenarioDifferenceLabel(const Money(amount: 113, currency: 'NPR')),
        'Rs 113.00 more',
      );
      expect(
        scenarioDifferenceLabel(const Money(amount: 0.001, currency: 'NPR')),
        'Same as your cart now',
      );
    });

    test('dispatch, sellers and stock risk read naturally', () {
      expect(readyToShipLabel(0), 'Ready to ship today');
      expect(readyToShipLabel(1), 'Ready to ship in 1 day');
      expect(readyToShipLabel(4), 'Ready to ship in 4 days');
      expect(sellerCountLabel(1), '1 seller');
      expect(sellerCountLabel(3), '3 sellers');
      expect(stockRiskLabel(1), '1 item may not have enough stock');
      expect(stockRiskLabel(2), '2 items may not have enough stock');
    });
  });
}
