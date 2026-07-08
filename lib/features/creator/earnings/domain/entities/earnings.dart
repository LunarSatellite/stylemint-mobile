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

/// The 4 payout destinations the backend actually supports (locked v1.1
/// spec — `Identity.Enums.PayoutMethodKind`). Distinct from
/// [PayoutMethodType]: that's the display bucket for an *existing* method;
/// this is what the caller must pick when *adding* one, since NimbBank and
/// LaxmiBank are different backend kinds even though both display as
/// "Bank A/C".
enum PayoutDestinationKind {
  nimbBank(1),
  laxmiBank(2),
  paypal(3),
  esewa(4);

  const PayoutDestinationKind(this.code);

  final int code;
}

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
