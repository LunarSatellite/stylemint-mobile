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

/// Wire shape for the backend's `PayoutMethodDto` (Identity module).
/// `kind` is the backend's int enum `PayoutMethodKind`: NimbBank=1,
/// LaxmiBank=2, PayPal=3, Esewa=4 (locked v1.1 spec — exactly these four).
/// `isPrimary` maps to the domain's `isDefault`.
class PayoutMethodDto {
  const PayoutMethodDto({
    required this.id,
    required this.kind,
    required this.label,
    this.isPrimary = false,
  });

  factory PayoutMethodDto.fromJson(Map<String, dynamic> json) =>
      PayoutMethodDto(
        id: json['id'] as String,
        kind: json['kind'] as int,
        label: json['label'] as String? ?? '',
        isPrimary: json['isPrimary'] as bool? ?? false,
      );

  final String id;
  final int kind;
  final String label;
  final bool isPrimary;

  PayoutMethod toDomain() => PayoutMethod(
    id: id,
    type: _typeFromKind(kind),
    label: label,
    isDefault: isPrimary,
  );

  /// Both bank kinds (NimbBank=1, LaxmiBank=2) collapse to
  /// [PayoutMethodType.bankTransfer] — the app doesn't yet distinguish
  /// which bank a payout method targets in its display model.
  static PayoutMethodType _typeFromKind(int kind) => switch (kind) {
    3 => PayoutMethodType.paypal,
    4 => PayoutMethodType.esewa,
    _ => PayoutMethodType.bankTransfer,
  };
}
