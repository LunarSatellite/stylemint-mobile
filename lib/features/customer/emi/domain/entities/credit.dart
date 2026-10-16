import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Payment plans beyond phase 1's calculator: the Credit module's contract
/// (`/v1/credit/*`). EMI, pay later and pay-now-buy-later are one agreement
/// model with different settings, so they share these types.
///
/// Every enum carries the backend's pinned number. Those numbers cross the
/// API and are stored, so declaration order here never decides them.

enum PlanKind {
  instalment(1),
  payLater(2),
  prepay(3);

  const PlanKind(this.wire);
  final int wire;

  static PlanKind? fromWire(Object? raw) =>
      _byWire(values, raw, (k) => k.wire, {
        'instalment': instalment,
        'paylater': payLater,
        'prepay': prepay,
      });

  /// What the buyer calls it.
  String get label => switch (this) {
    instalment => 'EMI',
    payLater => 'Pay later',
    prepay => 'Pay now, buy later',
  };

  /// One line on what it means for the buyer.
  String get explainer => switch (this) {
    instalment =>
      'A down payment now, the rest monthly. Delivered after the down payment.',
    payLater =>
      'A first payment now, the rest monthly. Delivered after the first '
          'payment.',
    prepay => 'Pay monthly first. Delivered once the price is paid in full.',
  };
}

enum PlanGuarantor {
  vendor(1),
  platform(2),
  partner(3),
  none(4);

  const PlanGuarantor(this.wire);
  final int wire;

  static PlanGuarantor? fromWire(Object? raw) =>
      _byWire(values, raw, (g) => g.wire, {
        'vendor': vendor,
        'platform': platform,
        'partner': partner,
        'none': none,
      });

  /// Who stands behind the plan, said plainly.
  String get statement => switch (this) {
    vendor => 'The seller offers and approves this plan.',
    platform => 'StyleMint guarantees this plan to the seller.',
    partner => 'A licensed lending partner provides this plan.',
    none => 'Nothing is lent: you pay before you receive the item.',
  };
}

enum PlanInterest {
  none(0),
  flat(1),
  reducingBalance(2);

  const PlanInterest(this.wire);
  final int wire;

  static PlanInterest fromWire(Object? raw) =>
      _byWire(values, raw, (i) => i.wire, {
        'none': none,
        'flat': flat,
        'reducingbalance': reducingBalance,
      }) ??
      none;
}

enum AgreementStatus {
  pendingApproval(1),
  approved(2),
  active(3),
  completed(4),
  defaulted(5),
  declined(6),
  cancelled(7),
  expired(8),

  /// The plan had started and its order was cancelled before it shipped, or the
  /// item was returned: everything paid on it is refunded, and nothing more is
  /// owed.
  reversed(9);

  const AgreementStatus(this.wire);
  final int wire;

  static AgreementStatus? fromWire(Object? raw) =>
      _byWire(values, raw, (s) => s.wire, {
        'pendingapproval': pendingApproval,
        'approved': approved,
        'active': active,
        'completed': completed,
        'defaulted': defaulted,
        'declined': declined,
        'cancelled': cancelled,
        'expired': expired,
        'reversed': reversed,
      });

  String get label => switch (this) {
    pendingApproval => 'Waiting for approval',
    approved => 'Approved — first payment due',
    active => 'Active',
    completed => 'Paid off',
    defaulted => 'Defaulted',
    declined => 'Not approved',
    cancelled => 'Cancelled',
    expired => 'Expired',
    reversed => 'Refunded',
  };

  /// Finished one way or another: nothing more can be paid or decided.
  bool get isClosed =>
      this == completed ||
      this == defaulted ||
      this == declined ||
      this == cancelled ||
      this == expired ||
      this == reversed;
}

enum InstalmentStatus {
  scheduled(1),
  partiallyPaid(2),
  paid(3),
  overdue(4),
  waived(5);

  const InstalmentStatus(this.wire);
  final int wire;

  static InstalmentStatus fromWire(Object? raw) =>
      _byWire(values, raw, (s) => s.wire, {
        'scheduled': scheduled,
        'partiallypaid': partiallyPaid,
        'paid': paid,
        'overdue': overdue,
        'waived': waived,
      }) ??
      scheduled;

