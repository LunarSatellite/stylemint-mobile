import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/payment_plan_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/payment_plans_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_progress_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';

import 'credit_fakes.dart';

/// EMI after delivery, as the buyer sees it (contract v1): the order's
/// "Payment plan" card, the plan's progress and schedule, the due banner,
/// and the fallbacks for a server that does not send the new fields yet.

const _planId = 'f90a6410-3076-4791-84cf-fa5c77f25a4c';

/// 12 Nov 2026, midday in Kathmandu.
final _now = DateTime.utc(2026, 11, 12, 6);
final _today = DateTime(2026, 11, 12);

Map<String, dynamic> _line(
  int n, {
  required String due,
  int state = 1,
  double lateFee = 0,
}) => {
  'number': n,
  'dueDate': due,
  'scheduledAmount': 16000,
  'principalDue': 16000,
  'interestDue': 0,
  'lateFeeDue': lateFee,
  'paid': state == 3 ? 16000 : 0,
  'outstanding': state == 3 ? 0 : 16000 + lateFee,
  'state': state,
  'paidUtc': state == 3 ? '2026-10-14T05:00:00+00:00' : null,
};

/// A delivered EMI: one instalment paid, the next due in 2 days, the last a
/// month later. [extra] lays the contract's new fields (or anything) on top.
Map<String, dynamic> _runningPlan({
  int secondState = 1,
  String secondDue = '2026-11-14',
  double lateFee = 0,
  Map<String, dynamic> extra = const {},
}) => {
  ...agreementWire(
    state: 3,
    needsActivationPayment: false,
    outstanding: 32000 + lateFee,
    payoff: 32000,
    instalments: [
      _line(1, due: '2026-10-14', state: 3),
      _line(2, due: secondDue, state: secondState, lateFee: lateFee),
      _line(3, due: '2026-12-14'),
    ],
  ),
  'activatedUtc': '2026-09-14T05:00:00+00:00',
  'deliveredUtc': '2026-09-20T05:00:00+00:00',
  ...extra,
};

class _FailingCreditRepository extends FakeCreditRepository {
  @override
  Future<Either<EmiFailure, List<CreditAgreement>>> listAgreements() async =>
      left(const EmiFailure(EmiFailureKind.notFound));

  @override
  Future<Either<EmiFailure, CreditAgreement>> getAgreement(String id) async =>
      left(const EmiFailure(EmiFailureKind.notFound));
}

/// Counts reads, to show an order paid outright looks nothing up.
class _CountingCreditRepository extends FakeCreditRepository {
  _CountingCreditRepository({super.agreement});

  int reads = 0;

  @override
  Future<Either<EmiFailure, List<CreditAgreement>>> listAgreements() {
    reads++;
    return super.listAgreements();
  }

  @override
  Future<Either<EmiFailure, CreditAgreement>> getAgreement(String id) {
    reads++;
    return super.getAgreement(id);
  }
}

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
}

