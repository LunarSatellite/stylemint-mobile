import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/tips/domain/entities/tip.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'tip_dto.freezed.dart';
part 'tip_dto.g.dart';

@freezed
abstract class TipDto with _$TipDto {
  const factory TipDto({
    required String id,
    required String senderId,
    required String senderName,
    required String senderAvatarUrl,
    required String receiverId,
    required String receiverName,
    required String receiverAvatarUrl,
    required double amount,
    @Default('NPR') String currency,
    @Default('') String message,
    String? reelId,
    required DateTime createdAt,
  }) = _TipDto;

  const TipDto._();

  factory TipDto.fromJson(Map<String, dynamic> json) =>
      _$TipDtoFromJson(json);

  Tip toDomain() => Tip(
    id: id,
    senderId: senderId,
    senderName: senderName,
    senderAvatarUrl: senderAvatarUrl,
    receiverId: receiverId,
    receiverName: receiverName,
    receiverAvatarUrl: receiverAvatarUrl,
    amount: Money(amount: amount, currency: currency),
    message: message,
    reelId: reelId,
    createdAt: createdAt,
  );
}

@freezed
abstract class TipBalanceDto with _$TipBalanceDto {
  const factory TipBalanceDto({
    required double availableAmount,
    @Default('NPR') String availableCurrency,
    required double totalReceivedAmount,
    @Default('NPR') String totalReceivedCurrency,
    required double totalSentAmount,
    @Default('NPR') String totalSentCurrency,
    required double pendingAmount,
    @Default('NPR') String pendingCurrency,
  }) = _TipBalanceDto;

  const TipBalanceDto._();

  factory TipBalanceDto.fromJson(Map<String, dynamic> json) =>
      _$TipBalanceDtoFromJson(json);

  TipBalance toDomain() => TipBalance(
    availableBalance:
        Money(amount: availableAmount, currency: availableCurrency),
    totalReceived:
        Money(amount: totalReceivedAmount, currency: totalReceivedCurrency),
    totalSent:
        Money(amount: totalSentAmount, currency: totalSentCurrency),
    pendingBalance:
        Money(amount: pendingAmount, currency: pendingCurrency),
  );
}
