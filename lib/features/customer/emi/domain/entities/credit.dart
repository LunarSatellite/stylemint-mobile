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
  eSewa(3, 'eSewa');

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
  });

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
  });

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
    AgreementStatus.approved when needsActivationPayment && !needsCheckout =>
      PaymentPurpose.activation,
    AgreementStatus.active when nextDue != null => PaymentPurpose.instalment,
    _ => null,
  };
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
