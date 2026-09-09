import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_balance.dart';

part 'wallet_balance_dto.freezed.dart';
part 'wallet_balance_dto.g.dart';

// Backend sends status as int enum (StyleMint.Modules.Identity.Enums.WalletStatus,
// 1-based): 1=Active, 2=Frozen, 3=Closed.
String _statusFromJson(dynamic v) {
  if (v is String) return v;
  return switch (v as int) {
    2 => 'Frozen',
    3 => 'Closed',
    _ => 'Active',
  };
}

dynamic _statusToJson(String v) => v;

@freezed
abstract class WalletBalanceDto with _$WalletBalanceDto {
  const factory WalletBalanceDto({
    required String id,
    required String accountId,
    required String currency,
    required double available,
    required double pending,
    @Default(0.0) double reserved,
    @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
    @Default('Active')
    String status,
    @Default('') String updatedUtc,
    @Default('') String rowVersion,
  }) = _WalletBalanceDto;

  const WalletBalanceDto._();

  factory WalletBalanceDto.fromJson(Map<String, dynamic> json) =>
      _$WalletBalanceDtoFromJson(json);

  WalletBalance toDomain() => WalletBalance(
        id: id,
        accountId: accountId,
        currency: currency,
        available: available,
        pending: pending,
        status: status,
        updatedUtc: updatedUtc.isNotEmpty
            ? DateTime.parse(updatedUtc)
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}
