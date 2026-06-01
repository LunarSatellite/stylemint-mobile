import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'earnings_dto.freezed.dart';
part 'earnings_dto.g.dart';

@freezed
abstract class EarningsSummaryDto with _$EarningsSummaryDto {
  const factory EarningsSummaryDto({
    required double totalEarningsAmount,
    @Default('NPR') String totalEarningsCurrency,
    required double availableBalanceAmount,
    @Default('NPR') String availableBalanceCurrency,
    required double pendingBalanceAmount,
    @Default('NPR') String pendingBalanceCurrency,
    required double totalCommission,
    required double thisMonthEarningsAmount,
    @Default('NPR') String thisMonthEarningsCurrency,
    required double totalPayoutsAmount,
    @Default('NPR') String totalPayoutsCurrency,
  }) = _EarningsSummaryDto;

  const EarningsSummaryDto._();

  factory EarningsSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$EarningsSummaryDtoFromJson(json);

  EarningsSummary toDomain() => EarningsSummary(
    totalEarnings: Money(
      amount: totalEarningsAmount,
      currency: totalEarningsCurrency,
    ),
    availableBalance: Money(
      amount: availableBalanceAmount,
      currency: availableBalanceCurrency,
    ),
    pendingBalance: Money(
      amount: pendingBalanceAmount,
      currency: pendingBalanceCurrency,
    ),
    totalCommission: totalCommission,
    thisMonthEarnings: Money(
      amount: thisMonthEarningsAmount,
      currency: thisMonthEarningsCurrency,
    ),
    totalPayouts: Money(
      amount: totalPayoutsAmount,
      currency: totalPayoutsCurrency,
    ),
  );
}

@freezed
abstract class EarningsLedgerEntryDto with _$EarningsLedgerEntryDto {
  const factory EarningsLedgerEntryDto({
    required String id,
    required String type,
    required String description,
    required double amountAmount,
    @Default('NPR') String amountCurrency,
    required DateTime createdAt,
    String? reference,
  }) = _EarningsLedgerEntryDto;

  const EarningsLedgerEntryDto._();

  factory EarningsLedgerEntryDto.fromJson(Map<String, dynamic> json) =>
      _$EarningsLedgerEntryDtoFromJson(json);

  EarningsLedgerEntry toDomain() {
    final typeEnum = LedgerEntryType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => LedgerEntryType.commission,
    );
    return EarningsLedgerEntry(
      id: id,
      type: typeEnum,
      description: description,
      amount: Money(amount: amountAmount, currency: amountCurrency),
      createdAt: createdAt,
      reference: reference,
    );
  }
}

@freezed
abstract class PayoutMethodDto with _$PayoutMethodDto {
  const factory PayoutMethodDto({
    required String id,
    required String type,
    required String label,
    @Default(false) bool isDefault,
  }) = _PayoutMethodDto;

  const PayoutMethodDto._();

  factory PayoutMethodDto.fromJson(Map<String, dynamic> json) =>
      _$PayoutMethodDtoFromJson(json);

  PayoutMethod toDomain() {
    final typeEnum = PayoutMethodType.values.firstWhere(
      (t) => t.name == type,
      orElse: () => PayoutMethodType.bankTransfer,
    );
    return PayoutMethod(
      id: id,
      type: typeEnum,
      label: label,
      isDefault: isDefault,
    );
  }
}
