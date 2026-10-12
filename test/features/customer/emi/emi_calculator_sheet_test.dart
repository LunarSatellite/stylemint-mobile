import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_plan.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/product_emi_offer.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/emi_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/presentation/widgets/emi_calculator_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

const _price = Money(amount: 25000, currency: 'NPR');

const _offer = ProductEmiOffer(
  minDownPaymentPercent: 30,
  tenures: [3, 6],
  variants: {'v1': EmiVariantTerms(price: _price, eligible: true)},
);

/// Answers every quote with the contract's own arithmetic, as the server
/// would — or with [failure] when set.
class _FakeEmiRepository implements EmiRepository {
  _FakeEmiRepository({this.failure});

  final EmiFailure? failure;
  final requests = <(int, int)>[];

  @override
  Future<Either<EmiFailure, EmiQuote>> getQuote({
    required String variantId,
    required int downPaymentPercent,
    required int tenureMonths,
  }) async {
    requests.add((downPaymentPercent, tenureMonths));
    final refusal = failure;
    if (refusal != null) return left(refusal);
    final plan = EmiPlan.compute(
      price: _price,
      downPaymentPercent: downPaymentPercent,
      tenureMonths: tenureMonths,
    );
    return right(
      EmiQuote(
        variantId: variantId,
        productId: 'p1',
        price: _price,
        downPaymentPercent: downPaymentPercent,
        downPayment: plan.downPayment,
        financedAmount: plan.financedAmount,
        tenureMonths: tenureMonths,
        monthlyInstallment: plan.monthlyInstallment,
        lastInstallment: plan.lastInstallment,
        interestTotal: const Money(amount: 0, currency: 'NPR'),
        totalPayable: _price,
        schedule: [
          for (var i = 0; i < plan.schedule.length; i++)
            EmiInstallment(number: i + 1, amount: plan.schedule[i]),
        ],
      ),
    );
  }

  @override
  Future<Either<EmiFailure, EmiEligibility>> getEligibility() async =>
      left(const EmiFailure(EmiFailureKind.unknown));
}

EmiEligibility _eligibility({
  bool eligible = false,
  List<String> reasons = const [],
  KycStatus status = KycStatus.none,
}) => EmiEligibility(
  kycTier: eligible ? 2 : 0,
  kycStatus: status,
  eligible: eligible,
  reasons: reasons,
);

/// Lays the sheet out on a phone-sized screen rather than the 800x600
/// default, as the social tests do.
void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<_FakeEmiRepository> _pump(
  WidgetTester tester, {
  bool signedIn = false,
  EmiEligibility? eligibility,
  EmiFailure? quoteFailure,
}) async {
  _usePhoneSize(tester);
  final repository = _FakeEmiRepository(failure: quoteFailure);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        emiRepositoryProvider.overrideWithValue(repository),
        emiSignedInProvider.overrideWithValue(signedIn),
        if (eligibility != null)
          emiEligibilityProvider.overrideWith((ref) async => eligibility),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: EmiCalculatorSheet(
            productId: 'p1',
            productName: 'Pashmina overcoat',
            variantId: 'v1',
            price: _price,
            offer: _offer,
            quoteDebounce: Duration(milliseconds: 10),
          ),
        ),
      ),
    ),
  );
  return repository;
}

/// Lets the debounce fire and the fake quote land.
Future<void> _settleQuote(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 20));
  await tester.pump();
  await tester.pump();
}

String _rowValue(WidgetTester tester, String key) {
  final row = find.byKey(Key(key));
  final texts = tester
      .widgetList<Text>(find.descendant(of: row, matching: find.byType(Text)))
      .map((t) => t.data ?? '')
      .toList();
  return texts.last;
}

