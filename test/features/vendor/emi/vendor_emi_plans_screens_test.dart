import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/data/models/vendor_emi_plan_json.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/domain/entities/vendor_emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/screens/vendor_emi_plan_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/screens/vendor_emi_plans_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_emi_plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_emi_plans_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_order_plan_progress.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_payment_plan_json.dart';

import 'vendor_emi_plan_fixtures.dart';

void _tallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 6000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps [screen] at `/` with a router that also answers the places it can
/// go: the plan detail and the vendor order.
Future<void> _pump(
  WidgetTester tester,
  MockVendorEmiRepository repo,
  Widget screen,
) async {
  _tallPhone(tester);
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => screen),
      GoRoute(
        path: '/vendor/emi-plans/:agreementId',
        builder: (_, state) =>
            Text('plan page ${state.pathParameters['agreementId']}'),
      ),
      GoRoute(
        path: '/vendor/orders/:orderId',
        builder: (_, state) =>
            Text('order page ${state.pathParameters['orderId']}'),
      ),
      GoRoute(
        path: '/vendor/emi-plans',
        builder: (_, _) => const Text('plans page'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vendorEmiRepositoryProvider.overrideWithValue(repo),
        vendorEmiTodayProvider.overrideWithValue(planToday),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await _settle(tester);
}

void main() {
  group('reading the plans payload', () {
    test('carries the contract v1 figures', () {
      final plan = readVendorEmiPlan(vendorPlanWire());
      expect(plan.buyerDisplayName, 'Sarah P.');
      expect(plan.productName, 'Leather jacket');
      expect(plan.orderNumber, 'NK2026-00101');
      expect(plan.vendorSubOrderId, planSubOrderId);
      expect(plan.downPaymentStatus, VendorDownPaymentStatus.paidOnline);
      expect(plan.collected.amount, 28000);
      expect(plan.remaining.amount, 32500);
      expect(plan.financed.amount, 48000);
      expect(plan.monthlyInstalment.amount, 16000);
      expect(plan.lateFeesOutstanding.amount, 500);
      expect(plan.nextInstalment?.number, 2);
      expect(plan.isOverdue, isTrue);
    });

    test('works the figures out from the schedule before the deploy', () {
      final plan = readVendorEmiPlan(vendorPlanWire(withNewFields: false));
      // The started plan's down payment plus the one paid instalment.
      expect(plan.collected.amount, 12000 + 16000);
      expect(plan.nextInstalment?.number, 2);
      expect(plan.lateFeesOutstanding.amount, 500);
      expect(plan.orderNumber, isNull);
      expect(plan.downPaymentStatus, VendorDownPaymentStatus.paidOnline);
    });

    test('skips an unreadable row rather than losing the list', () {
      final plans = readVendorEmiPlans([
        vendorPlanWire(),
        {'agreement': 'nonsense'},
        {'buyerDisplayName': 'no agreement'},
      ]);
      expect(plans, hasLength(1));
      expect(readVendorEmiPlans({'items': threePlansWire()}), hasLength(3));
    });

    test('filters and instalment standings follow the Kathmandu calendar', () {
      final plans = threePlans();
      List<String> ids(VendorEmiPlanFilter f) => [
        for (final p in plans)
          if (f.matches(p, planToday)) p.id,
      ];
      expect(ids(VendorEmiPlanFilter.active), [overduePlanId, dueSoonPlanId]);
      expect(ids(VendorEmiPlanFilter.overdue), [overduePlanId]);
      expect(ids(VendorEmiPlanFilter.dueSoon), [dueSoonPlanId]);
      expect(ids(VendorEmiPlanFilter.completed), [completedPlanId]);

      final schedule = plans[1].agreement.instalments;
      expect(
        instalmentStanding(schedule[0], planToday),
        VendorInstalmentStanding.dueSoon,
      );
      expect(
        instalmentStanding(schedule[1], planToday),
        VendorInstalmentStanding.upcoming,
      );
      expect(
        instalmentStanding(schedule[0], DateTime(2026, 10, 18)),
        VendorInstalmentStanding.dueToday,
      );
      expect(
        kathmanduToday(DateTime.utc(2026, 10, 16, 18, 30)),
        DateTime(2026, 10, 17),
        reason: '18:30 UTC is already the next day in Kathmandu',
      );
    });

    test('the order payment plan names its agreement', () {
      final plan = readVendorOrderPaymentPlan({
        'agreementId': overduePlanId,
        'kind': 'Instalment',
        'priceAmount': 60000,
        'currency': 'NPR',
      })!;
      expect(plan.agreementId, overduePlanId);
      final unnamed = readVendorOrderPaymentPlan({'kind': 'Instalment'})!;
      expect(unnamed.agreementId, isNull);
    });
  });

  group('EMI plans list', () {
    testWidgets('shows each running plan with its collections', (
      tester,
    ) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo);
      await _pump(tester, repo, const VendorEmiPlansScreen());

      // Active by default: the overdue plan and the one due soon.
      expect(find.text('Sarah P.'), findsOneWidget);
      expect(find.text('Ram K.'), findsOneWidget);
      expect(find.text('Mina T.'), findsNothing);
      expect(find.text('Leather jacket'), findsOneWidget);
      expect(find.text('Order NK2026-00101'), findsOneWidget);
      expect(find.text('Financed'), findsNWidgets(2));
      expect(find.text('Rs 28,000'), findsOneWidget, reason: 'collected');
      expect(find.text('Rs 32,500'), findsOneWidget, reason: 'remaining');
      expect(find.text('Overdue'), findsOneWidget);
      expect(
        find.text('Next due: Rs 16,500 on Oct 10, 2026'),
        findsOneWidget,
      );
      expect(
        find.text('Next due: Rs 16,000 on Oct 18, 2026'),
        findsOneWidget,
      );
      // A display name only: nothing that looks like a phone or an email.
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('+977'), findsNothing);
    });

    testWidgets('filters to overdue, due soon and completed', (tester) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo);
      await _pump(tester, repo, const VendorEmiPlansScreen());

      Finder chip(String name) =>
          find.byKey(Key('vendor-emi-plans-filter-$name'));

      await _tap(tester, chip('overdue'));
      expect(find.text('Sarah P.'), findsOneWidget);
      expect(find.text('Ram K.'), findsNothing);

      await _tap(tester, chip('dueSoon'));
      expect(find.text('Ram K.'), findsOneWidget);
      expect(find.text('Sarah P.'), findsNothing);

      await _tap(tester, chip('completed'));
      expect(find.text('Mina T.'), findsOneWidget);
      expect(find.text('Paid off'), findsWidgets);
      expect(find.text('Overdue (1)'), findsOneWidget);
    });

    testWidgets('a tile opens the plan', (tester) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo);
      await _pump(tester, repo, const VendorEmiPlansScreen());

      await _tap(
        tester,
        find.byKey(const Key('vendor-emi-plan-tile-$overduePlanId')),
      );
      expect(find.text('plan page $overduePlanId'), findsOneWidget);
    });

    testWidgets('says it is being set up while the endpoint is 404', (
      tester,
    ) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo, failure: notFound);
      await _pump(tester, repo, const VendorEmiPlansScreen());

      expect(find.byKey(VendorEmiPlansSettingUp.viewKey), findsOneWidget);
      expect(find.text('EMI plan tracking is being set up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('EMI plan detail', () {
    testWidgets('shows the terms, the collections and the full schedule', (
      tester,
    ) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo);
      await _pump(
        tester,
        repo,
        const VendorEmiPlanDetailScreen(agreementId: overduePlanId),
      );

      expect(find.text('Leather jacket'), findsOneWidget);
      expect(find.text('Buyer: Sarah P.'), findsOneWidget);
      expect(find.text('Rs 12,000 · Paid online'), findsOneWidget);
      expect(find.text('Rs 48,000'), findsOneWidget, reason: 'financed');
      expect(find.text('3 months'), findsOneWidget);
      expect(find.text('Rs 16,000'), findsWidgets, reason: 'monthly');
      expect(find.text('Rs 28,000'), findsOneWidget, reason: 'collected');
      expect(find.text('Rs 32,500'), findsOneWidget, reason: 'remaining');
      expect(find.text('Rs 500'), findsOneWidget, reason: 'late fees unpaid');

      expect(find.text('Payment 1 · Sep 10, 2026'), findsOneWidget);
      expect(find.text('Payment 2 · Oct 10, 2026'), findsOneWidget);
      expect(find.text('Payment 3 · Nov 10, 2026'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('incl. Rs 500 late fee'), findsOneWidget);
    });

    testWidgets('links to the seller\'s order', (tester) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo);
      await _pump(
        tester,
        repo,
        const VendorEmiPlanDetailScreen(agreementId: overduePlanId),
      );

      expect(find.text('Order NK2026-00101'), findsOneWidget);
      await _tap(tester, find.byKey(VendorEmiPlanDetailScreen.orderLinkKey));
      expect(find.text('order page $planSubOrderId'), findsOneWidget);
    });

    testWidgets('a cash down payment still to collect says so', (
      tester,
    ) async {
      final repo = MockVendorEmiRepository();
      stubPlans(
        repo,
        plans: [
          readVendorEmiPlan(
            vendorPlanWire(downPaymentStatus: 'collect_on_delivery'),
          ),
        ],
      );
      await _pump(
        tester,
        repo,
        const VendorEmiPlanDetailScreen(agreementId: overduePlanId),
      );
      expect(find.text('Rs 12,000 · Rider collects in cash'), findsOneWidget);
    });

    testWidgets('says it is being set up while the endpoint is 404', (
      tester,
    ) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo, failure: notFound);
      await _pump(
        tester,
        repo,
        const VendorEmiPlanDetailScreen(agreementId: overduePlanId),
      );
      expect(find.byKey(VendorEmiPlansSettingUp.viewKey), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('order Payment card progress', () {
    testWidgets('collected, remaining, next due and the plan link', (
      tester,
    ) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo);
      await _pump(
        tester,
        repo,
        const Scaffold(
          body: VendorOrderPlanProgress(agreementId: overduePlanId),
        ),
      );

      expect(find.text('Collected so far'), findsOneWidget);
      expect(find.text('Rs 28,000'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('Rs 32,500'), findsOneWidget);
      expect(find.text('Rs 16,500 on Oct 10, 2026'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);

      await _tap(tester, find.byKey(VendorOrderPlanProgress.linkKey));
      expect(find.text('plan page $overduePlanId'), findsOneWidget);
    });

    testWidgets('draws nothing while the plan cannot be read', (
      tester,
    ) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo, failure: notFound);
      await _pump(
        tester,
        repo,
        const Scaffold(
          body: VendorOrderPlanProgress(agreementId: overduePlanId),
        ),
      );
      expect(find.byKey(VendorOrderPlanProgress.sectionKey), findsNothing);
      expect(find.text('Collected so far'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('EMI plans card on the EMI page', () {
    testWidgets('counts running, overdue and due soon, and opens the list', (
      tester,
    ) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo);
      await _pump(tester, repo, const Scaffold(body: VendorEmiPlansCard()));

      expect(
        find.text('EMI plans · 2 running · 1 overdue · 1 due soon'),
        findsOneWidget,
      );
      expect(find.text('Rs 100,000 collected so far'), findsOneWidget);
      await _tap(tester, find.byKey(VendorEmiPlansCard.cardKey));
      expect(find.text('plans page'), findsOneWidget);
    });

    testWidgets('is hidden while the endpoint is 404', (tester) async {
      final repo = MockVendorEmiRepository();
      stubPlans(repo, failure: notFound);
      await _pump(tester, repo, const Scaffold(body: VendorEmiPlansCard()));
      expect(find.byKey(VendorEmiPlansCard.cardKey), findsNothing);
    });
  });
}