  bool get isSettled => this == paid || this == waived;
}

enum RiskBand {
  a(1),
  b(2),
  c(3),
  d(4);

  const RiskBand(this.wire);
  final int wire;

  static RiskBand? fromWire(Object? raw) =>
      _byWire(values, raw, (b) => b.wire, {'a': a, 'b': b, 'c': c, 'd': d});

  String get letter => name.toUpperCase();
}

/// What a payment is for. The server sets the amount from this; the app never
/// sends a figure.
enum PaymentPurpose {
  activation(1),
  instalment(2),
  payoff(3);

  const PaymentPurpose(this.wire);
  final int wire;
}

/// The online rails a plan can be paid on. Cash on delivery is not one: an
/// instalment has no parcel to hand over, so it would never capture.
enum PlanPaymentRail {
  card(1, 'Visa / Mastercard'),
  payPal(2, 'PayPal'),
  eSewa(3, 'eSewa'),

  /// EMI down payment only, collected by the rider at delivery.
  cashOnDelivery(4, 'Cash on delivery');

  /// The rails for paying online — every one but cash on delivery.
  static const online = [card, payPal, eSewa];

  const PlanPaymentRail(this.wire, this.label);
  final int wire;
  final String label;
}

// ── Plan options: the menu on a product page ────────────────────────────────

class PlanOption {
  const PlanOption({
    required this.kind,
    required this.guarantor,
    required this.interest,
    required this.minDownPaymentPercent,
    required this.maxDownPaymentPercent,
    required this.downPaymentFixed,
    required this.tenures,
    required this.fromMonthly,
    required this.fromDownPayment,
    required this.goodsBeforePaidInFull,
    required this.requiresVerifiedIdentity,
    this.requiresDocuments = false,
  });

  final PlanKind kind;
  final PlanGuarantor guarantor;
  final PlanInterest interest;
  final int minDownPaymentPercent;
  final int maxDownPaymentPercent;
  final bool downPaymentFixed;
  final List<int> tenures;
  final Money fromMonthly;
  final Money fromDownPayment;
  final bool goodsBeforePaidInFull;
  final bool requiresVerifiedIdentity;

  /// The seller decides from documents the buyer sends with the application:
  /// an identity document and proof of income. EMI on the seller's own stock.
  final bool requiresDocuments;

  int get longestTenure => tenures.isEmpty ? 0 : tenures.last;
}

class PlanOptions {
  const PlanOptions({
    required this.variantId,
    required this.price,
    required this.options,
  });

  final String variantId;
  final Money price;
  final List<PlanOption> options;

  PlanOption? of(PlanKind kind) {
    for (final option in options) {
      if (option.kind == kind) return option;
    }
    return null;
  }
}

// ── Quotes ──────────────────────────────────────────────────────────────────

class PlanScheduleLine {
  const PlanScheduleLine({
    required this.number,
    required this.monthsAfterStart,
    required this.amount,
    required this.principal,
    required this.interest,
  });

  final int number;
  final int monthsAfterStart;
  final Money amount;
  final Money principal;
  final Money interest;
}

/// A priced offer signed by the server. Accepting it means sending
/// [token] back unchanged; every figure here is for showing, never for
/// sending.
class CreditQuote {
  const CreditQuote({
    required this.token,
    required this.expiresAt,
    required this.kind,
    required this.guarantor,
    required this.price,
    required this.downPaymentPercent,
    required this.downPayment,
    required this.financed,
    required this.tenureMonths,
    required this.interest,
    required this.monthlyRatePercent,
    required this.totalInterest,
    required this.totalPayable,
    required this.aprPercent,
    required this.goodsBeforePaidInFull,
    required this.schedule,
    this.lateFee,
    this.lateFeeGraceDays = 0,
  });

  /// The flat fee charged once on an instalment more than [lateFeeGraceDays]
  /// days late, as the signed quote states it. Null or zero: no late fee.
  final Money? lateFee;
  final int lateFeeGraceDays;

  bool get chargesLateFee => (lateFee?.amount ?? 0) > 0;

