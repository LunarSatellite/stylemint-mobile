import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart'
    show ShippingAddress;
import 'package:stylemint_mobile_frontend/features/customer/emi/data/models/credit_json.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/emi_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/repositories/credit_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Payloads exactly as the backend serialised them, copied from the output
/// of `CreditWireContractTests` in lead360 (only the quote token is
/// shortened). If a reader stops understanding these, the app has drifted
/// from the server.
const planOptionsWire = <String, dynamic>{
  'variantId': 'f0a10cdf-15d7-4402-8774-9ac69f7aa421',
  'currency': 'NPR',
  'price': 60000,
  'options': [
    {
      'kind': 1,
      'guarantor': 1,
      'interestMethod': 0,
      'minDownPaymentPercent': 20,
      'maxDownPaymentPercent': 90,
      'downPaymentFixed': false,
      'tenures': [3, 6],
      'fromMonthly': 8000,
      'fromDownPayment': 12000,
      'goodsReleasedBeforePaidInFull': true,
      'requiresVerifiedIdentity': true,
    },
    {
      'kind': 3,
      'guarantor': 4,
      'interestMethod': 0,
      'minDownPaymentPercent': 10,
      'maxDownPaymentPercent': 90,
      'downPaymentFixed': false,
      'tenures': [3],
      'fromMonthly': 18000,
      'fromDownPayment': 6000,
      'goodsReleasedBeforePaidInFull': false,
      'requiresVerifiedIdentity': false,
    },
  ],
};

const quoteWire = <String, dynamic>{
  'quoteToken': 'v1.payload.signature',
  'expiresUtc': '2026-03-02T06:15:00+00:00',
  'kind': 1,
  'guarantor': 1,
  'currency': 'NPR',
  'price': 60000,
  'downPaymentPercent': 20,
  'downPayment': 12000,
  'financed': 48000,
  'tenureMonths': 3,
  'interestMethod': 0,
  'monthlyRatePercent': 0,
  'totalInterest': 0,
  'totalPayable': 60000,
  'aprPercent': 0,
  'effectiveAnnualRatePercent': 0,
  'goodsReleasedBeforePaidInFull': true,
  'schedule': [
    {
      'number': 1,
      'monthsAfterStart': 1,
      'amount': 16000,
      'principal': 16000,
      'interest': 0,
    },
    {
      'number': 2,
      'monthsAfterStart': 2,
      'amount': 16000,
      'principal': 16000,
      'interest': 0,
    },
    {
      'number': 3,
      'monthsAfterStart': 3,
      'amount': 16000,
      'principal': 16000,
      'interest': 0,
    },
  ],
};

Map<String, dynamic> _instalment(int n, {int state = 1, String? dueDate}) => {
  'number': n,
  'dueDate': dueDate,
  'scheduledAmount': 16000,
  'principalDue': 16000,
  'interestDue': 0,
  'lateFeeDue': 0,
  'paid': state == 3 ? 16000 : 0,
  'outstanding': state == 3 ? 0 : 16000,
  'state': state,
  'paidUtc': state == 3 ? '2026-04-02T05:00:00+00:00' : null,
};

/// The order checkout created for a plan, in the fixtures.
const planOrderId = '7a1e3f52-9a0b-4c55-8d1e-2b6f0c9e4d11';

/// An approved EMI awaiting its down payment — the serialiser's own output.
/// Checked out unless [checkedOut] says otherwise: an approved plan with no
/// order goes to checkout first.
Map<String, dynamic> agreementWire({
  String id = 'f90a6410-3076-4791-84cf-fa5c77f25a4c',
  int state = 2,
  List<String> reasons = const [],
  bool needsActivationPayment = true,
  List<Map<String, dynamic>>? instalments,
  double outstanding = 48000,
  double? payoff,
  int guarantor = 1,
  bool checkedOut = true,
  double downPayment = 12000,
}) => {
  'id': id,
  'buyerAccountId': '1f67201b-7d81-4a60-93c2-b8869639dadb',
  'vendorAccountId': 'de135640-cc06-4ce7-9c2a-5804ecb88092',
  'productId': '11645bf9-cfca-4df2-88fa-7ebaec17d369',
  'variantId': 'f0a10cdf-15d7-4402-8774-9ac69f7aa421',
  'kind': 1,
  'guarantor': guarantor,
  'state': state,
  'stateReasons': reasons,
  'currency': 'NPR',
  'price': 60000,
  'downPayment': downPayment,
  'financed': 48000,
  'tenureMonths': 3,
  'interestMethod': 0,
  'totalInterest': 0,
  'totalPayable': 60000,
  'aprPercent': 0,
  'outstanding': outstanding,
  'outstandingPrincipal': outstanding,
  'payoffAmountToday': payoff,
  'daysPastDue': 0,
  'delinquency': 0,
  'appliedUtc': '2026-03-02T06:00:00+00:00',
  'approvalExpiresUtc': '2026-03-09T06:00:00+00:00',
  'activatedUtc': null,
  'goodsReleasedUtc': null,
  'closedUtc': null,
  'needsActivationPayment': needsActivationPayment,
  'orderId': checkedOut ? planOrderId : null,
  'instalments':
      instalments ?? [_instalment(1), _instalment(2), _instalment(3)],
};

