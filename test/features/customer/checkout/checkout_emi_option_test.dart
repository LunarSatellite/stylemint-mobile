import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/data/models/cart_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/checkout_emi_option.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/widgets/credit_documents_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/data/saved_credit_documents.dart';
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

/// Saved EMI documents, in memory: what the device would keep.
class FakeSavedDocuments implements SavedCreditDocumentStore {
  bool consent = false;
  final List<SavedCreditDocument> docs = [];
  int _next = 0;

  @override
  Future<bool> hasConsent() async => consent;

  @override
  Future<void> setConsent(bool value) async {
    if (!value) return deleteAll();
    consent = true;
  }

  @override
  Future<List<SavedCreditDocument>> list() async =>
      consent ? [...docs] : const [];

  @override
  Future<SavedCreditDocument?> save({
    required CreditDocumentKind kind,
    required String path,
    required String name,
    required int sizeBytes,
  }) async {
    if (!consent) return null;
    final doc = SavedCreditDocument(
      id: 'saved-${_next++}',
      kind: kind,
      name: name,
      sizeBytes: sizeBytes,
      savedAt: DateTime(2026, 10, 16),
      path: '/private/emi-documents/$name',
    );
    docs.add(doc);
    return doc;
  }

  @override
  Future<void> delete(String id) async => docs.removeWhere((d) => d.id == id);

