import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class EarningsSummary {
  const EarningsSummary({
    required this.totalEarnings,
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalCommission,
    required this.thisMonthEarnings,
    required this.totalPayouts,
  });

  final Money totalEarnings;
  final Money availableBalance;
  final Money pendingBalance;
  final double totalCommission;
  final Money thisMonthEarnings;
  final Money totalPayouts;

  EarningsSummary copyWith({
    Money? totalEarnings,
    Money? availableBalance,
    Money? pendingBalance,
    double? totalCommission,
    Money? thisMonthEarnings,
    Money? totalPayouts,
  }) {
    return EarningsSummary(
      totalEarnings: totalEarnings ?? this.totalEarnings,
      availableBalance: availableBalance ?? this.availableBalance,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      totalCommission: totalCommission ?? this.totalCommission,
      thisMonthEarnings: thisMonthEarnings ?? this.thisMonthEarnings,
      totalPayouts: totalPayouts ?? this.totalPayouts,
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

enum PayoutMethodType { bankTransfer, esewa, paypal }

class PayoutMethod {
  const PayoutMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.isDefault,
  });

  final String id;
  final PayoutMethodType type;
  final String label;
  final bool isDefault;

  PayoutMethod copyWith({
    String? id,
    PayoutMethodType? type,
    String? label,
    bool? isDefault,
  }) {
    return PayoutMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