/// An active plan: one instalment paid, one overdue, one to come.
Map<String, dynamic> activeAgreementWire({bool overdue = true}) =>
    agreementWire(
      state: 3,
      needsActivationPayment: false,
      outstanding: 32000,
      payoff: 32000,
      instalments: [
        _instalment(1, state: 3, dueDate: '2026-04-02'),
        _instalment(2, state: overdue ? 4 : 1, dueDate: '2026-05-02'),
        _instalment(3, dueDate: '2099-06-02'),
      ],
    );

const paymentStartWire = <String, dynamic>{
  'attemptId': '8632b793-a7c6-4fa3-8749-ccc44a126ada',
  'agreementId': 'f90a6410-3076-4791-84cf-fa5c77f25a4c',
  'purpose': 1,
  'amount': 12000,
  'currency': 'NPR',
  'payment': {
    'intentId': '9fc0ae0b-ca4d-4c44-b111-37f1fb02e644',
    'method': 3,
    'handoffKind': 2,
    'redirectUrl': 'https://pay.example.test/redirect',
    'clientSecret': null,
    'providerIntentId': null,
  },
};

const profileWire = <String, dynamic>{
  'score': 740,
  'band': 2,
  'creditLimit': 150000,
  'availableCredit': 150000,
  'outstandingPrincipal': 0,
  'openAgreements': 1,
  'identityVerified': true,
  'factors': [
    {'code': 'kyc_verified', 'points': 60},
    {'code': 'phone_verified', 'points': 20},
    {'code': 'email_verified', 'points': 10},
    {'code': 'account_age', 'points': 60},
    {'code': 'completed_orders', 'points': 50},
    {'code': 'completed_value', 'points': 40},
  ],
  'policyVersion': 'scorecard-2026-10-v1',
};

const vendorProgramWire = <String, dynamic>{
  'vendorAccountId': 'de135640-cc06-4ce7-9c2a-5804ecb88092',
  'payLaterEnabled': false,
  'payLaterTenures': <int>[],
  'payLaterDownPaymentPercent': 0,
  'payLaterAcceptedRiskFeePercent': 0,
  'currentPlatformRiskFeePercent': 3,
  'payLaterOffered': false,
  'prepayEnabled': true,
  'prepayTenures': [3],
  'prepayDepositPercent': 10,
};

/// A repository that answers from the wire fixtures and records every call.
/// Set a field to a failure to make that call fail.
class FakeCreditRepository implements CreditRepository {
  FakeCreditRepository({
    Map<String, dynamic>? agreement,
    this.planOptions,
    this.quoteFailure,
    this.applyFailure,
    this.paymentFailure,
    this.reviewFailure,
    this.expiredQuote = false,
  }) : agreement = agreement ?? agreementWire();

  Map<String, dynamic> agreement;
  Map<String, dynamic>? planOptions;
  EmiFailure? quoteFailure;
  EmiFailure? applyFailure;
  EmiFailure? paymentFailure;
  EmiFailure? reviewFailure;

  /// Quotes expire 15 minutes after they are made, unless this says the
  /// one handed out has already lapsed.
  bool expiredQuote;

  /// Fields laid over [quoteWire] on every quote, e.g. a late fee.
  Map<String, dynamic> quoteExtra = {};

  final quotes = <({PlanKind kind, int? down, int tenure})>[];
  final applications = <({String token, String key})>[];
  final payments =
      <({PaymentPurpose purpose, PlanPaymentRail rail, String key})>[];
  final reviews = <({bool approve, List<String> reasons})>[];

  /// Plan checkout: set a failure to make that step fail.
  EmiFailure? checkoutFailure;
  EmiFailure? placeFailure;
  List<ShippingAddress> addresses = const [
    ShippingAddress(
      id: 'addr-home',
      label: 'Home',
      countryCode: 'NP',
      isDefault: true,
      line1: 'Lazimpat 2',
      city: 'Kathmandu',
    ),
  ];
  String? placedRedirect = 'https://pay.example.test/first-payment';
  int checkoutsStarted = 0;
  final placements =
      <
        ({String sessionId, String addressId, PlanPaymentRail rail, String key})
      >[];
  final programs = <VendorCreditProgram>[];
  int cancels = 0;

