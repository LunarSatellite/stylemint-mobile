import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/checkout_emi_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_eligibility.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_quote.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/emi_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

import '../emi/credit_fakes.dart';

CartItem _item({
  String? variantId = 'v-1',
  int quantity = 1,
  String name = 'Pashmina overcoat',
}) => CartItem(
  id: 'line-$name',
  productId: 'p-$name',
  productName: name,
  productImageUrl: '',
  variantName: 'M',
  quantity: quantity,
  unitPrice: const Money(amount: 60000, currency: 'NPR'),
  isInStock: true,
  variantId: variantId,
);

/// EMI quotes fail, so the card shows the device's own arithmetic.
class _NoQuoteEmiRepository implements EmiRepository {
  @override
  Future<Either<EmiFailure, EmiQuote>> getQuote({
    required String variantId,
    required int downPaymentPercent,
    required int tenureMonths,
  }) async => left(const EmiFailure(EmiFailureKind.offline));

  @override
  Future<Either<EmiFailure, EmiEligibility>> getEligibility() async =>
      left(const EmiFailure(EmiFailureKind.unknown));
}

EmiEligibility _eligibility(EmiCta cta) => EmiEligibility(
  kycTier: cta == EmiCta.eligible ? 2 : 0,
  kycStatus: KycStatus.none,
  eligible: cta == EmiCta.eligible,
  reasons: switch (cta) {
    EmiCta.inReview => const [EmiIneligibleReason.kycInReview],
    EmiCta.eligible => const [],
    _ => const [EmiIneligibleReason.kycRequired],
  },
);

