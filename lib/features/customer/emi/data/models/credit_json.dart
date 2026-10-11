import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/emi/domain/entities/credit.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Readers for the Credit module's payloads (`/v1/credit/*`).
///
/// The server sends plain decimals with one `currency` beside them, and enums
/// as their pinned numbers. Readers are tolerant in the usual way — a missing
/// field reads as absent — except where a missing value would change what a
/// buyer is told about money: an agreement or quote without a recognisable
/// kind or state is refused with a [FormatException] rather than guessed.

Money _money(Object? raw, String currency) =>
    Money(amount: readOptionalDouble(raw) ?? 0, currency: currency);

Money? _optionalMoney(Object? raw, String currency) {
  final amount = readOptionalDouble(raw);
  return amount == null ? null : Money(amount: amount, currency: currency);
}

String _currency(Map<String, dynamic> json) =>
    readOptionalString(json['currency']) ?? 'NPR';

List<int> _ints(Object? raw) => raw is List
    ? List.unmodifiable(raw.map(readInt).where((n) => n > 0))
    : const <int>[];

List<String> _strings(Object? raw) => raw is List
    ? List.unmodifiable(
        raw.whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty),
      )
    : const <String>[];

T _required<T>(T? value, String field) {
  if (value == null) throw FormatException('Credit payload: unreadable $field');
  return value;
}

PlanOptions readPlanOptions(Map<String, dynamic> json) {
  final currency = _currency(json);
  final options = <PlanOption>[];
  for (final raw
      in json['options'] is List ? json['options'] as List : const []) {
    if (raw is! Map) continue;
    final o = Map<String, dynamic>.from(raw);
    final kind = PlanKind.fromWire(o['kind']);
    final guarantor = PlanGuarantor.fromWire(o['guarantor']);
    final tenures = _ints(o['tenures']);
    // An option this build cannot name, or one with nothing to choose, is
    // left off rather than shown half-understood.
    if (kind == null || guarantor == null || tenures.isEmpty) continue;
    options.add(
      PlanOption(
        kind: kind,
        guarantor: guarantor,
        interest: PlanInterest.fromWire(o['interestMethod']),
        minDownPaymentPercent: readInt(o['minDownPaymentPercent']),
        maxDownPaymentPercent: readInt(o['maxDownPaymentPercent']),
        downPaymentFixed: readBool(o['downPaymentFixed']),
        tenures: tenures,
        fromMonthly: _money(o['fromMonthly'], currency),
        fromDownPayment: _money(o['fromDownPayment'], currency),
        goodsBeforePaidInFull: readBool(o['goodsReleasedBeforePaidInFull']),
        requiresVerifiedIdentity: readBool(o['requiresVerifiedIdentity']),
      ),
    );
  }
  return PlanOptions(
    variantId: readString(json['variantId']),
    price: _money(json['price'], currency),
    options: List.unmodifiable(options),
  );
}

List<PlanScheduleLine> _schedule(Object? raw, String currency) => [
  for (final line in raw is List ? raw : const [])
    if (line is Map)
      PlanScheduleLine(
        number: readInt(line['number']),
        monthsAfterStart: readInt(line['monthsAfterStart']),
        amount: _money(line['amount'], currency),
        principal: _money(line['principal'], currency),
        interest: _money(line['interest'], currency),
      ),
];

CreditQuote readCreditQuote(Map<String, dynamic> json) {
  final currency = _currency(json);
  final token = readString(json['quoteToken']);
  if (token.isEmpty) throw const FormatException('Credit quote: no token');
  return CreditQuote(
    token: token,
    expiresAt: _required(readDate(json['expiresUtc']), 'expiresUtc'),
    kind: _required(PlanKind.fromWire(json['kind']), 'kind'),
    guarantor: _required(
      PlanGuarantor.fromWire(json['guarantor']),
      'guarantor',
    ),
    price: _money(json['price'], currency),
    downPaymentPercent: readInt(json['downPaymentPercent']),
    downPayment: _money(json['downPayment'], currency),
    financed: _money(json['financed'], currency),
    tenureMonths: readInt(json['tenureMonths']),
    interest: PlanInterest.fromWire(json['interestMethod']),
    monthlyRatePercent: readOptionalDouble(json['monthlyRatePercent']) ?? 0,
    totalInterest: _money(json['totalInterest'], currency),
    totalPayable: _money(json['totalPayable'], currency),
    aprPercent: readOptionalDouble(json['aprPercent']) ?? 0,
    goodsBeforePaidInFull: readBool(json['goodsReleasedBeforePaidInFull']),
    schedule: List.unmodifiable(_schedule(json['schedule'], currency)),
    lateFee: _optionalMoney(json['lateFeeAmount'], currency),
    lateFeeGraceDays: readInt(json['lateFeeGraceDays']),
  );
}

PlanInstalment _instalment(Map<String, dynamic> json, String currency) =>
    PlanInstalment(
      number: readInt(json['number']),
      dueDate: readDate(json['dueDate']),
      scheduled: _money(json['scheduledAmount'], currency),
      lateFeeDue: _money(json['lateFeeDue'], currency),
      paid: _money(json['paid'], currency),
      outstanding: _money(json['outstanding'], currency),
      status: InstalmentStatus.fromWire(json['state']),
      paidAt: readDate(json['paidUtc']),
      credited: _optionalMoney(json['credited'], currency),
    );