void main() {
  testWidgets('opens on the minimum down payment and the longest tenure, '
      'worked out locally, then confirmed by the server', (tester) async {
    final repository = await _pump(tester);

    // Before the server answers: the device's own arithmetic.
    expect(find.text('30% · Rs 7,500'), findsOneWidget);
    expect(_rowValue(tester, 'emi-monthly'), 'Rs 2,917 × 5');
    expect(_rowValue(tester, 'emi-last'), 'Rs 2,915');
    expect(_rowValue(tester, 'emi-total'), 'Rs 25,000');
    expect(find.text('Month 6'), findsOneWidget);

    await _settleQuote(tester);

    expect(repository.requests, [(30, 6)]);
    expect(find.text('Confirmed by StyleMint'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tenure chip recomputes and asks the server again', (
    tester,
  ) async {
    final repository = await _pump(tester);
    await _settleQuote(tester);

    await tester.tap(find.byKey(const Key('emi-tenure-3')));
    await tester.pump();

    // 17,500 over 3 months: 5,834, 5,834, 5,832.
    expect(_rowValue(tester, 'emi-monthly'), 'Rs 5,834 × 2');
    expect(_rowValue(tester, 'emi-last'), 'Rs 5,832');
    expect(find.text('Month 4'), findsNothing);

    await _settleQuote(tester);
    expect(repository.requests.last, (30, 3));
    expect(find.text('Confirmed by StyleMint'), findsOneWidget);
  });

  testWidgets('the slider runs from the minimum to 90 % in 5 % steps', (
    tester,
  ) async {
    await _pump(tester);
    final slider = tester.widget<Slider>(
      find.byKey(const Key('emi-down-payment-slider')),
    );
    expect(slider.min, 30);
    expect(slider.max, 90);
    expect(slider.divisions, 12);

    slider.onChanged!(50);
    await tester.pump();
    expect(find.text('50% · Rs 12,500'), findsOneWidget);
    // 12,500 over 6 months: 2,084 x 5, then 2,080.
    expect(_rowValue(tester, 'emi-monthly'), 'Rs 2,084 × 5');
    expect(_rowValue(tester, 'emi-last'), 'Rs 2,080');
  });

  testWidgets('signed out, the button asks the buyer to sign in', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text(EmiCtaButton.signInLabel), findsOneWidget);
  });

  testWidgets('kyc_required asks the buyer to get verified', (tester) async {
    await _pump(
      tester,
      signedIn: true,
      eligibility: _eligibility(reasons: const ['kyc_required']),
    );
    await _settleQuote(tester);
    expect(find.text(EmiCtaButton.getVerifiedLabel), findsOneWidget);
  });

  testWidgets('kyc_in_review says the verification is in review', (
    tester,
  ) async {
    await _pump(
      tester,
      signedIn: true,
      eligibility: _eligibility(
        reasons: const ['kyc_in_review'],
        status: KycStatus.underReview,
      ),
    );
    await _settleQuote(tester);
    expect(find.text(EmiCtaButton.inReviewLabel), findsOneWidget);
  });

  testWidgets('an eligible buyer can continue to a quote', (tester) async {
    await _pump(
      tester,
      signedIn: true,
      eligibility: _eligibility(eligible: true, status: KycStatus.approved),
    );
    await _settleQuote(tester);

    final label = find.text(EmiCtaButton.continueLabel);
    expect(label, findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(of: label, matching: find.byType(FilledButton)),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('emi_quote.not_available replaces the plan with a notice', (
    tester,
  ) async {
    await _pump(
      tester,
      quoteFailure: const EmiFailure(
        EmiFailureKind.notFound,
        code: 'emi_quote.not_available',
        statusCode: 404,
      ),
    );
    await _settleQuote(tester);

    expect(
      find.text('EMI is not offered on this option any more.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('emi-monthly')), findsNothing);
    expect(find.text(EmiCtaButton.signInLabel), findsNothing);
  });

  testWidgets('a quote that fails for another reason keeps the estimate', (
    tester,
  ) async {
    await _pump(
      tester,
      quoteFailure: const EmiFailure(EmiFailureKind.offline),
    );
    await _settleQuote(tester);

    expect(_rowValue(tester, 'emi-monthly'), 'Rs 2,917 × 5');
    expect(find.textContaining('offline'), findsOneWidget);
  });
}
