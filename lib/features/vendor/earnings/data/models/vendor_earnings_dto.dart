import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_earnings_dto.freezed.dart';
part 'vendor_earnings_dto.g.dart';

@freezed
abstract class VendorEarningsSummaryDto with _$VendorEarningsSummaryDto {
  const factory VendorEarningsSummaryDto({
    required double totalRevenueAmount,
    @Default('NPR') String totalRevenueCurrency,
    required double pendingPayoutAmount,
    @Default('NPR') String pendingPayoutCurrency,
    required double availableBalanceAmount,
    @Default('NPR') String availableBalanceCurrency,
    required double thisMonthAmount,
    @Default('NPR') String thisMonthCurrency,
    required double lastMonthAmount,
    @Default('NPR') String lastMonthCurrency,
    required int totalOrders,
    required double platformFeesAmount,
    @Default('NPR') String platformFeesCurrency,
    DateTime? nextPayoutDate,
  }) = _VendorEarningsSummaryDto;

  const VendorEarningsSummaryDto._();

  factory VendorEarningsSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$VendorEarningsSummaryDtoFromJson(json);

  VendorEarningsSummary toDomain() => VendorEarningsSummary(
    totalRevenue: Money(
      amount: totalRevenueAmount,
      currency: totalRevenueCurrency,
    ),
    pendingPayout: Money(
      amount: pendingPayoutAmount,
      currency: pendingPayoutCurrency,
    ),
    availableBalance: Money(
      amount: availableBalanceAmount,
      currency: availableBalanceCurrency,
    ),
    thisMonth: Money(
      amount: thisMonthAmount,
      currency: thisMonthCurrency,
    ),
    lastMonth: Money(
      amount: lastMonthAmount,
      currency: lastMonthCurrency,
    ),
    totalOrders: totalOrders,
    platformFees: Money(
      amount: platformFeesAmount,
      currency: platformFeesCurrency,
    ),
    nextPayoutDate: nextPayoutDate,
  );
}

@freezed
abstract class VendorEarningsLedgerDto with _$VendorEarningsLedgerDto {
  const factory VendorEarningsLedgerDto({
    required String id,
    required String type,
    String? orderNumber,
    @Default('') String description,
    required double amountAmount,
    @Default('NPR') String amountCurrency,
    required double balanceAmount,
    @Default('NPR') String balanceCurrency,
    required DateTime createdAt,
  }) = _VendorEarningsLedgerDto;

  const VendorEarningsLedgerDto._();

  factory VendorEarningsLedgerDto.fromJson(Map<String, dynamic> json) =>
      _$VendorEarningsLedgerDtoFromJson(json);

  VendorEarningsLedger toDomain() {
    final typeEnum = VendorLedgerType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => VendorLedgerType.sale,
    );
    return VendorEarningsLedger(
      id: id,
      type: typeEnum,
      orderNumber: orderNumber,
      description: description,
      amount: Money(amount: amountAmount, currency: amountCurrency),
      balance: Money(amount: balanceAmount, currency: balanceCurrency),
      createdAt: createdAt,
    );
  }
}

@freezed
abstract class VendorPayoutMethodDto with _$VendorPayoutMethodDto {
  const factory VendorPayoutMethodDto({
    required String id,
    required String type,
    required String label,
    @Default('') String accountInfo,
    @Default(false) bool isDefault,
  }) = _VendorPayoutMethodDto;

  const VendorPayoutMethodDto._();

  factory VendorPayoutMethodDto.fromJson(Map<String, dynamic> json) =>
      _$VendorPayoutMethodDtoFromJson(json);

  VendorPayoutMethod toDomain() {
    final typeEnum = VendorPayoutMethodType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => VendorPayoutMethodType.bank,
    );
    return VendorPayoutMethod(
      id: id,
      type: typeEnum,
      label: label,
      accountInfo: accountInfo,
      isDefault: isDefault,
    );
  }
}