  final String token;
  final DateTime expiresAt;
  final PlanKind kind;
  final PlanGuarantor guarantor;
  final Money price;
  final int downPaymentPercent;
  final Money downPayment;
  final Money financed;
  final int tenureMonths;
  final PlanInterest interest;
  final double monthlyRatePercent;
  final Money totalInterest;
  final Money totalPayable;
  final double aprPercent;
  final bool goodsBeforePaidInFull;
  final List<PlanScheduleLine> schedule;

  bool isExpiredAt(DateTime now) => !now.isBefore(expiresAt);
}

// ── Agreements ──────────────────────────────────────────────────────────────

class PlanInstalment {
  const PlanInstalment({
    required this.number,
    required this.dueDate,
    required this.scheduled,
    required this.lateFeeDue,
    required this.paid,
    required this.outstanding,
    required this.status,
    required this.paidAt,
    this.credited,
  });

  final int number;

  /// A calendar date in the business time zone; null until the plan starts.
  final DateTime? dueDate;
  final Money scheduled;
  final Money lateFeeDue;
  final Money paid;
  final Money outstanding;
  final InstalmentStatus status;
  final DateTime? paidAt;

  /// What a partial refund took off this payment: no longer owed. Null or zero
  /// when nothing was.
  final Money? credited;

  bool get wasCredited => (credited?.amount ?? 0) > 0;
}

class CreditAgreement {
  const CreditAgreement({
    required this.id,
    required this.productId,
    required this.variantId,
    required this.vendorAccountId,
    required this.buyerAccountId,
    required this.kind,
    required this.guarantor,
    required this.status,
    required this.reasons,
    required this.price,
    required this.downPayment,
    required this.financed,
    required this.tenureMonths,
    required this.interest,
    required this.totalInterest,
    required this.totalPayable,
    required this.aprPercent,
    required this.outstanding,
    required this.outstandingPrincipal,
    required this.payoffToday,
    required this.daysPastDue,
    required this.appliedAt,
    required this.approvalExpiresAt,
    required this.activatedAt,
    required this.goodsReleasedAt,
    required this.closedAt,
    required this.needsActivationPayment,
    required this.instalments,
    this.orderId,
    this.priceReduced,
    this.decisionNote,
    this.documentsSubmittedAt,
    this.cashOnDeliveryDownPaymentAllowed = false,
    this.downPaymentOnDelivery = false,
    this.lateFee,
    this.lateFeeGraceDays = 0,
    this.deliveredAt,
    this.reportedPaidToDate,
    this.reportedInstalmentsPaid,
    this.reportedInstalmentsRemaining,
    this.reportedNextInstalment,
    this.reportedLateFeesOutstanding,
  });

  /// The flat fee charged once on an instalment more than [lateFeeGraceDays]
  /// days late. Null or zero: this plan charges none.
  final Money? lateFee;
  final int lateFeeGraceDays;

  bool get chargesLateFee => (lateFee?.amount ?? 0) > 0;

  /// When the item reached the buyer; null until then (or from a server that
  /// does not say).
  final DateTime? deliveredAt;

  // What the server counts itself (EMI-after-delivery contract v1). Each is
  // null from a server that predates it; the getters below then count from
  // [instalments].
  final Money? reportedPaidToDate;
  final int? reportedInstalmentsPaid;
  final int? reportedInstalmentsRemaining;
  final PlanInstalment? reportedNextInstalment;
  final Money? reportedLateFeesOutstanding;

  /// Whether the plan has started, so its down payment has been paid.
  bool get _started =>
      activatedAt != null ||
      status == AgreementStatus.active ||
      status == AgreementStatus.completed ||
      status == AgreementStatus.defaulted;

  /// The down payment (once the plan started) plus everything paid on
  /// instalments, late fees included.
  Money get paidToDate {
    final reported = reportedPaidToDate;
    if (reported != null) return reported;
    var paid = _started ? downPayment.amount : 0.0;
    for (final i in instalments) {
      paid += i.paid.amount;
    }
    return Money(amount: paid, currency: price.currency);
  }

  /// Instalments settled: paid, waived or covered by a refund.
  int get instalmentsPaid =>
      reportedInstalmentsPaid ??
      instalments.where((i) => i.status.isSettled).length;

