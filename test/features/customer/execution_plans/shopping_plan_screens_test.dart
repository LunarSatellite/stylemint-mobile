import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/data/datasources/execution_plans_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/domain/entities/commerce_execution_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/screens/shopping_plan_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/screens/shopping_plans_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/presentation/widgets/execution_plan_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/execution_plans/shared/providers.dart';

/// Answers every read with [plans]; every write is refused with [failure]
/// when one is set, and otherwise echoes the first plan back.
class _FakeDataSource implements ExecutionPlansDataSource {
  _FakeDataSource({this.plans = const <CommerceExecutionPlan>[], this.failure});

  List<CommerceExecutionPlan> plans;
  Object? failure;
  final List<String> calls = [];

  @override
  Future<List<CommerceExecutionPlan>> list() async {
    calls.add('list');
    if (failure is Object && plans.isEmpty && failure == 'read') {
      throw Exception('read failed');
    }
    return plans;
  }

  @override
  Future<CommerceExecutionPlan> get(String planId) async => plans.first;

  @override
  Future<CommerceExecutionPlan> compile({
    required String intent,
    required String currency,
    required int maximumItems,
    required String idempotencyKey,
    double? maximumSpend,
    DateTime? mustCompleteByUtc,
  }) async {
    calls.add('compile:$intent:$currency:$maximumItems:$maximumSpend');
    if (failure != null) throw Exception('refused');
    return plans.first;
  }

  @override
  Future<CommerceExecutionPlan> approvePlan({
    required String planId,
    required String idempotencyKey,
  }) async {
    calls.add('approvePlan:$planId');
    if (failure != null) throw Exception('refused');
    return plans.first;
  }

  @override
  Future<CommerceExecutionPlan> approveStep({
    required String planId,
    required String taskKey,
    required String idempotencyKey,
  }) async {
    calls.add('approveStep:$planId:$taskKey');
    if (failure != null) throw Exception('refused');
    return plans.first;
  }

  @override
  Future<CommerceExecutionPlan> cancel({
    required String planId,
    required String idempotencyKey,
  }) async {
    calls.add('cancel:$planId');
    if (failure != null) throw Exception('refused');
    return plans.first;
  }
}

/// A read that always throws, for the quiet load-failure path.
class _FailingDataSource extends _FakeDataSource {
  @override
  Future<List<CommerceExecutionPlan>> list() async {
    calls.add('list');
    throw Exception('read failed');
  }
}

ExecutionStep _step({
  required int sequence,
  required String taskKey,
  required String purpose,
  required ExecutionApproval approval,
  ExecutionStepStatus status = ExecutionStepStatus.pending,
  bool approvedOnWire = true,
  List<String> completionConditions = const <String>[],
  List<String> requiredProofs = const <String>[],
  DateTime? completedUtc,
}) => ExecutionStep(
  sequence: sequence,
  taskKey: taskKey,
  purpose: purpose,
  toolKey: 'tool.$taskKey',
  approval: approval,
  requiredProofs: requiredProofs,
  completionConditions: completionConditions,
  status: status,
  approvedOnWire: approvedOnWire,
  fallbackActivated: false,
  completedUtc: completedUtc,
);

/// The four steps the compiler actually emits.
List<ExecutionStep> _compiledSteps({
  ExecutionStepStatus status = ExecutionStepStatus.pending,
  bool placeOrderApproved = false,
  DateTime? completedUtc,
}) => <ExecutionStep>[
  _step(
    sequence: 1,
    taskKey: 'discover',
    purpose: 'Find evidence-backed candidates',
    approval: ExecutionApproval.none,
    status: status,
    completedUtc: completedUtc,
    completionConditions: const ['at_least_one_candidate'],
    requiredProofs: const ['candidateIds'],
  ),
  _step(
    sequence: 2,
    taskKey: 'compose_basket',
    purpose: 'Build a bounded basket',
    approval: ExecutionApproval.none,
    status: status,
    completedUtc: completedUtc,
    completionConditions: const ['within_budget'],
    requiredProofs: const ['lineItems'],
  ),
  _step(
    sequence: 3,
    taskKey: 'prepare_checkout',
    purpose: 'Reserve inventory and freeze payable terms',
    approval: ExecutionApproval.customerBeforeExecution,
    status: status,
    completedUtc: completedUtc,
    completionConditions: const [
      'inventory_reserved',
      'price_snapshot_frozen',
    ],
    requiredProofs: const ['inventoryHoldIds', 'priceSnapshot'],
  ),
  _step(
    sequence: 4,
    taskKey: 'place_order',
    purpose: 'Create the authoritative order',
    approval: ExecutionApproval.customerAtTask,
    approvedOnWire: placeOrderApproved,
    status: status,
    completedUtc: completedUtc,
    completionConditions: const ['authoritative_order_created'],
    requiredProofs: const ['paymentReceipt'],
  ),
];