void _usePhoneSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 4000);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Pumps the option inside a router, so pushes land on named stub screens.
Future<FakeCreditRepository> _pump(
  WidgetTester tester,
  List<CartItem> items, {
  bool offered = true,
  Object? optionsError,
  bool signedIn = true,
  EmiCta cta = EmiCta.eligible,
  FakeCreditRepository? credit,
}) async {
  _usePhoneSize(tester);
  final repo = credit ?? FakeCreditRepository();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: SingleChildScrollView(child: CheckoutEmiOption(items: items)),
        ),
      ),
      GoRoute(
        path: RouteNames.customerKyc,
        builder: (_, _) => const Scaffold(body: Text('KYC screen')),
      ),
      GoRoute(
        path: RouteNames.paymentPlanCheckout,
        builder: (_, s) => Scaffold(
          body: Text('Plan checkout ${s.pathParameters['agreementId']}'),
        ),
      ),
      GoRoute(
        path: RouteNames.paymentPlanDetail,
        builder: (_, s) => Scaffold(
          body: Text('Plan detail ${s.pathParameters['agreementId']}'),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        planOptionsProvider.overrideWith((ref, variantId) async {
          if (optionsError != null) throw optionsError;
          return offered
              ? readPlanOptions(planOptionsWire)
              : PlanOptions(
                  variantId: variantId,
                  price: const Money(amount: 60000, currency: 'NPR'),
                  options: const [],
                );
        }),
        creditRepositoryProvider.overrideWithValue(repo),
        emiRepositoryProvider.overrideWithValue(_NoQuoteEmiRepository()),
        emiSignedInProvider.overrideWithValue(signedIn),
        emiEligibilityProvider.overrideWith((ref) async => _eligibility(cta)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  test('cart line keeps its productVariantId', () {
    final dto = CartItemDto.fromJson(<String, dynamic>{
      'lineId': 'l1',
      'productId': 'p1',
      'productTitleSnapshot': 'Shawl',
      'quantity': 1,
      'unitPriceAmount': 5000,
      'productVariantId': 'v-42',
    });
    expect(dto.toDomain().variantId, 'v-42');
  });

  testWidgets('plans are shown inline: kinds, tenures, down payment, '
      'monthly and total', (tester) async {
    await _pump(tester, [_item()]);
    expect(find.byKey(CheckoutEmiOption.cardKey), findsOneWidget);
    expect(find.text('Pay with EMI'), findsOneWidget);
    // Both kinds on offer, EMI first; EMI's tenures as chips.
    expect(
      find.byKey(const Key('checkout-emi-kind-instalment')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('checkout-emi-kind-prepay')), findsOneWidget);
    expect(find.byKey(const Key('checkout-emi-tenure-3')), findsOneWidget);
    expect(find.byKey(const Key('checkout-emi-tenure-6')), findsOneWidget);
    // 20% of 60,000 down, 48,000 over the longest tenure (6) = 8,000.
    expect(find.text('Down payment 20% (min 20%)'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('checkout-emi-monthly')),
        matching: find.textContaining('8,000'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('checkout-emi-total')),
        matching: find.textContaining('60,000'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Pay down payment'), findsOneWidget);
    expect(find.textContaining('12,000'), findsWidgets);
    // No bottom sheet is needed to see any of it.
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('tenure and down payment are adjustable', (tester) async {
    await _pump(tester, [_item()]);
    await tester.tap(find.byKey(const Key('checkout-emi-tenure-3')));
    await tester.pumpAndSettle();
    // 48,000 over 3 months.
    expect(
      find.descendant(
        of: find.byKey(const Key('checkout-emi-monthly')),
        matching: find.textContaining('16,000'),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('checkout-emi-down-plus')));
    await tester.pumpAndSettle();
    expect(find.text('Down payment 25% (min 20%)'), findsOneWidget);
    expect(find.textContaining('15,000'), findsWidgets);
  });

  testWidgets('no plan offered draws nothing', (tester) async {
    await _pump(tester, [_item()], offered: false);
    expect(find.byKey(CheckoutEmiOption.cardKey), findsNothing);
    expect(find.byKey(CheckoutEmiOption.noteKey), findsNothing);
  });

  testWidgets('an item with no plan (the server says not available) '
      'draws nothing', (tester) async {
    await _pump(
      tester,
      [_item()],
      optionsError: const EmiLoadException(
        EmiFailure(EmiFailureKind.rejected, code: 'credit_offer.not_available'),
      ),
    );
    expect(find.byKey(CheckoutEmiOption.cardKey), findsNothing);
    expect(find.byKey(CheckoutEmiOption.errorKey), findsNothing);
  });

  testWidgets('plans that could not be loaded offer a retry instead of '
      'vanishing', (tester) async {
    await _pump(
      tester,
      [_item()],
      optionsError: const EmiLoadException(EmiFailure(EmiFailureKind.offline)),
    );
    expect(find.byKey(CheckoutEmiOption.errorKey), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('several items: plans per eligible item, plus the one-item '
      'note', (tester) async {
    await _pump(tester, [_item(), _item(variantId: 'v-2', name: 'Silk scarf')]);
    expect(find.byKey(const ValueKey('checkout-emi-card-v-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('checkout-emi-card-v-2')), findsOneWidget);
    expect(find.text('Pay with EMI · Silk scarf'), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.noteKey), findsOneWidget);
  });

  testWidgets('a line without a variant id draws nothing', (tester) async {
    await _pump(tester, [_item(variantId: null)]);
    expect(find.byKey(CheckoutEmiOption.cardKey), findsNothing);
  });

  testWidgets('signed out: sign in first', (tester) async {
    await _pump(tester, [_item()], signedIn: false);
    expect(find.text('Sign in to pay with EMI'), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
  });

  testWidgets('unverified: get verified opens KYC from checkout', (
    tester,
  ) async {
    final repo = await _pump(tester, [_item()], cta: EmiCta.getVerified);
    expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
    await tester.tap(find.byKey(CheckoutEmiOption.verifyKey));
    await tester.pumpAndSettle();
    expect(find.text('KYC screen'), findsOneWidget);
    expect(repo.applications, isEmpty);
  });

  testWidgets('in review: says so, and cannot pay yet', (tester) async {
    await _pump(tester, [_item()], cta: EmiCta.inReview);
    expect(find.byKey(CheckoutEmiOption.inReviewKey), findsOneWidget);
    expect(find.text('Verification in review'), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
  });

  testWidgets('verified: pay quotes, applies once with a key, and opens the '
      'plan checkout when approved', (tester) async {
    final repo = await _pump(tester, [_item()]);
    await tester.tap(find.byKey(CheckoutEmiOption.payKey));
    await tester.pumpAndSettle();
    expect(repo.quotes.single.kind, PlanKind.instalment);
    expect(repo.quotes.single.down, 20);
    expect(repo.quotes.single.tenure, 6);
    expect(repo.applications, hasLength(1));
    expect(repo.applications.single.key, isNotEmpty);
    expect(find.textContaining('Plan checkout'), findsOneWidget);
  });

  testWidgets('verified but referred to the seller: opens the plan, which '
      'says it waits on them', (tester) async {
    final repo = FakeCreditRepository(agreement: agreementWire(state: 1));
    await _pump(tester, [_item()], credit: repo);
    await tester.tap(find.byKey(CheckoutEmiOption.payKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Plan detail'), findsOneWidget);
  });

  testWidgets('declined: the reason is shown on the checkout', (tester) async {
    final repo = FakeCreditRepository(
      agreement: agreementWire(state: 6, reasons: ['cooling_off']),
    );
    await _pump(tester, [_item()], credit: repo);
    await tester.tap(find.byKey(CheckoutEmiOption.payKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkout-emi-pay-error')), findsOneWidget);
    expect(find.textContaining('Plan'), findsNothing);
  });
}