  /// Instalments still to pay.
  int get instalmentsRemaining =>
      reportedInstalmentsRemaining ??
      instalments.where((i) => !i.status.isSettled).length;

  /// The earliest instalment not yet settled.
  PlanInstalment? get nextInstalment => reportedNextInstalment ?? nextDue;

  /// Late fees charged and not yet paid, across the plan.
  Money get lateFeesOutstanding {
    final reported = reportedLateFeesOutstanding;
    if (reported != null) return reported;
    var fees = 0.0;
    for (final i in instalments) {
      if (!i.status.isSettled) fees += i.lateFeeDue.amount;
    }
    return Money(amount: fees, currency: price.currency);
  }

  /// Running, so a balance is being paid down month by month.
  bool get isRepaying =>
      status == AgreementStatus.active || status == AgreementStatus.defaulted;

  /// The seller's own words with their decision — a decline's reason.
  final String? decisionNote;

  /// When the buyer sent their documents to the seller; null until then.
  final DateTime? documentsSubmittedAt;

  /// EMI whose seller lets the down payment be paid in cash on delivery.
  final bool cashOnDeliveryDownPaymentAllowed;

  /// The down payment is to be collected in cash when the item arrives; the
  /// plan starts then.
  final bool downPaymentOnDelivery;

  final String id;
  final String productId;
  final String variantId;
  final String vendorAccountId;
  final String buyerAccountId;
  final PlanKind kind;
  final PlanGuarantor guarantor;
  final AgreementStatus status;

  /// Reason codes behind the current state — why it was referred, declined.
  final List<String> reasons;
  final Money price;
  final Money downPayment;
  final Money financed;
  final int tenureMonths;
  final PlanInterest interest;
  final Money totalInterest;
  final Money totalPayable;
  final double aprPercent;
  final Money outstanding;
  final Money outstandingPrincipal;

  /// What settling in full would cost today; null when it cannot be settled.
  final Money? payoffToday;
  final int daysPastDue;
  final DateTime? appliedAt;
  final DateTime? approvalExpiresAt;
  final DateTime? activatedAt;
  final DateTime? goodsReleasedAt;
  final DateTime? closedAt;
  final bool needsActivationPayment;
  final List<PlanInstalment> instalments;

  /// How much partial refunds have taken off the price while the buyer kept
  /// the item — first off what was still owed, the rest paid back. Null or
  /// zero when none.
  final Money? priceReduced;

  /// The order checkout created for this plan. A plan starts with the order
  /// that delivers its item: approved with no order, it goes to checkout;
  /// approved with one, it is waiting for its first payment.
  final String? orderId;

  /// Reversed because the item came back, rather than because the order was
  /// cancelled before it shipped.
  bool get reversedForReturn =>
      status == AgreementStatus.reversed && reasons.contains('order_returned');

  /// Approved, and not yet checked out — the next step is checkout.
  bool get needsCheckout =>
      status == AgreementStatus.approved && (orderId?.isEmpty ?? true);

  /// The first instalment not yet settled.
  PlanInstalment? get nextDue {
    for (final i in instalments) {
      if (!i.status.isSettled) return i;
    }
    return null;
  }

  bool get hasOverdue =>
      instalments.any((i) => i.status == InstalmentStatus.overdue);

  /// Withdrawable only before any money has moved.
  bool get canCancel =>
      status == AgreementStatus.pendingApproval ||
      status == AgreementStatus.approved;

  /// The payment the buyer should be offered first, if any.
  PaymentPurpose? get primaryPayment => switch (status) {
    // A down payment due in cash is collected by the rider, not paid here.
    AgreementStatus.approved
        when needsActivationPayment &&
            !needsCheckout &&
            !downPaymentOnDelivery =>
      PaymentPurpose.activation,
    AgreementStatus.active when nextDue != null => PaymentPurpose.instalment,
    _ => null,
  };
}

// ── Where an instalment stands, for the buyer ───────────────────────────────

/// The contract's display rule: settled → paid; overdue → overdue; otherwise
/// the due date against today in Kathmandu.
enum InstalmentPhase {
  paid,
  overdue,

  /// Due today — or past its date while the server has not yet marked it
  /// overdue.
  dueToday,

  /// Due within the next [planDueSoonDays] days.
  dueSoon,
  upcoming,

