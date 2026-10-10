import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/product_emi_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/emi_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/payment_plan_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/plan_checkout_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/screens/plan_review_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/emi_calculator_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/emi_from_line.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/plan_widgets.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import 'credit_fakes.dart';

const _price = Money(amount: 60000, currency: 'NPR');
const _variant = 'f0a10cdf-15d7-4402-8774-9ac69f7aa421';
const _offer = ProductEmiOffer(
  minDownPaymentPercent: 20,
  tenures: [3, 6],
  variants: {_variant: EmiVariantTerms(price: _price, eligible: true)},
);

/// Phase 1's live check is not the subject here; it simply has no answer.
class _QuietEmiRepository implements EmiRepository {
  @override
  Future<Either<EmiFailure, EmiQuote>> getQuote({
    required String variantId,
    required int downPaymentPercent,
    required int tenureMonths,
  }) async => left(const EmiFailure(EmiFailureKind.unknown));

  @override
  Future<Either<EmiFailure, EmiEligibility>> getEligibility() async =>
      left(const EmiFailure(EmiFailureKind.unknown));
}

EmiEligibility _eligibility({required bool verified}) => EmiEligibility(
  kycTier: verified ? 2 : 0,
  kycStatus: verified ? KycStatus.approved : KycStatus.none,
  eligible: verified,
  reasons: verified ? const [] : const ['kyc_required'],
);

