import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/screens/vendor_payment_plan_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/emi/presentation/widgets/vendor_credit_program_card.dart';

import '../../customer/emi/credit_fakes.dart';

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _pump(
  WidgetTester tester,
  FakeCreditRepository repo,
  Widget screen,
) async {
  _phoneSize(tester);
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, _) => screen)],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        creditRepositoryProvider.overrideWithValue(repo),
        planProductNameProvider.overrideWith(
          (ref, productId) async => 'Pashmina overcoat',
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  group('a referral', () {
    Map<String, dynamic> referral({int guarantor = 1}) => agreementWire(
      state: 1,
      guarantor: guarantor,
      reasons: const ['band_too_low', 'manual_review_required'],
      needsActivationPayment: false,
    );

    testWidgets('says why StyleMint referred it, in the vendor\'s terms', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeCreditRepository(agreement: referral()),
        const VendorPaymentPlanDetailScreen(agreementId: 'a1'),
      );

      expect(find.text('Why this needs your decision'), findsOneWidget);
      expect(
        find.text('The buyer has little purchase history with StyleMint yet.'),
        findsOneWidget,
      );
      expect(
        find.text('Your EMI terms ask to review every request.'),
        findsOneWidget,
      );
    });

    testWidgets('approving sends the decision', (tester) async {
      final repo = FakeCreditRepository(agreement: referral());
      await _pump(
        tester,
        repo,
        const VendorPaymentPlanDetailScreen(agreementId: 'a1'),
      );

      await _tap(tester, find.byKey(const Key('vendor-plan-approve')));

      expect(repo.reviews.single.approve, isTrue);
      expect(repo.reviews.single.reasons, isEmpty);
    });

    testWidgets('declining needs a reason, and sends it', (tester) async {
      final repo = FakeCreditRepository(agreement: referral());
      await _pump(
        tester,
        repo,
        const VendorPaymentPlanDetailScreen(agreementId: 'a1'),
      );

      await _tap(tester, find.byKey(const Key('vendor-plan-decline')));
      final confirm = find.byKey(const Key('vendor-decline-confirm'));
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.tap(find.byKey(const Key('vendor-decline-out_of_stock')));
      await tester.pump();
      await tester.tap(confirm);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(repo.reviews.single.approve, isFalse);
      expect(repo.reviews.single.reasons, ['out_of_stock']);
    });

    testWidgets('a plan StyleMint guarantees is not the vendor\'s to decide', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeCreditRepository(agreement: referral(guarantor: 2)),
        const VendorPaymentPlanDetailScreen(agreementId: 'a1'),
      );

      expect(find.byKey(const Key('vendor-plan-approve')), findsNothing);
      expect(find.byKey(const Key('vendor-plan-decline')), findsNothing);
    });
  });

  group('the pay later and prepay settings', () {
    testWidgets('turning pay later on accepts today\'s fee, shown first', (
      tester,
    ) async {
      final repo = FakeCreditRepository();
      await _pump(
        tester,
        repo,
        const Scaffold(body: SingleChildScrollView(child: VendorCreditProgramCard())),
      );

      expect(find.textContaining('3% risk fee'), findsOneWidget);

      await _tap(tester, find.byKey(const Key('vendor-paylater-switch')));
      final save = find.byKey(const Key('vendor-program-save'));
      expect(
        tester.widget<FilledButton>(save).onPressed,
        isNull,
        reason: 'pay later needs at least one tenure',
      );
      await _tap(tester, find.text('3 months').first);
      await _tap(tester, save);

      final saved = repo.programs.single;
      expect(saved.payLaterEnabled, isTrue);
      expect(saved.payLaterTenures, [3]);
      expect(saved.payLaterAcceptedRiskFeePercent, 3);
      expect(saved.prepayEnabled, isTrue, reason: 'left as it was');
      expect(saved.prepayTenures, [3]);
    });
  });
}