  @override
  Future<Either<EmiFailure, PlanOptions>> getPlanOptions(
    String variantId,
  ) async => right(readPlanOptions(planOptions ?? planOptionsWire));

  @override
  Future<Either<EmiFailure, CreditProfile>> getProfile() async =>
      right(readCreditProfile(profileWire));

  @override
  Future<Either<EmiFailure, CreditQuote>> createQuote({
    required String variantId,
    required PlanKind kind,
    required int? downPaymentPercent,
    required int tenureMonths,
  }) async {
    quotes.add((kind: kind, down: downPaymentPercent, tenure: tenureMonths));
    final failure = quoteFailure;
    if (failure != null) return left(failure);
    final expires = expiredQuote
        ? DateTime.now().toUtc().subtract(const Duration(minutes: 1))
        : DateTime.now().toUtc().add(const Duration(minutes: 15));
    return right(
      readCreditQuote({
        ...quoteWire,
        ...quoteExtra,
        'expiresUtc': expires.toIso8601String(),
      }),
    );
  }

  @override
  Future<Either<EmiFailure, CreditAgreement>> apply({
    required String quoteToken,
    required String idempotencyKey,
  }) async {
    applications.add((token: quoteToken, key: idempotencyKey));
    final failure = applyFailure;
    return failure != null
        ? left(failure)
        : right(readCreditAgreement(agreement));
  }

  @override
  Future<Either<EmiFailure, List<CreditAgreement>>> listAgreements() async =>
      right([readCreditAgreement(agreement)]);

  @override
  Future<Either<EmiFailure, CreditAgreement>> getAgreement(String id) async =>
      right(readCreditAgreement(agreement));

  @override
  Future<Either<EmiFailure, CreditAgreement>> cancel({
    required String agreementId,
    required String idempotencyKey,
  }) async {
    cancels++;
    return right(readCreditAgreement(agreement));
  }

  @override
  Future<Either<EmiFailure, PlanPaymentStart>> startPayment({
    required String agreementId,
    required PaymentPurpose purpose,
    required PlanPaymentRail rail,
    required String idempotencyKey,
  }) async {
    payments.add((purpose: purpose, rail: rail, key: idempotencyKey));
    final failure = paymentFailure;
    return failure != null
        ? left(failure)
        : right(readPlanPaymentStart(paymentStartWire));
  }

  @override
  Future<Either<EmiFailure, PlanCheckout>> startCheckout(
    String agreementId,
  ) async {
    checkoutsStarted++;
    final failure = checkoutFailure;
    if (failure != null) return left(failure);
    return right(
      PlanCheckout(
        sessionId: 'session-$checkoutsStarted',
        title: 'Pashmina overcoat',
        option: 'M · Charcoal',
        price: const Money(amount: 60000, currency: 'NPR'),
      ),
    );
  }

  @override
  Future<Either<EmiFailure, List<ShippingAddress>>> deliveryAddresses() async =>
      right(addresses);

  @override
  Future<Either<EmiFailure, PlanCheckoutPlaced>> placeCheckout({
    required String sessionId,
    required String addressId,
    required PlanPaymentRail rail,
    required String idempotencyKey,
  }) async {
    placements.add((
      sessionId: sessionId,
      addressId: addressId,
      rail: rail,
      key: idempotencyKey,
    ));
    final failure = placeFailure;
    if (failure != null) return left(failure);
    agreement = {...agreement, 'orderId': planOrderId};
    return right(
      PlanCheckoutPlaced(
        orderNumber: 'NK2026-00042',
        redirectUrl: placedRedirect,
      ),
    );
  }

  @override
  Future<Either<EmiFailure, List<CreditAgreement>>> vendorAgreements({
    AgreementStatus? status,
  }) async => right([readCreditAgreement(agreement)]);

  @override
  Future<Either<EmiFailure, CreditAgreement>> vendorAgreement(
    String id,
  ) async => right(readCreditAgreement(agreement));

  @override
  Future<Either<EmiFailure, CreditAgreement>> vendorReview({
    required String agreementId,
    required bool approve,
    required List<String> reasons,
    required String idempotencyKey,
  }) async {
    reviews.add((approve: approve, reasons: reasons));
    final failure = reviewFailure;
    return failure != null
        ? left(failure)
        : right(readCreditAgreement(agreement));
  }

  @override
  Future<Either<EmiFailure, VendorCreditProgram>> vendorProgram() async =>
      right(readVendorCreditProgram(vendorProgramWire));

  @override
  Future<Either<EmiFailure, VendorCreditProgram>> putVendorProgram(
    VendorCreditProgram program, {
    required String idempotencyKey,
  }) async {
    programs.add(program);
    return right(program);
  }
}
