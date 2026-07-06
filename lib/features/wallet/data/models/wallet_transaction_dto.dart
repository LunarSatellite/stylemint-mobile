import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/wallet_transaction.dart';

part 'wallet_transaction_dto.freezed.dart';
part 'wallet_transaction_dto.g.dart';

@freezed
abstract class WalletTransactionDto with _$WalletTransactionDto {
  const factory WalletTransactionDto({
    required String id,
    required String walletId,
    required String currency,
    required String type,
    required String source,
    required double amount,
    required double balanceAfter,
    String? correlationId,
    String? correlationType,
    String? reversalOf,
    String? description,
    @Default('') String occurredUtc,
  }) = _WalletTransactionDto;

  const WalletTransactionDto._();

  factory WalletTransactionDto.fromJson(Map<String, dynamic> json) =>
      _$WalletTransactionDtoFromJson(json);

  WalletTransaction toDomain() => WalletTransaction(
        id: id,
        walletId: walletId,
        currency: currency,
        type: type,
        source: source,
        amount: amount,
        balanceAfter: balanceAfter,
        correlationId: correlationId,
        correlationType: correlationType,
        reversalOf: reversalOf,
        description: description,
        occurredUtc: occurredUtc.isNotEmpty
            ? DateTime.parse(occurredUtc)
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}
