import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class MonthlySummary {
  const MonthlySummary({
    required this.thisMonthEarnings,
    required this.salesCount,
    required this.reelCount,
    required this.avgPerSale,
    required this.highestReelEarnings,
  });

  final Money thisMonthEarnings;
  final int salesCount;
  final int reelCount;
  final Money avgPerSale;
  final Money highestReelEarnings;
}

/// The three fields `GET /v1/earnings/balance` actually returns
/// (`LedgerBalanceDto`: available, pending, lifetime).
///
/// `totalCommission`, `thisMonthEarnings` and `totalPayouts` used to sit
/// here too. That endpoint sends none of them, so `toDomain` filled all
/// three with literal zeros — a `double 0` and two `Money(amount: 0)` —
/// and the mapper's own comment said they "default to zero until a
/// confirmed source is wired". Nothing rendered them, which is the only
/// reason no creator was ever told they had been paid Rs 0 in total. They
/// are removed rather than left loaded: a money field whose only producer
/// is a constant is a rendering waiting to happen, and this app has drawn
/// that exact "Rs 0" before, on the Active Partnerships card.
///
/// The month-to-date figures are real and already have a home:
/// [MonthlySummary], from `GET /v1/earnings/summary`, which the earnings
/// screen reads through `monthlyEarningsSummaryProvider`. Lifetime
/// payouts have no producer at all — Payouts has no per-payee payout
/// total endpoint — so nothing here can stand in for one.
class EarningsSummary {
  const EarningsSummary({
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingBalance,
  });

  final Money totalEarnings;
  final Money availableBalance;
  final Money pendingBalance;

  EarningsSummary copyWith({
    Money? totalEarnings,
    Money? availableBalance,
    Money? pendingBalance,
  }) {
    return EarningsSummary(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
    );
  }
}

enum LedgerEntryType { commission, payout, bonus, adjustment }

class EarningsLedgerEntry {
  const EarningsLedgerEntry({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.createdAt,
    this.reference,
  });

  final String id;
  final LedgerEntryType type;
  final String description;
  final Money amount;
  final DateTime createdAt;
  final String? reference;

  EarningsLedgerEntry copyWith({
    String? id,
    LedgerEntryType? type,
    String? description,
    Money? amount,
    DateTime? createdAt,
    String? reference,
  }) {
    return EarningsLedgerEntry(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      reference: reference ?? this.reference,
    );
  }
}

/// Mirrors backend `PayoutDestinationKind`: NIMB=1, Laxmi=2, PayPal=3,
/// eSewa=4. These are the only payout destinations supported in v1.
enum PayoutMethodType { nimbBank, laxmiBank, paypal, esewa }

enum PayoutState { requested, processing, paid, failed, held }

enum PayoutMode { automaticWeekly, onDemand }

class PayoutRecord {
  const PayoutRecord({
    required this.id,
    required this.requestedAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.state,
    required this.mode,
    required this.destinationLabel,
    required this.requestedAt,
    this.destinationRef,
    this.paidAt,
  });

  final String id;
  final Money requestedAmount;
  final Money feeAmount;
  final Money netAmount;
  final PayoutState state;
  final PayoutMode mode;
  final String destinationLabel;
  final String? destinationRef;
  final DateTime requestedAt;
  final DateTime? paidAt;
}

class PayoutMethod {
  const PayoutMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.isPrimary,
  });

  final String id;
  final PayoutMethodType type;
  final String label;
  final bool isPrimary;

  PayoutMethod copyWith({
    String? id,
    PayoutMethodType? type,
    String? label,
    bool? isPrimary,
  }) {
    return PayoutMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

class PayoutInvoiceLine {
  const PayoutInvoiceLine({
    required this.description,
    required this.amount,
    required this.occurredAt,
  });

  final String description;
  final Money amount;
  final DateTime occurredAt;
}

class PayoutInvoice {
  const PayoutInvoice({
    required this.payoutId,
    required this.invoiceNumber,
    required this.destinationLabel,
    required this.grossAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.requestedAt,
    required this.state,
    this.destinationRef,
    this.paidAt,
    this.providerPayoutId,
    this.lines = const [],
  });

  final String payoutId;
  final String invoiceNumber;
  final String destinationLabel;
  final String? destinationRef;
  final Money grossAmount;
  final Money feeAmount;
  final Money netAmount;
  final DateTime requestedAt;
  final DateTime? paidAt;
  final PayoutState state;
  final String? providerPayoutId;
  final List<PayoutInvoiceLine> lines;
}
