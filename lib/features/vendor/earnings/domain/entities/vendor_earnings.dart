import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class VendorEarningsSummary {
  const VendorEarningsSummary({
    required this.totalRevenue,
    required this.pendingPayout,
    required this.availableBalance,
    required this.thisMonth,
    required this.lastMonth,
    required this.totalOrders,
    required this.platformFees,
    this.nextPayoutDate,
  });

  final Money totalRevenue;
  final Money pendingPayout;
  final Money availableBalance;
  final Money thisMonth;
  final Money lastMonth;
  final int totalOrders;
  final Money platformFees;
  final DateTime? nextPayoutDate;

  VendorEarningsSummary copyWith({
    Money? totalRevenue,
    Money? pendingPayout,
    Money? availableBalance,
    Money? thisMonth,
    Money? lastMonth,
    int? totalOrders,
    Money? platformFees,
    DateTime? nextPayoutDate,
  }) {
    return VendorEarningsSummary(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      pendingPayout: pendingPayout ?? this.pendingPayout,
      availableBalance: availableBalance ?? this.availableBalance,
      thisMonth: thisMonth ?? this.thisMonth,
      lastMonth: lastMonth ?? this.lastMonth,
      totalOrders: totalOrders ?? this.totalOrders,
      platformFees: platformFees ?? this.platformFees,
      nextPayoutDate: nextPayoutDate ?? this.nextPayoutDate,
    );
  }
}

/// Mirrors `GET /v1/earnings/balance` — the true payout-eligible ledger
/// balance (distinct from [VendorEarningsSummary.availableBalance], which
/// comes from the Brand Studio analytics rollup, not the Payouts ledger).
class VendorEarningsBalance {
  const VendorEarningsBalance({
    required this.available,
    required this.pending,
    required this.lifetime,
  });

  final Money available;
  final Money pending;
  final Money lifetime;
}

/// Mirrors the backend's `LedgerEntryKind` (skill §2): Commission=1,
/// VendorNet=2, Reversal=3, PayoutDebit=4, FeeDebit=5, BoostFeeDebit=6.
enum VendorLedgerType { sale, refund, payout, fee }

class VendorEarningsLedger {
  const VendorEarningsLedger({
    required this.id,
    required this.type,
    this.orderId,
    this.note,
    required this.amount,
    required this.occurredAt,
  });

  final String id;
  final VendorLedgerType type;
  final String? orderId;
  final String? note;
  final Money amount;
  final DateTime occurredAt;

  VendorEarningsLedger copyWith({
    String? id,
    VendorLedgerType? type,
    String? orderId,
    String? note,
    Money? amount,
    DateTime? occurredAt,
  }) {
    return VendorEarningsLedger(
      id: id ?? this.id,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      note: note ?? this.note,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
    );
  }
}

/// Mirrors the backend's `PayoutState` (skill §12): Requested=1,
/// Processing=2, Paid=3, Failed=4, Held=5.
enum VendorPayoutState { requested, processing, paid, failed, held }

/// A single row of `GET /v1/payouts` — one payout request/run, distinct from
/// [VendorEarningsLedger] which is the underlying per-sale/fee ledger.
class VendorPayout {
  const VendorPayout({
    required this.id,
    required this.destinationKind,
    required this.destinationRef,
    required this.requestedAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.requestedAt,
    required this.state,
    this.paidAt,
    this.failureMessage,
  });

  final String id;
  final int destinationKind;
  final String destinationRef;
  final Money requestedAmount;
  final Money feeAmount;
  final Money netAmount;
  final DateTime requestedAt;
  final VendorPayoutState state;
  final DateTime? paidAt;
  final String? failureMessage;
}

class VendorPayoutInvoiceLine {
  const VendorPayoutInvoiceLine({
    required this.description,
    required this.amount,
    required this.occurredAt,
  });

  final String description;
  final Money amount;
  final DateTime occurredAt;
}

/// Mirrors `GET /v1/payouts/{id}/invoice` — the printable receipt payload
/// for a single payout. [lines] is empty when the bridge layer hasn't
/// wired the earnings-ledger lookup yet; the receipt still renders.
class VendorPayoutInvoice {
  const VendorPayoutInvoice({
    required this.payoutId,
    required this.invoiceNumber,
    required this.destinationKind,
    required this.destinationRef,
    required this.grossAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.requestedAt,
    required this.state,
    this.paidAt,
    this.providerPayoutId,
    this.lines = const [],
  });

  final String payoutId;
  final String invoiceNumber;
  final int destinationKind;
  final String destinationRef;
  final Money grossAmount;
  final Money feeAmount;
  final Money netAmount;
  final DateTime requestedAt;
  final VendorPayoutState state;
  final DateTime? paidAt;
  final String? providerPayoutId;
  final List<VendorPayoutInvoiceLine> lines;
}