void _phoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// The app's real routes for payment plans, around [home].
Future<GoRouter> _pumpApp(
  WidgetTester tester, {
  required FakeCreditRepository repo,
  Widget home = const SizedBox.shrink(),
  String initialLocation = '/',
  bool verified = true,
  bool planOptionsFail = false,
  List<Uri>? launched,
}) async {
  _phoneSize(tester);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(body: home),
      ),
      GoRoute(
        path: RouteNames.paymentPlanReview,
        builder: (_, state) =>
            PlanReviewScreen(args: state.extra! as PlanReviewArgs),
      ),
      GoRoute(
        path: RouteNames.paymentPlanDetail,
        builder: (_, state) => PaymentPlanDetailScreen(
          agreementId: state.pathParameters['agreementId']!,
          args: state.extra is PlanDetailArgs
              ? state.extra! as PlanDetailArgs
              : const PlanDetailArgs(),
        ),
      ),
      GoRoute(
        path: RouteNames.paymentPlanCheckout,
        builder: (_, state) => PlanCheckoutScreen(
          agreementId: state.pathParameters['agreementId']!,
          args: state.extra is PlanDetailArgs
              ? state.extra! as PlanDetailArgs
              : const PlanDetailArgs(),
        ),
      ),
      GoRoute(
        path: RouteNames.customerKyc,
        builder: (_, _) => const Scaffold(body: Text('KYC screen')),
      ),
      GoRoute(
        path: RouteNames.shippingAddEdit,
        builder: (_, _) => const Scaffold(body: Text('Address form')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        creditRepositoryProvider.overrideWithValue(repo),
        emiRepositoryProvider.overrideWithValue(_QuietEmiRepository()),
        emiSignedInProvider.overrideWithValue(true),
        emiEligibilityProvider.overrideWith(
          (ref) async => _eligibility(verified: verified),
        ),
        planPaymentLauncherProvider.overrideWithValue(
          (uri) async => launched?.add(uri),
        ),
        planProductNameProvider.overrideWith(
          (ref, productId) async => 'Pashmina overcoat',
        ),
        if (planOptionsFail)
          planOptionsProvider.overrideWith(
            (ref, variantId) async => throw const EmiLoadException(
              EmiFailure(EmiFailureKind.notFound),
            ),
          ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return router;
}

/// A button that opens the sheet the way the product page does.
Widget _opener(List<PlanOption> options) => Builder(
  builder: (context) => Center(
    child: TextButton(
      onPressed: () => showEmiCalculatorSheet(
        context,
        productId: 'p1',
        productName: 'Pashmina overcoat',
        variantId: _variant,
        price: _price,
        offer: _offer,
        planOptions: options,
      ),
      child: const Text('open'),
    ),
  ),
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Scrolls the screen's list until [finder] is built and on screen. Lists
/// build lazily, so something below the fold is not in the tree until then.
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

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await _reveal(tester, finder);
  await tester.tap(finder);
  await _settle(tester);
}

List<PlanOption> get _menu => readPlanOptions(planOptionsWire).options;

void main() {
  group('the plan sheet', () {
    testWidgets('offers every plan the seller has, as chips', (tester) async {
      await _pumpApp(
        tester,
        repo: FakeCreditRepository(),
        home: _opener(_menu),
      );
      await tester.tap(find.text('open'));
      await _settle(tester);

      expect(find.text('Pay over time'), findsOneWidget);
      expect(find.byKey(const Key('plan-kind-instalment')), findsOneWidget);
      expect(find.byKey(const Key('plan-kind-prepay')), findsOneWidget);
      expect(find.byKey(const Key('plan-kind-payLater')), findsNothing);
    });

    testWidgets(
      'pay now, buy later needs no verification below the threshold, and '
      'says the item waits for the last payment',
      (tester) async {
        await _pumpApp(
          tester,
          repo: FakeCreditRepository(),
          home: _opener(_menu),
          verified: false,
        );
        await tester.tap(find.text('open'));
        await _settle(tester);

        // EMI lends, so an unverified buyer is sent to get verified.
        expect(find.text(EmiCtaButton.getVerifiedLabel), findsOneWidget);

        await _tapVisible(tester, find.byKey(const Key('plan-kind-prepay')));

        expect(find.text(EmiCtaButton.continueLabel), findsOneWidget);
        expect(
          find.text('Your item is delivered after the last payment.'),
          findsOneWidget,
        );
        expect(find.text('Deposit'), findsWidgets);
      },
    );

    testWidgets('Continue asks for a signed quote and opens its review', (
      tester,
    ) async {
      final repo = FakeCreditRepository();
      await _pumpApp(tester, repo: repo, home: _opener(_menu));
      await tester.tap(find.text('open'));
      await _settle(tester);

      await _tapVisible(tester, find.byKey(const Key('plan-continue')));

      expect(repo.quotes.single.kind, PlanKind.instalment);
      expect(repo.quotes.single.down, 20, reason: 'opens on the minimum');
      expect(repo.quotes.single.tenure, 6, reason: 'and the longest tenure');
      expect(find.text('Review your EMI plan'), findsOneWidget);
      expect(find.textContaining('16,000'), findsWidgets);
    });

    testWidgets('a refused quote is explained under the button', (
      tester,
    ) async {
      final repo = FakeCreditRepository(
        quoteFailure: const EmiFailure(
          EmiFailureKind.notFound,
          code: 'credit_offer.not_available',
        ),
      );
      await _pumpApp(tester, repo: repo, home: _opener(_menu));
      await tester.tap(find.text('open'));
      await _settle(tester);

      await _tapVisible(tester, find.byKey(const Key('plan-continue')));

      expect(find.byKey(const Key('plan-continue-error')), findsOneWidget);
      expect(
        find.text('This item can no longer be paid for this way.'),
        findsOneWidget,
      );
    });
  });

  group('the review', () {
    Future<FakeCreditRepository> openReview(
      WidgetTester tester, {
      FakeCreditRepository? repo,
    }) async {
      final r = repo ?? FakeCreditRepository();
      await _pumpApp(tester, repo: r, home: _opener(_menu));
      await tester.tap(find.text('open'));
      await _settle(tester);
      await _tapVisible(tester, find.byKey(const Key('plan-continue')));
      return r;
    }

    testWidgets('Apply waits for the buyer to agree, then sends the token', (
      tester,
    ) async {
      final repo = await openReview(tester);
      final apply = find.byKey(const Key('review-apply'));
      await _reveal(tester, apply);

      expect(tester.widget<FilledButton>(apply).onPressed, isNull);

      await _tapVisible(tester, find.byKey(const Key('review-agree')));
      await _tapVisible(tester, apply);

      expect(repo.applications.single.token, 'v1.payload.signature');
      expect(find.text('You are approved'), findsOneWidget);
      expect(find.byKey(const Key('plan-pay-primary')), findsOneWidget);
    });

    testWidgets('an expired quote cannot be applied for', (tester) async {
      await openReview(tester, repo: FakeCreditRepository(expiredQuote: true));
      await _reveal(tester, find.byKey(const Key('review-apply')));

      expect(
        find.text('This offer has expired. Go back and ask for a new one.'),
        findsOneWidget,
      );
      final apply = tester.widget<FilledButton>(
        find.byKey(const Key('review-apply')),
      );
      expect(apply.onPressed, isNull);
    });

    testWidgets('a stale quote is refused with a reason to ask again', (
      tester,
    ) async {
      await openReview(
        tester,
        repo: FakeCreditRepository(
          applyFailure: const EmiFailure(
            EmiFailureKind.rejected,
            code: 'credit_quote.stale',
          ),
        ),
      );
      await _tapVisible(tester, find.byKey(const Key('review-agree')));
      await _tapVisible(tester, find.byKey(const Key('review-apply')));

      expect(find.byKey(const Key('review-error')), findsOneWidget);
      expect(find.textContaining('ask for a new one'), findsWidgets);
    });

    testWidgets('a retried application reuses its idempotency key', (
      tester,
    ) async {
      final repo = await openReview(
        tester,
        repo: FakeCreditRepository(
          applyFailure: const EmiFailure(EmiFailureKind.offline),
        ),
      );
      await _tapVisible(tester, find.byKey(const Key('review-agree')));
      await _tapVisible(tester, find.byKey(const Key('review-apply')));
      repo.applyFailure = null;
      await _tapVisible(tester, find.byKey(const Key('review-apply')));

      expect(repo.applications, hasLength(2));
      expect(repo.applications[0].key, repo.applications[1].key);
    });
  });

  group('a plan', () {
    final launched = <Uri>[];
    setUp(launched.clear);

    Future<FakeCreditRepository> openPlan(
      WidgetTester tester,
      Map<String, dynamic> wire,
    ) async {
      final repo = FakeCreditRepository(agreement: wire);
      await _pumpApp(
        tester,
        repo: repo,
        initialLocation: RouteNames.paymentPlanDetailPath('plan-1'),
        launched: launched,
      );
      await _settle(tester);
      return repo;
    }

    testWidgets('an overdue plan leads with what is due, online only', (
      tester,
    ) async {
      final repo = await openPlan(tester, activeAgreementWire());

      expect(find.text('A payment is overdue'), findsOneWidget);
      expect(find.text('Pashmina overcoat'), findsOneWidget);
      final pay = find.byKey(const Key('plan-pay-primary'));
      expect(
        find.descendant(of: pay, matching: find.textContaining('16,000')),
        findsOneWidget,
        reason: 'what is already due, not the whole balance',
      );
      expect(find.byKey(const Key('plan-pay-off')), findsOneWidget);

      await _tapVisible(tester, pay);
      expect(find.text('Cash on Delivery'), findsNothing);
      await tester.tap(find.byKey(const Key('plan-rail-card')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('plan-pay-confirm')));
      await _settle(tester);

      expect(repo.payments.single.purpose, PaymentPurpose.instalment);
      expect(repo.payments.single.rail, PlanPaymentRail.card);
      expect(launched.single.toString(), 'https://pay.example.test/redirect');
      expect(find.byKey(const Key('plan-payment-started')), findsOneWidget);
    });

    testWidgets('a payment that cannot start keeps the sheet open', (
      tester,
    ) async {
      final repo = FakeCreditRepository(
        agreement: agreementWire(),
        paymentFailure: const EmiFailure(
          EmiFailureKind.server,
          code: 'credit_payment.unavailable',
        ),
      );
      await _pumpApp(
        tester,
        repo: repo,
        initialLocation: RouteNames.paymentPlanDetailPath('plan-1'),
      );
      await _settle(tester);

      await _tapVisible(tester, find.byKey(const Key('plan-pay-primary')));
      await tester.tap(find.byKey(const Key('plan-pay-confirm')));
      await _settle(tester);

      expect(repo.payments.single.purpose, PaymentPurpose.activation);
      expect(find.byKey(const Key('plan-pay-error')), findsOneWidget);
      expect(find.textContaining('Nothing has been charged'), findsOneWidget);
    });

    testWidgets('a declined plan says why, in words', (tester) async {
      await openPlan(
        tester,
        agreementWire(
          state: 6,
          reasons: const ['band_too_low', 'cooling_off'],
          needsActivationPayment: false,
        ),
      );

      expect(find.text('Not approved'), findsWidgets);
      expect(find.textContaining('enough history'), findsOneWidget);
      expect(find.textContaining('wait a few days'), findsOneWidget);
      expect(find.byKey(const Key('plan-pay-primary')), findsNothing);
    });
  });

  group('checking out a plan', () {
    final launched = <Uri>[];
    setUp(launched.clear);

    Future<FakeCreditRepository> openApproved(
      WidgetTester tester, {
      FakeCreditRepository? repo,
    }) async {
      final fake =
          repo ??
          FakeCreditRepository(agreement: agreementWire(checkedOut: false));
      await _pumpApp(
        tester,
        repo: fake,
        initialLocation: RouteNames.paymentPlanDetailPath('plan-1'),
        launched: launched,
      );
      await _settle(tester);
      return fake;
    }

    testWidgets('an approved plan goes to checkout before any payment', (
      tester,
    ) async {
      await openApproved(tester);

      expect(find.byKey(const Key('plan-checkout')), findsOneWidget);
      expect(
        find.byKey(const Key('plan-pay-primary')),
        findsNothing,
        reason:
            'the first payment starts the plan, and a plan starts with the '
            'order that delivers it',
      );
      expect(find.textContaining('Check out by'), findsOneWidget);
    });

    testWidgets(
      'placing pays the first amount, not the price, and comes back',
      (tester) async {
        final repo = await openApproved(tester);

        await _tapVisible(tester, find.byKey(const Key('plan-checkout')));
        expect(find.text('Pashmina overcoat'), findsWidgets);
        expect(find.text('M · Charcoal'), findsOneWidget);
        final due = find.byKey(const Key('plan-checkout-due-today'));
        expect(
          find.descendant(of: due, matching: find.textContaining('12,000')),
          findsOneWidget,
        );
        expect(find.text('Cash on Delivery'), findsNothing);
        expect(find.textContaining('Place order and pay'), findsOneWidget);

        await tester.tap(find.byKey(const Key('plan-checkout-rail-card')));
        await tester.pump();
        await _tapVisible(tester, find.byKey(const Key('plan-checkout-place')));

        final placed = repo.placements.single;
        expect(placed.sessionId, 'session-1');
        expect(placed.addressId, 'addr-home', reason: 'the default address');
        expect(placed.rail, PlanPaymentRail.card);
        expect(
          launched.single.toString(),
          'https://pay.example.test/first-payment',
        );
        expect(find.byKey(const Key('plan-payment-started')), findsOneWidget);
        expect(
          find.byKey(const Key('plan-checkout')),
          findsNothing,
          reason: 'the plan has its order now',
        );
      },
    );

    testWidgets('with nothing due up front it places without a payment page', (
      tester,
    ) async {
      final repo = FakeCreditRepository(
        agreement: agreementWire(
          checkedOut: false,
          downPayment: 0,
          needsActivationPayment: false,
        ),
      )..placedRedirect = null;
      await openApproved(tester, repo: repo);

      await _tapVisible(tester, find.byKey(const Key('plan-checkout')));
      final due = find.byKey(const Key('plan-checkout-due-today'));
      expect(
        find.descendant(of: due, matching: find.text('Nothing')),
        findsOneWidget,
      );
      expect(find.text('Place order'), findsOneWidget);

      await _tapVisible(tester, find.byKey(const Key('plan-checkout-place')));

      expect(repo.placements, hasLength(1));
      expect(launched, isEmpty);
    });

    testWidgets('without an address there is nothing to place', (tester) async {
      final repo = FakeCreditRepository(
        agreement: agreementWire(checkedOut: false),
      )..addresses = const [];
      await openApproved(tester, repo: repo);

      await _tapVisible(tester, find.byKey(const Key('plan-checkout')));

      expect(
        find.byKey(const Key('plan-checkout-add-address')),
        findsOneWidget,
      );
      final place = tester.widget<FilledButton>(
        find.byKey(const Key('plan-checkout-place')),
      );
      expect(place.onPressed, isNull);
    });

    testWidgets('a refused place says why and starts afresh on the retry', (
      tester,
    ) async {
      final repo =
          FakeCreditRepository(agreement: agreementWire(checkedOut: false))
            ..placeFailure = const EmiFailure(
              EmiFailureKind.server,
              code: 'credit_payment.unavailable',
            );
      await openApproved(tester, repo: repo);
      await _tapVisible(tester, find.byKey(const Key('plan-checkout')));

      await _tapVisible(tester, find.byKey(const Key('plan-checkout-place')));
      expect(find.byKey(const Key('plan-checkout-error')), findsOneWidget);
      expect(find.textContaining('Nothing has been charged'), findsOneWidget);

      repo.placeFailure = null;
      await _tapVisible(tester, find.byKey(const Key('plan-checkout-place')));

      expect(
        repo.checkoutsStarted,
        2,
        reason: 'the server ended the first session when it refused it',
      );
      expect(repo.placements.last.sessionId, 'session-2');
      expect(repo.placements.last.key, isNot(repo.placements.first.key));
    });

    testWidgets('a plan already waiting on its order is sent back to pay', (
      tester,
    ) async {
      final repo =
          FakeCreditRepository(agreement: agreementWire(checkedOut: false))
            ..checkoutFailure = const EmiFailure(
              EmiFailureKind.rejected,
              code: 'credit_agreement.order_attached',
            );
      await openApproved(tester, repo: repo);

      await _tapVisible(tester, find.byKey(const Key('plan-checkout')));

      expect(find.textContaining('Pay it from the plan'), findsOneWidget);
    });
  });

  group('the product page line', () {
    Widget line() => const EmiFromLine(
      offer: _offer,
      productId: 'p1',
      productName: 'Pashmina overcoat',
      variantId: _variant,
    );

    testWidgets('names every plan on offer', (tester) async {
      await _pumpApp(tester, repo: FakeCreditRepository(), home: line());
      await _settle(tester);

      expect(find.textContaining('EMI from Rs 8,000/month'), findsOneWidget);
      expect(find.textContaining('or pay now, buy later'), findsOneWidget);
    });

    testWidgets('draws nothing when the server says nothing is offered', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        repo: FakeCreditRepository(
          planOptions: {...planOptionsWire, 'options': const <Object>[]},
        ),
        home: line(),
      );
      await _settle(tester);

      expect(find.textContaining('EMI from'), findsNothing);
    });

    testWidgets('falls back to phase 1 on a server without plan options', (
      tester,
    ) async {
      await _pumpApp(
        tester,
        repo: FakeCreditRepository(),
        home: line(),
        planOptionsFail: true,
      );
      await _settle(tester);

      // 48,000 over 6 months at the minimum 20 %.
      expect(find.text('EMI from Rs 8,000/month'), findsOneWidget);
      expect(find.textContaining('or pay'), findsNothing);
    });
  });
}
