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

enum VendorLedgerType { sale, refund, payout, fee }

class VendorEarningsLedger {
  const VendorEarningsLedger({
    required this.id,
    required this.type,
    this.orderNumber,
    this.description = '',
    required this.amount,
    required this.balance,
    required this.createdAt,
  });

  final String id;
  final VendorLedgerType type;
  final String? orderNumber;
  final String description;
  final Money amount;
  final Money balance;
  final DateTime createdAt;

  VendorEarningsLedger copyWith({
    String? id,
    VendorLedgerType? type,
    String? orderNumber,
    String? description,
    Money? amount,
    Money? balance,
    DateTime? createdAt,
  }) {
    return VendorEarningsLedger(
      id: id ?? this.id,
      type: type ?? this.type,
      orderNumber: orderNumber ?? this.orderNumber,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum VendorPayoutMethodType { bank, eSewa, PayPal }

class VendorPayoutMethod {
  const VendorPayoutMethod({
    required this.id,
    required this.type,
    required this.label,
    required this.accountInfo,
    this.isDefault = false,
  });

  final String id;
  final VendorPayoutMethodType type;
  final String label;
  final String accountInfo;
  final bool isDefault;

  VendorPayoutMethod copyWith({
    String? id,
    VendorPayoutMethodType? type,
    String? label,
    String? accountInfo,
    bool? isDefault,
  }) {
    return VendorPayoutMethod(
      id: id ?? this.id,
      type: type ?? this.type,
      label: label ?? this.label,
      accountInfo: accountInfo ?? this.accountInfo,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