/// [home] at `/`, with the plan screens' real routes behind it.
Future<GoRouter> _pump(
  WidgetTester tester, {
  required FakeCreditRepository repo,
  Widget home = const SizedBox.shrink(),
  String initialLocation = '/',
}) async {
  _phoneSize(tester);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: SingleChildScrollView(child: home)),
      ),
      GoRoute(
        path: RouteNames.paymentPlans,
        builder: (_, _) => const PaymentPlansScreen(),
      ),
      GoRoute(
        path: RouteNames.paymentPlanDetail,
        builder: (_, state) => PaymentPlanDetailScreen(
          agreementId: state.pathParameters['agreementId']!,
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        creditRepositoryProvider.overrideWithValue(repo),
        planClockProvider.overrideWithValue(() => _now),
        planProductNameProvider.overrideWith(
          (ref, productId) async => 'Pashmina overcoat',
        ),
        creditProfileProvider.overrideWith(
          (ref) async => throw const EmiLoadException(
            EmiFailure(EmiFailureKind.notFound),
          ),
        ),
        planPaymentLauncherProvider.overrideWithValue((uri) async {}),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
  return router;
}

Finder _rowWith(String key, String text) => find.descendant(
  of: find.byKey(Key(key)),
  matching: find.textContaining(text),
);

void main() {
  group('reading a plan (contract v1)', () {
    test("the server's own counts win when sent", () {
      final a = readCreditAgreement(
        _runningPlan(
          extra: {
            'paidToDate': 30000,
            'instalmentsPaid': 1,
            'instalmentsRemaining': 2,
            'lateFeesOutstanding': 500,
            'lateFeeAmount': 500,
            'lateFeeGraceDays': 5,
            'nextInstalment': _line(2, due: '2026-11-15'),
          },
        ),
      );
      expect(a.paidToDate.amount, 30000);
      expect(a.instalmentsPaid, 1);
      expect(a.instalmentsRemaining, 2);
      expect(a.lateFeesOutstanding.amount, 500);
      expect(a.nextInstalment!.dueDate, DateTime(2026, 11, 15));
      expect(a.chargesLateFee, isTrue);
      expect(a.lateFeeGraceDays, 5);
      expect(a.deliveredAt, isNotNull);
    });

    test('an older server: counted from the schedule, never a crash', () {
      final a = readCreditAgreement(_runningPlan(lateFee: 500));
      // Down payment 12,000 + instalment 1's 16,000.
      expect(a.paidToDate.amount, 28000);
      expect(a.instalmentsPaid, 1);
      expect(a.instalmentsRemaining, 2);
      expect(a.nextInstalment!.number, 2);
      expect(a.lateFeesOutstanding.amount, 500);
      expect(a.chargesLateFee, isFalse);
    });

    test('a plan not yet started has paid nothing', () {
      final a = readCreditAgreement(agreementWire());
      expect(a.paidToDate.amount, 0);
      expect(a.instalmentsRemaining, 3);
    });
  });

  group('where an instalment stands, in Kathmandu', () {
    PlanInstalment line(String due, {int state = 1}) =>
        readCreditAgreement(
          _runningPlan(secondDue: due, secondState: state),
        ).instalments[1];

    test('today in Kathmandu, not on the device', () {
      // 20:00 UTC on 11 Nov is already 12 Nov in Kathmandu.
      expect(
        kathmanduToday(DateTime.utc(2026, 11, 11, 20)),
        DateTime(2026, 11, 12),
      );
    });

    test('paid, overdue, today, soon, upcoming, not started', () {
      expect(
        instalmentPhase(line('2026-11-01', state: 3), _today),
        InstalmentPhase.paid,
      );
      expect(
        instalmentPhase(line('2026-11-01', state: 4), _today),
        InstalmentPhase.overdue,
      );
      expect(
        instalmentPhase(line('2026-11-12'), _today),
        InstalmentPhase.dueToday,
      );
      expect(
        instalmentPhase(line('2026-11-15'), _today),
        InstalmentPhase.dueSoon,
      );
      expect(
        instalmentPhase(line('2026-11-16'), _today),
        InstalmentPhase.upcoming,
      );
      final unstarted = readCreditAgreement(agreementWire()).instalments.first;
      expect(instalmentPhase(unstarted, _today), InstalmentPhase.notStarted);
    });

    test('the alert: overdue first, then the soonest; nothing far off', () {
      final soon = readCreditAgreement(_runningPlan());
      final overdue = readCreditAgreement({
        ..._runningPlan(secondState: 4, secondDue: '2026-11-01'),
        'id': 'a2f0c1d2-0000-4000-8000-000000000002',
      });
      final far = readCreditAgreement(_runningPlan(secondDue: '2026-11-30'));

      expect(planDueAlert([far], _today), isNull);
      final first = planDueAlert([soon, overdue], _today)!;
      expect(first.isOverdue, isTrue);
      expect(first.agreement.id, overdue.id);

      final onlySoon = planDueAlert([soon, far], _today)!;
      expect(onlySoon.phase, InstalmentPhase.dueSoon);
      expect(onlySoon.daysUntil, 2);

      expect(
        planDueAlert([soon], _today, dismissed: {onlySoon.key}),
        isNull,
      );
      // A finished plan reminds nobody.
      expect(
        planDueAlert([readCreditAgreement(agreementWire(state: 4))], _today),
        isNull,
      );
    });
  });

  group('an order names its plan', () {
    Map<String, dynamic> order([Map<String, dynamic> extra = const {}]) => {
      'id': planOrderId,
      'orderNumber': 'NK2026-00101',
      'state': 2,
      'placedUtc': '2026-09-14T00:00:00Z',
      ...extra,
    };

    test('absent: not said; null: paid outright; an id: that plan', () {
      expect(
        OrderDetailDto.fromJson(order()).toDomain().creditAgreementId,
        isNull,
      );
      expect(
        OrderDetailDto.fromJson(
          order({'creditAgreementId': null}),
        ).toDomain().creditAgreementId,
        '',
      );
      expect(
        OrderDetailDto.fromJson(
          order({'creditAgreementId': _planId}),
        ).toDomain().creditAgreementId,
        _planId,
      );
    });
  });

  group("the order's Payment plan card", () {
    testWidgets('shows progress and opens the plan', (tester) async {
      final repo = FakeCreditRepository(agreement: _runningPlan());
      final router = await _pump(
        tester,
        repo: repo,
        home: const OrderPaymentPlanCard(
          orderId: planOrderId,
          creditAgreementId: _planId,
        ),
      );

      expect(find.byKey(const Key('order-payment-plan-card')), findsOneWidget);
      expect(find.text('Payment plan'), findsOneWidget);
      expect(_rowWith('plan-paid-so-far', '28,000'), findsOneWidget);
      expect(_rowWith('plan-remaining', '32,000'), findsOneWidget);
      expect(_rowWith('plan-next-instalment', '16,000'), findsOneWidget);
      expect(_rowWith('plan-next-instalment', 'Nov 14, 2026'), findsOneWidget);
      expect(_rowWith('plan-instalments-left', '2 of 3'), findsOneWidget);
      expect(find.byKey(const Key('order-plan-overdue')), findsNothing);

      await tester.tap(find.byKey(const Key('order-plan-open')));
      await _settle(tester);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        RouteNames.paymentPlanDetailPath(_planId),
      );
    });

    testWidgets('an overdue plan carries the badge', (tester) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(
          agreement: _runningPlan(secondState: 4, secondDue: '2026-11-01'),
        ),
        home: const OrderPaymentPlanCard(
          orderId: planOrderId,
          creditAgreementId: _planId,
        ),
      );
      expect(find.byKey(const Key('order-plan-overdue')), findsOneWidget);
      expect(find.text('Overdue instalment'), findsOneWidget);
    });

    testWidgets('an older server: found by the order id', (tester) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(agreement: _runningPlan()),
        home: const OrderPaymentPlanCard(orderId: planOrderId),
      );
      expect(find.byKey(const Key('order-payment-plan-card')), findsOneWidget);
    });

    testWidgets('another order: no card', (tester) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(agreement: _runningPlan()),
        home: const OrderPaymentPlanCard(
          orderId: '00000000-0000-4000-8000-000000000000',
        ),
      );
      expect(find.byKey(const Key('order-payment-plan-card')), findsNothing);
    });

    testWidgets('paid outright: no card, nothing looked up', (tester) async {
      final repo = _CountingCreditRepository(agreement: _runningPlan());
      await _pump(
        tester,
        repo: repo,
        home: const OrderPaymentPlanCard(
          orderId: planOrderId,
          creditAgreementId: '',
        ),
      );
      expect(find.byKey(const Key('order-payment-plan-card')), findsNothing);
      expect(repo.reads, 0);
    });

    testWidgets('a plan that cannot be read: no card, no error', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: _FailingCreditRepository(),
        home: const OrderPaymentPlanCard(
          orderId: planOrderId,
          creditAgreementId: _planId,
        ),
      );
      expect(find.byKey(const Key('order-payment-plan-card')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('the plan screen', () {
    testWidgets('balance, full schedule, late fees and Pay now', (
      tester,
    ) async {
      final repo = FakeCreditRepository(
        agreement: _runningPlan(
          extra: {'lateFeeAmount': 500, 'lateFeeGraceDays': 5},
        ),
      );
      await _pump(
        tester,
        repo: repo,
        initialLocation: RouteNames.paymentPlanDetailPath(_planId),
      );

      await _reveal(tester, find.byKey(const Key('plan-remaining')));
      expect(_rowWith('plan-remaining', '32,000'), findsOneWidget);
      expect(_rowWith('plan-paid-so-far', '28,000'), findsOneWidget);
      expect(_rowWith('plan-instalments-left', '2 of 3'), findsOneWidget);

      await _reveal(tester, find.byKey(const Key('plan-instalment-note-3')));
      expect(
        find.descendant(
          of: find.byKey(const Key('plan-instalment-note-1')),
          matching: find.textContaining('Paid'),
        ),
        findsOneWidget,
      );
      expect(find.text('Due in 2 days'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);

      await _reveal(tester, find.byKey(const Key('plan-late-fee-terms')));
      expect(find.textContaining('more than 5 days'), findsOneWidget);

      final pay = find.byKey(const Key('plan-pay-primary'));
      await _reveal(tester, pay);
      expect(
        find.descendant(of: pay, matching: find.textContaining('Pay now')),
        findsOneWidget,
      );
      await tester.tap(pay);
      await _settle(tester);
      await tester.tap(find.byKey(const Key('plan-pay-confirm')));
      await _settle(tester);
      expect(repo.payments.single.purpose, PaymentPurpose.instalment);
    });

    testWidgets('an overdue instalment and its late fee', (tester) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(
          agreement: _runningPlan(
            secondState: 4,
            secondDue: '2026-11-01',
            lateFee: 500,
          ),
        ),
        initialLocation: RouteNames.paymentPlanDetailPath(_planId),
      );
      await _reveal(tester, find.byKey(const Key('plan-late-fees')));
      expect(_rowWith('plan-late-fees', '500'), findsOneWidget);
      await _reveal(tester, find.byKey(const Key('plan-instalment-note-2')));
      expect(
        find.descendant(
          of: find.byKey(const Key('plan-instalment-note-2')),
          matching: find.text('Overdue'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('incl. Rs 500 late fee'), findsWidgets);
    });

    testWidgets('the list says what is left and what is next', (
      tester,
    ) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(agreement: _runningPlan()),
        initialLocation: RouteNames.paymentPlans,
      );
      expect(find.text('My EMI plans'), findsOneWidget);
      expect(find.textContaining('32,000 left'), findsOneWidget);
      // Due in 2 days: the banner on top of the list.
      expect(find.byKey(const Key('plan-due-banner')), findsOneWidget);
    });
  });

  group('the due banner', () {
    testWidgets('due in 2 days: says so and opens the plan', (tester) async {
      final router = await _pump(
        tester,
        repo: FakeCreditRepository(agreement: _runningPlan()),
        home: const PlanDueBanner(),
      );
      expect(find.text('Instalment due in 2 days'), findsOneWidget);
      expect(find.textContaining('16,000'), findsOneWidget);

      await tester.tap(find.byKey(const Key('plan-due-banner-title')));
      await _settle(tester);
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        RouteNames.paymentPlanDetailPath(_planId),
      );
    });

    testWidgets('overdue: says so', (tester) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(
          agreement: _runningPlan(secondState: 4, secondDue: '2026-11-01'),
        ),
        home: const PlanDueBanner(),
      );
      expect(find.text('Instalment overdue'), findsOneWidget);
    });

    testWidgets('due today', (tester) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(
          agreement: _runningPlan(secondDue: '2026-11-12'),
        ),
        home: const PlanDueBanner(),
      );
      expect(find.text('Instalment due today'), findsOneWidget);
    });

    testWidgets('nothing within 3 days: no banner', (tester) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(
          agreement: _runningPlan(secondDue: '2026-11-20'),
        ),
        home: const PlanDueBanner(),
      );
      expect(find.byKey(const Key('plan-due-banner')), findsNothing);
    });

    testWidgets('plans that cannot be read: no banner', (tester) async {
      await _pump(
        tester,
        repo: _FailingCreditRepository(),
        home: const PlanDueBanner(),
      );
      expect(find.byKey(const Key('plan-due-banner')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('closing it hides it', (tester) async {
      await _pump(
        tester,
        repo: FakeCreditRepository(agreement: _runningPlan()),
        home: const PlanDueBanner(),
      );
      await tester.tap(find.byKey(const Key('plan-due-banner-dismiss')));
      await tester.pump();
      expect(find.byKey(const Key('plan-due-banner')), findsNothing);
    });
  });
}