CommerceExecutionPlan _plan({
  ExecutionPlanStatus status = ExecutionPlanStatus.awaitingCustomerApproval,
  DateTime? approvedUtc,
  List<ExecutionStep>? steps,
}) => CommerceExecutionPlan(
  id: 'plan-1',
  intent: 'A rain jacket and boots for a trek in November',
  status: status,
  steps: steps ?? _compiledSteps(),
  createdUtc: DateTime.utc(2026, 9, 19, 8),
  approvedUtc: approvedUtc,
);

/// Every word on screen, including the ones inside buttons.
List<String> _screenText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .where((s) => s.isNotEmpty)
    .toList(growable: false);

void main() {
  Future<_FakeDataSource> pumpList(
    WidgetTester tester, {
    _FakeDataSource? source,
    double textScale = 1,
  }) async {
    final ds = source ?? _FakeDataSource();
    tester.view.physicalSize = const Size(320, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          executionPlansDataSourceProvider.overrideWithValue(ds),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const ShoppingPlansScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ds;
  }

  Future<_FakeDataSource> pumpDetail(
    WidgetTester tester,
    CommerceExecutionPlan plan, {
    double textScale = 1,
  }) async {
    final ds = _FakeDataSource(plans: <CommerceExecutionPlan>[plan]);
    tester.view.physicalSize = const Size(320, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          executionPlansDataSourceProvider.overrideWithValue(ds),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const ShoppingPlanDetailScreen(planId: 'plan-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ds;
  }

  group('ShoppingPlansScreen', () {
    testWidgets('empty: it says so rather than drawing a placeholder row', (
      tester,
    ) async {
      await pumpList(tester);

      expect(find.byKey(const ValueKey('plans-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('plan-card-plan-1')), findsNothing);
    });

    testWidgets('loaded: a plan shows its own words and its status', (
      tester,
    ) async {
      await pumpList(
        tester,
        source: _FakeDataSource(plans: <CommerceExecutionPlan>[_plan()]),
      );

      expect(find.byKey(const ValueKey('plan-card-plan-1')), findsOneWidget);
      expect(
        find.text('A rain jacket and boots for a trek in November'),
        findsOneWidget,
      );
      expect(find.textContaining('Waiting on you'), findsWidgets);
    });

    testWidgets('failure: the read failure is quiet and says nothing loaded', (
      tester,
    ) async {
      await pumpList(tester, source: _FailingDataSource());

      expect(find.byKey(const ValueKey('plans-load-failed')), findsOneWidget);
    });

    testWidgets('a refused compile shows the backend reason, not an exception',
        (tester) async {
      final ds = await pumpList(
        tester,
        source: _FakeDataSource(
          plans: <CommerceExecutionPlan>[_plan()],
          failure: 'refused',
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('plan-intent-field')),
        'boots',
      );
      await tester.tap(find.byKey(const ValueKey('plan-compile-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('plan-action-failure-notice')),
        findsOneWidget,
      );
      expect(ds.calls, contains('compile:boots:NPR:5:null'));
    });

    testWidgets('an empty intent asks the backend nothing', (tester) async {
      final ds = await pumpList(tester);

      await tester.tap(find.byKey(const ValueKey('plan-compile-button')));
      await tester.pumpAndSettle();

      expect(ds.calls.where((c) => c.startsWith('compile')), isEmpty);
    });

    testWidgets('the boundary is on the screen before any plan is', (
      tester,
    ) async {
      await pumpList(tester);

      expect(
        find.byKey(const ValueKey('plan-boundary-notice')),
        findsOneWidget,
      );
    });

    testWidgets('320dp at 1.3x does not overflow', (tester) async {
      await pumpList(
        tester,
        source: _FakeDataSource(plans: <CommerceExecutionPlan>[_plan()]),
        textScale: 1.3,
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('ShoppingPlanDetailScreen', () {
    testWidgets('loaded: the four compiled steps are drawn in order', (
      tester,
    ) async {
      await pumpDetail(tester, _plan());

      for (final key in <String>[
        'discover',
        'compose_basket',
        'prepare_checkout',
        'place_order',
      ]) {
        expect(find.byKey(ValueKey('plan-step-$key')), findsOneWidget);
      }
    });

    testWidgets('a step that touches price, stock or money says so', (
      tester,
    ) async {
      await pumpDetail(tester, _plan());

      expect(
        find.byKey(const ValueKey('plan-step-commitment-prepare_checkout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('plan-step-commitment-place_order')),
        findsOneWidget,
      );
      // The two read-only steps carry no such warning.
      expect(
        find.byKey(const ValueKey('plan-step-commitment-discover')),
        findsNothing,
      );
    });

    testWidgets('no spending limit reads as absent, never as zero', (
      tester,
    ) async {
      await pumpDetail(tester, _plan());

      expect(
        find.text(ExecutionPlanCopy.noSpendLimit),
        findsOneWidget,
      );
      expect(find.textContaining('Rs 0'), findsNothing);
    });

    testWidgets('approving is one deliberate act behind a confirmation', (
      tester,
    ) async {
      final ds = await pumpDetail(tester, _plan());

      await tester.tap(find.byKey(const ValueKey('plan-approve-button')));
      await tester.pumpAndSettle();
      // Nothing has been sent yet: the sheet states what a go-ahead is.
      expect(ds.calls.where((c) => c.startsWith('approvePlan')), isEmpty);
      expect(
        find.textContaining('buys nothing, holds nothing and pays nothing'),
        findsWidgets,
      );

      await tester.tap(find.byKey(const ValueKey('plan-confirm-action')));
      await tester.pumpAndSettle();
      expect(ds.calls, contains('approvePlan:plan-1'));
    });

    testWidgets('a gated step offers its own go-ahead once the plan has one', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _plan(
          status: ExecutionPlanStatus.ready,
          approvedUtc: DateTime.utc(2026, 9, 19, 9),
        ),
      );

      expect(
        find.byKey(const ValueKey('plan-step-approve-place_order')),
        findsOneWidget,
      );
      // The steps with no separate gate offer no button at all.
      expect(
        find.byKey(const ValueKey('plan-step-approve-prepare_checkout')),
        findsNothing,
      );
    });

    testWidgets('an unapproved plan offers no per-step go-ahead', (
      tester,
    ) async {
      await pumpDetail(tester, _plan());

      expect(
        find.byKey(const ValueKey('plan-step-approve-place_order')),
        findsNothing,
      );
    });

    testWidgets('a plan that is not on the account says so', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            executionPlansDataSourceProvider.overrideWithValue(
              _FakeDataSource(),
            ),
          ],
          child: const MaterialApp(
            home: ShoppingPlanDetailScreen(planId: 'missing'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('plan-missing')), findsOneWidget);
    });

    testWidgets('320dp at 1.3x does not overflow', (tester) async {
      await pumpDetail(tester, _plan(), textScale: 1.3);

      expect(tester.takeException(), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // §5.9: "will not set prices, reserve stock or move money".
  // ───────────────────────────────────────────────────────────────────────
  group('no step can render as already executed', () {
    /// Words that would tell a shopper a price, a hold or a payment has
    /// happened. None of them may appear anywhere on a plan screen.
    const banned = <String>[
      'Reserved',
      'reserved for you',
      'Paid',
      'Bought',
      'Purchased',
      'Ordered',
      'Order placed',
      'Completed',
      'Done',
      'Executed',
      'Stock held',
      'Price locked',
      'Payment taken',
    ];

    testWidgets('in every status the backend can report', (tester) async {
      for (final status in <ExecutionStepStatus>[
        ExecutionStepStatus.pending,
        ExecutionStepStatus.inProgress,
        ExecutionStepStatus.completed,
        ExecutionStepStatus.failed,
        ExecutionStepStatus.skipped,
        ExecutionStepStatus.unrecognised,
      ]) {
        await pumpDetail(
          tester,
          _plan(
            status: ExecutionPlanStatus.inProgress,
            approvedUtc: DateTime.utc(2026, 9, 19, 9),
            steps: _compiledSteps(
              status: status,
              placeOrderApproved: true,
              completedUtc: status == ExecutionStepStatus.completed
                  ? DateTime.utc(2026, 9, 19, 10)
                  : null,
            ),
          ),
        );

        final text = _screenText(tester).join(' | ');
        for (final word in banned) {
          expect(
            text.contains(word),
            isFalse,
            reason:
                'step status $status rendered "$word", which claims a price, '
                'a hold or a payment happened',
          );
        }
      }
    });

    testWidgets('a recorded step says only that evidence exists', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _plan(
          status: ExecutionPlanStatus.inProgress,
          approvedUtc: DateTime.utc(2026, 9, 19, 9),
          steps: _compiledSteps(
            status: ExecutionStepStatus.completed,
            placeOrderApproved: true,
            completedUtc: DateTime.utc(2026, 9, 19, 10),
          ),
        ),
      );

      expect(find.textContaining('Evidence recorded'), findsWidgets);
    });

    testWidgets('a commitment the shopper never approved is not drawn at all',
        (tester) async {
      await pumpDetail(
        tester,
        _plan(
          status: ExecutionPlanStatus.inProgress,
          approvedUtc: DateTime.utc(2026, 9, 19, 9),
          steps: _compiledSteps(
            status: ExecutionStepStatus.completed,
            completedUtc: DateTime.utc(2026, 9, 19, 10),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('plan-refusal-notice')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('plan-step-place_order')), findsNothing);
      expect(
        find.byKey(const ValueKey('plan-approve-button')),
        findsNothing,
      );
    });

    testWidgets('evidence against a plan with no go-ahead is not drawn', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        _plan(
          status: ExecutionPlanStatus.inProgress,
          steps: _compiledSteps(
            status: ExecutionStepStatus.completed,
            placeOrderApproved: true,
            completedUtc: DateTime.utc(2026, 9, 19, 10),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('plan-refusal-notice')),
        findsOneWidget,
      );
    });

    test('no status label is a past-tense commitment', () {
      for (final status in ExecutionStepStatus.values) {
        final label = ExecutionPlanCopy.stepStatusLabel(status);
        for (final word in banned) {
          expect(
            label.toLowerCase().contains(word.toLowerCase()),
            isFalse,
            reason: '$status reads "$label"',
          );
        }
      }
    });
  });
}