  @override
  Future<void> deleteAll() async {
    docs.clear();
    consent = false;
  }
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
  Map<String, dynamic>? options,
  List<PickedCreditDocument> picks = const [],
  FakeSavedDocuments? saved,
}) async {
  final queue = [...picks];
  final savedDocs = saved ?? FakeSavedDocuments();
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
              ? readPlanOptions(options ?? planOptionsWire)
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
        creditDocumentPickerProvider.overrideWithValue(
          (_) async => queue.isEmpty ? null : queue.removeAt(0),
        ),
        savedCreditDocumentStoreProvider.overrideWithValue(savedDocs),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

/// "Add documents" on the inline plan card: opens the documents page.
Future<void> _openDocuments(WidgetTester tester) async {
  await tester.tap(find.byKey(CheckoutEmiOption.addDocumentsKey));
  await tester.pumpAndSettle();
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
    // EMI goes to the seller with documents — even though this (older)
    // server still says requiresVerifiedIdentity for it. Never KYC.
    expect(find.byKey(CheckoutEmiOption.documentsKey), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.verifyKey), findsNothing);
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

  testWidgets('the plan is on the checkout page itself; only the documents '
      'open on their own page, from "Add documents"', (tester) async {
    await _pump(tester, [_item()]);
    // Plan, figures and the next step are right on checkout.
    expect(find.byKey(CheckoutEmiOption.cardKey), findsOneWidget);
    expect(find.byKey(const Key('checkout-emi-tenure-6')), findsOneWidget);
    expect(find.byKey(const Key('checkout-emi-monthly')), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.addDocumentsKey), findsOneWidget);
    expect(find.byType(CreditDocumentsScreen), findsNothing);
    expect(find.byKey(const Key('checkout-emi-add-identity')), findsNothing);

    await _openDocuments(tester);
    expect(find.byType(CreditDocumentsScreen), findsOneWidget);
    expect(find.byKey(const Key('checkout-emi-add-identity')), findsOneWidget);
    expect(find.byKey(const Key('checkout-emi-add-financial')), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.sendKey), findsOneWidget);
  });

  testWidgets('a line without a variant id draws nothing', (tester) async {
    await _pump(tester, [_item(variantId: null)]);
    expect(find.byKey(CheckoutEmiOption.cardKey), findsNothing);
  });

  // Pay later on the platform's money still needs a verified identity. EMI
  // never does (see below).
  final payLaterOptions = <String, dynamic>{
    ...planOptionsWire,
    'options': [
      {
        ...(planOptionsWire['options']! as List).first as Map<String, dynamic>,
        'kind': 2,
        'guarantor': 2,
        'requiresVerifiedIdentity': true,
      },
    ],
  };

  testWidgets('EMI from an older server that still says requiresVerified'
      'Identity: documents, never Get verified', (tester) async {
    await _pump(tester, [_item()], cta: EmiCta.getVerified);
    expect(find.byKey(CheckoutEmiOption.documentsKey), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.verifyKey), findsNothing);
    expect(find.textContaining('Get verified'), findsNothing);
    // The documents and the send step are on their own page.
    expect(find.text('Add documents'), findsOneWidget);
  });

  testWidgets('pay later signed out: sign in first', (tester) async {
    await _pump(tester, [_item()], signedIn: false, options: payLaterOptions);
    expect(find.text('Sign in to use this plan'), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
  });

  testWidgets('pay later, unverified: get verified opens KYC from checkout', (
    tester,
  ) async {
    final repo = await _pump(
      tester,
      [_item()],
      cta: EmiCta.getVerified,
      options: payLaterOptions,
    );
    expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
    await tester.tap(find.byKey(CheckoutEmiOption.verifyKey));
    await tester.pumpAndSettle();
    expect(find.text('KYC screen'), findsOneWidget);
    expect(repo.applications, isEmpty);
  });

  testWidgets('pay later in review: says so, and cannot pay yet', (tester) async {
    await _pump(
      tester,
      [_item()],
      cta: EmiCta.inReview,
      options: payLaterOptions,
    );
    expect(find.byKey(CheckoutEmiOption.inReviewKey), findsOneWidget);
    expect(find.text('Verification in review'), findsOneWidget);
    expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
  });

  testWidgets('pay later verified: pay quotes, applies once with a key, and opens the '
      'plan checkout when approved', (tester) async {
    final repo = await _pump(tester, [_item()], options: payLaterOptions);
    await tester.tap(find.byKey(CheckoutEmiOption.payKey));
    await tester.pumpAndSettle();
    expect(repo.quotes.single.kind, PlanKind.payLater);
    expect(repo.quotes.single.down, 20);
    expect(repo.quotes.single.tenure, 6);
    expect(repo.applications, hasLength(1));
    expect(repo.applications.single.key, isNotEmpty);
    expect(find.textContaining('Plan checkout'), findsOneWidget);
  });

  testWidgets('pay later verified but referred to the seller: opens the plan, which '
      'says it waits on them', (tester) async {
    final repo = FakeCreditRepository(agreement: agreementWire(state: 1));
    await _pump(tester, [_item()], credit: repo, options: payLaterOptions);
    await tester.tap(find.byKey(CheckoutEmiOption.payKey));
    await tester.pumpAndSettle();
    expect(find.textContaining('Plan detail'), findsOneWidget);
  });

  testWidgets('pay later declined: the reason is shown on the checkout', (tester) async {
    final repo = FakeCreditRepository(
      agreement: agreementWire(state: 6, reasons: ['cooling_off']),
    );
    await _pump(tester, [_item()], credit: repo, options: payLaterOptions);
    await tester.tap(find.byKey(CheckoutEmiOption.payKey));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('checkout-emi-pay-error')), findsOneWidget);
    expect(find.textContaining('Plan'), findsNothing);
  });

  group('EMI decided by the seller, from documents sent at checkout', () {
    const variant = 'f0a10cdf-15d7-4402-8774-9ac69f7aa421';
    final sellerOptions = <String, dynamic>{
      ...planOptionsWire,
      'options': [
        {
          ...(planOptionsWire['options']! as List).first
              as Map<String, dynamic>,
          'requiresVerifiedIdentity': false,
          'requiresDocuments': true,
        },
      ],
    };
    const id = PickedCreditDocument(
      path: '/tmp/citizenship.jpg',
      name: 'citizenship.jpg',
      sizeBytes: 1000,
    );
    const slip = PickedCreditDocument(
      path: '/tmp/salary.pdf',
      name: 'salary.pdf',
      sizeBytes: 2000,
    );

    FakeCreditRepository repoWith(Map<String, dynamic>? agreement) {
      final repo = FakeCreditRepository(
        agreement: agreement ?? agreementWire(state: 1),
      );
      return repo;
    }

    testWidgets('signed out: sign in to apply', (tester) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        signedIn: false,
        options: sellerOptions,
      );
      expect(find.text('Sign in to apply for EMI'), findsOneWidget);
    });

    testWidgets('no KYC gate: the buyer adds identity and financial proof, '
        'sends, and then waits for the seller', (tester) async {
      // A fresh applicant: no plan on this item yet.
      final repo = repoWith(agreementWire(state: 1))
        ..agreement = agreementWire(state: 1, id: 'new-plan')
        ..submittedAgreement = {
          ...agreementWire(state: 1, id: 'new-plan'),
          'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
        };
      await _pump(
        tester,
        [_item(variantId: 'other-variant')],
        cta: EmiCta.getVerified,
        credit: repo,
        options: sellerOptions,
        picks: const [id, slip],
      );
      expect(find.byKey(CheckoutEmiOption.documentsKey), findsOneWidget);
      expect(find.byKey(CheckoutEmiOption.verifyKey), findsNothing);
      await _openDocuments(tester);
      final send = find.byKey(CheckoutEmiOption.sendKey);
      expect(
        tester
            .widget<FilledButton>(
              find.descendant(of: send, matching: find.byType(FilledButton)),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const Key('checkout-emi-add-identity')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkout-emi-add-financial')));
      await tester.pumpAndSettle();
      expect(find.text('citizenship.jpg'), findsOneWidget);
      expect(find.text('salary.pdf'), findsOneWidget);

      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(repo.quotes, hasLength(1));
      expect(repo.applications.single.key, isNotEmpty);
      expect(repo.uploads.map((u) => u.kind), [
        CreditDocumentKind.identity,
        CreditDocumentKind.financial,
      ]);
      expect(repo.uploads.every((u) => u.agreementId == 'new-plan'), isTrue);
      expect(repo.submissions.single.key, isNotEmpty);
      expect(find.byKey(CheckoutEmiOption.waitingKey), findsOneWidget);
      expect(find.text('Waiting for the seller to approve'), findsOneWidget);
      expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
    });

    testWidgets('a file over 10 MB is refused before upload', (tester) async {
      final repo = repoWith(null);
      await _pump(
        tester,
        [_item(variantId: 'other-variant')],
        credit: repo,
        options: sellerOptions,
        picks: const [
          PickedCreditDocument(
            path: '/tmp/big.pdf',
            name: 'big.pdf',
            sizeBytes: 11 * 1024 * 1024,
          ),
        ],
      );
      await _openDocuments(tester);
      await tester.tap(find.byKey(const Key('checkout-emi-add-financial')));
      await tester.pumpAndSettle();
      expect(find.textContaining('larger than 10 MB'), findsOneWidget);
      expect(find.text('big.pdf'), findsNothing);
    });

    Future<FakeCreditRepository> pumpFresh(
      WidgetTester tester,
      FakeSavedDocuments saved, {
      List<PickedCreditDocument> picks = const [id, slip],
    }) {
      final repo = repoWith(agreementWire(state: 1))
        ..agreement = agreementWire(state: 1, id: 'new-plan')
        ..submittedAgreement = {
          ...agreementWire(state: 1, id: 'new-plan'),
          'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
        };
      return _pump(
        tester,
        [_item(variantId: 'other-variant')],
        credit: repo,
        options: sellerOptions,
        picks: picks,
        saved: saved,
      );
    }

    Future<void> addBothAndSend(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('checkout-emi-add-identity')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkout-emi-add-financial')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CheckoutEmiOption.sendKey));
      await tester.pumpAndSettle();
    }

    testWidgets('saving documents asks first, and is off by default: '
        'without consent nothing is kept', (tester) async {
      final saved = FakeSavedDocuments();
      await pumpFresh(tester, saved);
      await _openDocuments(tester);
      expect(find.text(CreditDocumentsScreen.consentText), findsOneWidget);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(CreditDocumentsScreen.consentKey))
            .value,
        isFalse,
      );
      await addBothAndSend(tester);
      expect(find.byKey(CheckoutEmiOption.waitingKey), findsOneWidget);
      expect(saved.docs, isEmpty);
      expect(saved.consent, isFalse);
    });

    testWidgets('with consent the documents are kept on the phone and offered '
        'the next time, still uploaded fresh', (tester) async {
      final saved = FakeSavedDocuments();
      await pumpFresh(tester, saved);
      await _openDocuments(tester);
      await tester.tap(find.byKey(CreditDocumentsScreen.consentKey));
      await tester.pumpAndSettle();
      await addBothAndSend(tester);
      expect(saved.consent, isTrue);
      expect(saved.docs.map((d) => (d.kind, d.name)), [
        (CreditDocumentKind.identity, 'citizenship.jpg'),
        (CreditDocumentKind.financial, 'salary.pdf'),
      ]);

      // The next EMI application: nothing picked, the saved ones offered.
      await tester.pumpWidget(const SizedBox());
      final repo = await pumpFresh(tester, saved, picks: const []);
      await _openDocuments(tester);
      expect(find.byKey(CreditDocumentsScreen.savedKey), findsOneWidget);
      expect(find.text('Use saved documents'), findsOneWidget);
      await tester.tap(find.byKey(const Key('credit-docs-use-saved-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('credit-docs-use-saved-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CheckoutEmiOption.sendKey));
      await tester.pumpAndSettle();
      expect(repo.uploads.map((u) => u.kind), [
        CreditDocumentKind.identity,
        CreditDocumentKind.financial,
      ]);
      expect(saved.docs, hasLength(2), reason: 'not saved a second time');
    });

    testWidgets('saved documents can be deleted one by one or all at once, '
        'and turning consent off deletes them', (tester) async {
      final saved = FakeSavedDocuments()..consent = true;
      for (final d in [id, slip, id]) {
        await saved.save(
          kind: d == slip
              ? CreditDocumentKind.financial
              : CreditDocumentKind.identity,
          path: d.path,
          name: d.name,
          sizeBytes: d.sizeBytes,
        );
      }
      await pumpFresh(tester, saved, picks: const []);
      await _openDocuments(tester);
      await tester.tap(find.byKey(const Key('credit-docs-delete-saved-0')));
      await tester.pumpAndSettle();
      expect(saved.docs.map((d) => d.id), ['saved-1', 'saved-2']);
      expect(find.byKey(const Key('credit-docs-use-saved-0')), findsNothing);

      await tester.tap(find.byKey(CreditDocumentsScreen.deleteAllKey));
      await tester.pumpAndSettle();
      expect(saved.docs, isEmpty);
      expect(find.byKey(CreditDocumentsScreen.savedKey), findsNothing);

      // Consent on again with one saved, then off: it is deleted.
      await tester.tap(find.byKey(CreditDocumentsScreen.consentKey));
      await tester.pumpAndSettle();
      expect(saved.consent, isTrue);
      await saved.save(
        kind: CreditDocumentKind.identity,
        path: id.path,
        name: id.name,
        sizeBytes: id.sizeBytes,
      );
      await tester.tap(find.byKey(CreditDocumentsScreen.consentKey));
      await tester.pumpAndSettle();
      expect(saved.consent, isFalse);
      expect(saved.docs, isEmpty);
    });

    testWidgets('already sent: shows the wait, not the form', (tester) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith({
          ...agreementWire(state: 1),
          'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
        }),
        options: sellerOptions,
      );
      expect(find.byKey(CheckoutEmiOption.waitingKey), findsOneWidget);
      expect(find.byKey(CheckoutEmiOption.documentsKey), findsNothing);
    });

    testWidgets('approved by the seller: pay the down payment, which opens '
        'the plan checkout', (tester) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith({
          ...agreementWire(checkedOut: false),
          'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
        }),
        options: sellerOptions,
      );
      expect(find.byKey(CheckoutEmiOption.approvedKey), findsOneWidget);
      expect(find.textContaining('Pay down payment'), findsOneWidget);
      expect(find.textContaining('12,000'), findsWidgets);
      await tester.tap(find.byKey(CheckoutEmiOption.payKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Plan checkout'), findsOneWidget);
    });

    testWidgets('an approval given without documents is not reused: the buyer '
        'is asked for documents again', (tester) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith(agreementWire(checkedOut: false)),
        options: sellerOptions,
      );
      expect(find.byKey(CheckoutEmiOption.approvedKey), findsNothing);
      expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
      expect(find.byKey(CheckoutEmiOption.documentsKey), findsOneWidget);
    });

    testWidgets('approved, seller allows cash: online or cash on delivery for '
        'the down payment', (tester) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith({
          ...agreementWire(checkedOut: false),
          'cashOnDeliveryDownPaymentAllowed': true,
          'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
        }),
        options: sellerOptions,
      );
      expect(find.byKey(CheckoutEmiOption.payKey), findsOneWidget);
      expect(find.textContaining('online'), findsOneWidget);
      expect(find.byKey(CheckoutEmiOption.payCashKey), findsOneWidget);
      expect(
        find.textContaining('Pay down payment on delivery (cash)'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(CheckoutEmiOption.payCashKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Plan checkout'), findsOneWidget);
    });

    testWidgets('approved, seller does not allow cash: online only', (
      tester,
    ) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith(agreementWire(checkedOut: false)),
        options: sellerOptions,
      );
      expect(find.byKey(CheckoutEmiOption.payCashKey), findsNothing);
    });

    testWidgets('ordered with the down payment in cash: shows the order and '
        'the cash to pay on delivery, never EMI again', (tester) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith({
          ...agreementWire(),
          'cashOnDeliveryDownPaymentAllowed': true,
          'downPaymentOnDelivery': true,
          'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
        }),
        options: sellerOptions,
      );
      expect(find.byKey(CheckoutEmiOption.cashPendingKey), findsOneWidget);
      expect(
        find.textContaining('Ordered — pay Rs 12,000 down payment in cash'),
        findsOneWidget,
        reason: 'the down payment, in cash on delivery',
      );
      expect(find.textContaining('12,000'), findsWidgets);
      expect(find.textContaining('in cash on delivery'), findsWidgets);
      expect(find.byKey(CheckoutEmiOption.documentsKey), findsNothing);
      expect(find.byKey(CheckoutEmiOption.sendKey), findsNothing);
      expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
      expect(find.byKey(CheckoutEmiOption.payCashKey), findsNothing);
      await tester.tap(find.byKey(CheckoutEmiOption.viewPlanKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Plan detail'), findsOneWidget);
    });

    testWidgets('the checkout card says the item is ordered on EMI', (
      tester,
    ) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith({
          ...agreementWire(),
          'downPaymentOnDelivery': true,
          'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
        }),
        options: sellerOptions,
      );
      expect(find.text('EMI ordered'), findsOneWidget);
      expect(find.text('Pay with EMI'), findsNothing);
      expect(
        find.textContaining('down payment in cash on delivery'),
        findsOneWidget,
      );
    });

    testWidgets('ordered, down payment online still due: finish paying it '
        'from the plan, no new application', (tester) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith({
          ...agreementWire(),
          'documentsSubmittedUtc': '2026-03-02T06:20:00+00:00',
        }),
        options: sellerOptions,
      );
      expect(find.byKey(CheckoutEmiOption.orderedKey), findsOneWidget);
      expect(find.byKey(CheckoutEmiOption.documentsKey), findsNothing);
      await tester.tap(find.byKey(CheckoutEmiOption.orderedPayKey));
      await tester.pumpAndSettle();
      expect(find.textContaining('Plan detail'), findsOneWidget);
    });

    testWidgets('a plan that started or closed is not reused: the next '
        'purchase is a new application for the seller', (tester) async {
      for (final used in [
        agreementWire(state: 3), // active: down payment paid
        agreementWire(state: 4), // completed
        agreementWire(state: 7), // cancelled
        agreementWire(state: 8), // expired
      ]) {
        await _pump(
          tester,
          [_item(variantId: variant)],
          credit: repoWith(used),
          options: sellerOptions,
        );
        expect(
          find.byKey(CheckoutEmiOption.documentsKey),
          findsOneWidget,
          reason: 'state ${used['state']}',
        );
        expect(find.byKey(CheckoutEmiOption.approvedKey), findsNothing);
        expect(find.byKey(CheckoutEmiOption.payKey), findsNothing);
      }
    });

    testWidgets('declined by the seller: their reason, and apply again', (
      tester,
    ) async {
      await _pump(
        tester,
        [_item(variantId: variant)],
        credit: repoWith({
          ...agreementWire(state: 6, reasons: ['documents_not_sufficient']),
          'decisionNote': 'Bank statement is older than 3 months.',
        }),
        options: sellerOptions,
      );
      expect(find.byKey(CheckoutEmiOption.declinedKey), findsOneWidget);
      expect(
        find.textContaining('Bank statement is older than 3 months.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Apply again'));
      await tester.pumpAndSettle();
      expect(find.byKey(CheckoutEmiOption.documentsKey), findsOneWidget);
    });
  });
}
