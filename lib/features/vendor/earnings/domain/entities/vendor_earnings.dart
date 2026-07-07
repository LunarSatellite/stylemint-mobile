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