CreditAgreement readCreditAgreement(Map<String, dynamic> json) {
  final currency = _currency(json);
  final id = readString(json['id']);
  if (id.isEmpty) throw const FormatException('Credit agreement: no id');
  final instalments = [
    for (final raw
        in json['instalments'] is List ? json['instalments'] as List : const [])
      if (raw is Map) _instalment(Map<String, dynamic>.from(raw), currency),
  ]..sort((a, b) => a.number.compareTo(b.number));
  return CreditAgreement(
    id: id,
    productId: readString(json['productId']),
    variantId: readString(json['variantId']),
    vendorAccountId: readString(json['vendorAccountId']),
    buyerAccountId: readString(json['buyerAccountId']),
    kind: _required(PlanKind.fromWire(json['kind']), 'kind'),
    guarantor: _required(
      PlanGuarantor.fromWire(json['guarantor']),
      'guarantor',
    ),
    status: _required(AgreementStatus.fromWire(json['state']), 'state'),
    reasons: _strings(json['stateReasons']),
    price: _money(json['price'], currency),
    downPayment: _money(json['downPayment'], currency),
    financed: _money(json['financed'], currency),
    tenureMonths: readInt(json['tenureMonths']),
    interest: PlanInterest.fromWire(json['interestMethod']),
    totalInterest: _money(json['totalInterest'], currency),
    totalPayable: _money(json['totalPayable'], currency),
    aprPercent: readOptionalDouble(json['aprPercent']) ?? 0,
    outstanding: _money(json['outstanding'], currency),
    outstandingPrincipal: _money(json['outstandingPrincipal'], currency),
    payoffToday: _optionalMoney(json['payoffAmountToday'], currency),
    daysPastDue: readInt(json['daysPastDue']),
    appliedAt: readDate(json['appliedUtc']),
    approvalExpiresAt: readDate(json['approvalExpiresUtc']),
    activatedAt: readDate(json['activatedUtc']),
    goodsReleasedAt: readDate(json['goodsReleasedUtc']),
    closedAt: readDate(json['closedUtc']),
    needsActivationPayment: readBool(json['needsActivationPayment']),
    instalments: List.unmodifiable(instalments),
    orderId: readOptionalString(json['orderId']),
    priceReduced: _optionalMoney(json['priceReduced'], currency),
  );
}

List<CreditAgreement> readCreditAgreements(Object? raw) {
  if (raw is! List) return const <CreditAgreement>[];
  final agreements = <CreditAgreement>[];
  for (final item in raw) {
    if (item is! Map) continue;
    try {
      agreements.add(readCreditAgreement(Map<String, dynamic>.from(item)));
    } on FormatException {
      // One unreadable row does not hide the buyer's other plans.
      continue;
    }
  }
  return List.unmodifiable(agreements);
}

CreditProfile readCreditProfile(Map<String, dynamic> json) {
  const currency = 'NPR';
  return CreditProfile(
    score: readInt(json['score']),
    band: RiskBand.fromWire(json['band']),
    creditLimit: _money(json['creditLimit'], currency),
    availableCredit: _money(json['availableCredit'], currency),
    outstandingPrincipal: _money(json['outstandingPrincipal'], currency),
    openAgreements: readInt(json['openAgreements']),
    identityVerified: readBool(json['identityVerified']),
    factors: List.unmodifiable([
      for (final f
          in json['factors'] is List ? json['factors'] as List : const [])
        if (f is Map && readString(f['code']).isNotEmpty)
          ScoreFactor(
            code: readString(f['code']),
            points: readInt(f['points']),
          ),
    ]),
  );
}

PlanPaymentStart readPlanPaymentStart(Map<String, dynamic> json) {
  final currency = _currency(json);
  final payment = json['payment'] is Map
      ? Map<String, dynamic>.from(json['payment'] as Map)
      : const <String, dynamic>{};
  return PlanPaymentStart(
    attemptId: readString(json['attemptId']),
    agreementId: readString(json['agreementId']),
    amount: _money(json['amount'], currency),
    redirectUrl: readOptionalString(payment['redirectUrl']),
  );
}

/// A payment-plan checkout session (`POST /v1/checkout/sessions/payment-plan`):
/// its id and its one item. Refused without either — there is nothing to
/// check out.
PlanCheckout readPlanCheckout(Map<String, dynamic> json) {
  final sessionId = readOptionalString(json['id']);
  final items = json['items'] is List
      ? json['items'] as List
      : const <Object?>[];
  final item = items.isEmpty || items.first is! Map
      ? null
      : Map<String, dynamic>.from(items.first as Map);
  if (sessionId == null || item == null) {
    throw const FormatException(
      'A plan checkout carries a session and its item.',
    );
  }
  return PlanCheckout(
    sessionId: sessionId,
    title: readOptionalString(item['productTitleSnapshot']) ?? '',
    option: readOptionalString(item['variantLabelSnapshot']),
    thumbnailUrl: readOptionalString(item['thumbnailUrlSnapshot']),
    price: _money(
      item['unitPriceAmount'],
      readOptionalString(item['unitPriceCurrency']) ?? 'NPR',
    ),
  );
}

VendorCreditProgram readVendorCreditProgram(Map<String, dynamic> json) =>
    VendorCreditProgram(
      payLaterEnabled: readBool(json['payLaterEnabled']),
      payLaterTenures: _ints(json['payLaterTenures']),
      payLaterDownPaymentPercent: readInt(json['payLaterDownPaymentPercent']),
      payLaterAcceptedRiskFeePercent:
          readOptionalDouble(json['payLaterAcceptedRiskFeePercent']) ?? 0,
      currentPlatformRiskFeePercent:
          readOptionalDouble(json['currentPlatformRiskFeePercent']) ?? 0,
      payLaterOffered: readBool(json['payLaterOffered']),
      prepayEnabled: readBool(json['prepayEnabled']),
      prepayTenures: _ints(json['prepayTenures']),
      prepayDepositPercent: readInt(json['prepayDepositPercent']),
    );
