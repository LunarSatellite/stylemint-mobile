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

/// Mirrors `GET /v1/earnings/balance`.
@freezed
abstract class VendorEarningsBalanceDto with _$VendorEarningsBalanceDto {
  const factory VendorEarningsBalanceDto({
    @Default(0) double availableValue,
    @Default(0) double pendingValue,
    @Default(0) double lifetimeValue,
    @Default('NPR') String currency,
  }) = _VendorEarningsBalanceDto;

  const VendorEarningsBalanceDto._();

  factory VendorEarningsBalanceDto.fromJson(Map<String, dynamic> json) =>
      _$VendorEarningsBalanceDtoFromJson(json);

  VendorEarningsBalance toDomain() => VendorEarningsBalance(
    available: Money(amount: availableValue, currency: currency),
    pending: Money(amount: pendingValue, currency: currency),
    lifetime: Money(amount: lifetimeValue, currency: currency),
  );
}

/// Mirrors an item of `GET /v1/earnings/entries` — `kind` is the backend's
/// int-valued `LedgerEntryKind` (1=Commission, 2=VendorNet, 3=Reversal,
/// 4=PayoutDebit, 5=FeeDebit, 6=BoostFeeDebit), not a string.
@freezed
abstract class VendorEarningsLedgerDto with _$VendorEarningsLedgerDto {
  const factory VendorEarningsLedgerDto({
    required String id,
    required int kind,
    String? orderId,
    String? note,
    @Default(0) double amountValue,
    @Default('NPR') String amountCurrency,
    required DateTime occurredUtc,
  }) = _VendorEarningsLedgerDto;

  const VendorEarningsLedgerDto._();

  factory VendorEarningsLedgerDto.fromJson(Map<String, dynamic> json) =>
      _$VendorEarningsLedgerDtoFromJson(json);

  VendorEarningsLedger toDomain() => VendorEarningsLedger(
    id: id,
    type: switch (kind) {
      3 => VendorLedgerType.refund,
      4 => VendorLedgerType.payout,
      5 || 6 => VendorLedgerType.fee,
      _ => VendorLedgerType.sale,
    },
    orderId: orderId,
    note: note,
    amount: Money(amount: amountValue, currency: amountCurrency),
    occurredAt: occurredUtc,
  );
}