  /// No date yet: the plan has not started.
  notStarted;

  bool get needsPaying =>
      this == overdue || this == dueToday || this == dueSoon;
}

/// How many days ahead "due soon" looks.
const int planDueSoonDays = 3;

/// Nepal Time is a fixed UTC+05:45 with no daylight saving.
const Duration _kathmanduOffset = Duration(hours: 5, minutes: 45);

/// Today's calendar date in Asia/Kathmandu, for [now] (any zone).
DateTime kathmanduToday(DateTime now) {
  final k = now.toUtc().add(_kathmanduOffset);
  return DateTime(k.year, k.month, k.day);
}

/// Days from [today] (a Kathmandu date) to [instalment]'s due date; null when
/// it has none.
int? daysUntilDue(PlanInstalment instalment, DateTime today) {
  final d = instalment.dueDate;
  if (d == null) return null;
  // Both are whole dates; UTC arithmetic keeps a DST shift out of it.
  return DateTime.utc(d.year, d.month, d.day)
      .difference(DateTime.utc(today.year, today.month, today.day))
      .inDays;
}

InstalmentPhase instalmentPhase(PlanInstalment instalment, DateTime today) {
  if (instalment.status.isSettled) return InstalmentPhase.paid;
  if (instalment.status == InstalmentStatus.overdue) {
    return InstalmentPhase.overdue;
  }
  final days = daysUntilDue(instalment, today);
  if (days == null) return InstalmentPhase.notStarted;
  if (days <= 0) return InstalmentPhase.dueToday;
  if (days <= planDueSoonDays) return InstalmentPhase.dueSoon;
  return InstalmentPhase.upcoming;
}

/// The one plan payment worth interrupting the buyer for: overdue, or due
/// within [planDueSoonDays] days.
class PlanDueAlert {
  const PlanDueAlert({
    required this.agreement,
    required this.instalment,
    required this.phase,
    required this.daysUntil,
  });

  final CreditAgreement agreement;
  final PlanInstalment instalment;
  final InstalmentPhase phase;

  /// Days until the due date; zero or less when due today or past.
  final int daysUntil;

  bool get isOverdue => phase == InstalmentPhase.overdue;

  /// Identifies this reminder, so dismissing it hides only this one.
  String get key => '${agreement.id}:${instalment.number}:${phase.name}';
}

/// The most pressing alert among [plans]: anything overdue first, then the
/// soonest due. Null when nothing is close.
PlanDueAlert? planDueAlert(
  List<CreditAgreement> plans,
  DateTime today, {
  Set<String> dismissed = const {},
}) {
  PlanDueAlert? best;
  int rank(PlanDueAlert a) => a.isOverdue ? 0 : 1;
  for (final plan in plans) {
    if (!plan.isRepaying) continue;
    PlanInstalment? pick;
    for (final i in plan.instalments) {
      if (i.status == InstalmentStatus.overdue) {
        pick = i;
        break;
      }
    }
    pick ??= plan.nextInstalment;
    if (pick == null) continue;
    final phase = instalmentPhase(pick, today);
    if (!phase.needsPaying) continue;
    final alert = PlanDueAlert(
      agreement: plan,
      instalment: pick,
      phase: phase,
      daysUntil: daysUntilDue(pick, today) ?? 0,
    );
    if (dismissed.contains(alert.key)) continue;
    final current = best;
    if (current == null ||
        rank(alert) < rank(current) ||
        (rank(alert) == rank(current) &&
            alert.daysUntil < current.daysUntil)) {
      best = alert;
    }
  }
  return best;
}

// ── The buyer's standing ────────────────────────────────────────────────────

class ScoreFactor {
  const ScoreFactor({required this.code, required this.points});

  final String code;
  final int points;
}

class CreditProfile {
  const CreditProfile({
    required this.score,
    required this.band,
    required this.creditLimit,
    required this.availableCredit,
    required this.outstandingPrincipal,
    required this.openAgreements,
    required this.identityVerified,
    required this.factors,
  });

  final int score;
  final RiskBand? band;
  final Money creditLimit;
  final Money availableCredit;
  final Money outstandingPrincipal;
  final int openAgreements;
  final bool identityVerified;
  final List<ScoreFactor> factors;
}

/// A started payment: where to send the buyer to complete it.
class PlanPaymentStart {
  const PlanPaymentStart({
    required this.attemptId,
    required this.agreementId,
    required this.amount,
    required this.redirectUrl,
  });

  final String attemptId;
  final String agreementId;
  final Money amount;

  /// The provider's page; null when the provider needs no hand-off.
  final String? redirectUrl;
}

/// A checkout for one item on an approved plan: the plan's item at the plan's
/// price. The cart is not involved.
class PlanCheckout {
  const PlanCheckout({
    required this.sessionId,
    required this.title,
    required this.price,
    this.option,
    this.thumbnailUrl,
  });

  final String sessionId;
  final String title;
  final String? option;
  final String? thumbnailUrl;

  /// What the order is for — the price the buyer agreed to.
  final Money price;
}

/// A placed plan checkout. The order exists; the plan pays for it.
class PlanCheckoutPlaced {
  const PlanCheckoutPlaced({required this.orderNumber, this.redirectUrl});

  final String orderNumber;

  /// Where to make the plan's first payment; null when nothing was due up
  /// front and the plan started at once.
  final String? redirectUrl;
}

// ── Vendor ──────────────────────────────────────────────────────────────────

/// A vendor's opt-in to pay later and prepay. EMI terms stay per product.
class VendorCreditProgram {
  const VendorCreditProgram({
    required this.payLaterEnabled,
    required this.payLaterTenures,
    required this.payLaterDownPaymentPercent,
    required this.payLaterAcceptedRiskFeePercent,
    required this.currentPlatformRiskFeePercent,
    required this.payLaterOffered,
    required this.prepayEnabled,
    required this.prepayTenures,
    required this.prepayDepositPercent,
  });

  final bool payLaterEnabled;
  final List<int> payLaterTenures;
  final int payLaterDownPaymentPercent;
  final double payLaterAcceptedRiskFeePercent;

  /// The fee StyleMint charges now. Pay later is offered only while the
  /// vendor has accepted exactly this figure.
  final double currentPlatformRiskFeePercent;
  final bool payLaterOffered;
  final bool prepayEnabled;
  final List<int> prepayTenures;
  final int prepayDepositPercent;

  /// Turned on, but the fee has changed since the vendor accepted it.
  bool get payLaterNeedsFeeAcceptance => payLaterEnabled && !payLaterOffered;
}

T? _byWire<T>(
  List<T> values,
  Object? raw,
  int Function(T) wire,
  Map<String, T> names,
) {
  if (raw is int) {
    for (final v in values) {
      if (wire(v) == raw) return v;
    }
    return null;
  }
  if (raw is num && raw == raw.roundToDouble()) {
    return _byWire(values, raw.toInt(), wire, names);
  }
  if (raw is String) {
    final trimmed = raw.trim();
    final asInt = int.tryParse(trimmed);
    if (asInt != null) return _byWire(values, asInt, wire, names);
    return names[trimmed.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '')];
  }
  return null;
}

/// What a document sent with an EMI application proves.
enum CreditDocumentKind {
  identity('Identity'),
  financial('Financial');

  const CreditDocumentKind(this.wire);
  final String wire;
}

/// A document sent with an EMI application. Never its location: the seller
/// asks for that one document at a time.
class CreditDocumentInfo {
  const CreditDocumentInfo({
    required this.id,
    required this.kind,
    required this.contentType,
  });

  final String id;
  final CreditDocumentKind kind;
  final String contentType;

  bool get isPdf => contentType == 'application/pdf';
}

/// An EMI application as the seller deciding it sees it. The buyer appears
/// by display name only — never a phone number or an email.
class VendorCreditApplication {
  const VendorCreditApplication({
    required this.agreement,
    required this.buyerDisplayName,
    required this.productName,
    required this.documents,
    required this.riskReasons,
    this.riskBand,
    this.riskScore,
  });

  final CreditAgreement agreement;
  final String buyerDisplayName;
  final String productName;
  final List<CreditDocumentInfo> documents;
  final List<String> riskReasons;

  /// A–D, as the server's scorecard banded the buyer.
  final String? riskBand;
  final int? riskScore;
}
