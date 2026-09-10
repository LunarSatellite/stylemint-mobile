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

  factory TipDto.fromJson(Map<String, dynamic> json) => _$TipDtoFromJson(json);

  factory TipDto.fromHistoryJson(Map<String, dynamic> json) {
    final amount = json['amount'] as Map<String, dynamic>? ?? const {};
    return TipDto(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'StyleMint customer',
      senderAvatarUrl: json['senderAvatarUrl'] as String? ?? '',
      receiverId: json['receiverId'] as String? ?? '',
      receiverName: json['receiverName'] as String? ?? 'Creator',
      receiverAvatarUrl: json['receiverAvatarUrl'] as String? ?? '',
      amount: (amount['amount'] as num?)?.toDouble() ?? 0,
      currency: amount['currency'] as String? ?? 'NPR',
      reelId: json['reelId'] as String?,
      createdAt: _date(json['createdAt']),
    );
  }

  factory TipDto.fromTipJson(Map<String, dynamic> json) {
    final amount = json['amount'] as Map<String, dynamic>? ?? const {};
    return TipDto(
      id: json['id'] as String? ?? '',
      senderId: json['fromAccountId'] as String? ?? '',
      senderName: 'You',
      senderAvatarUrl: '',
      receiverId: json['toCreatorProfileId'] as String? ?? '',
      receiverName: 'Creator',
      receiverAvatarUrl: '',
      amount: (amount['amount'] as num?)?.toDouble() ?? 0,
      currency: amount['currency'] as String? ?? 'NPR',
      reelId: json['reelId'] as String?,
      createdAt: _date(json['initiatedUtc']),
    );
  }

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

  static DateTime _date(dynamic value) =>
      DateTime.tryParse(value as String? ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
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

  factory TipBalanceDto.fromApiJson(Map<String, dynamic> json) {
    ({double amount, String currency}) money(String key) {
      final value = json[key] as Map<String, dynamic>? ?? const {};
      return (
        amount: (value['amount'] as num?)?.toDouble() ?? 0,
        currency: value['currency'] as String? ?? 'NPR',
      );
    }

    final available = money('availableBalance');
    final received = money('totalReceived');
    final sent = money('totalSent');
    final pending = money('pendingBalance');
    return TipBalanceDto(
      availableAmount: available.amount,
      availableCurrency: available.currency,
      totalReceivedAmount: received.amount,
      totalReceivedCurrency: received.currency,
      totalSentAmount: sent.amount,
      totalSentCurrency: sent.currency,
      pendingAmount: pending.amount,
      pendingCurrency: pending.currency,
    );
  }

  TipBalance toDomain() => TipBalance(
    availableBalance: Money(
      amount: availableAmount,
      currency: availableCurrency,
    ),
    totalReceived: Money(
      amount: totalReceivedAmount,
      currency: totalReceivedCurrency,
    ),
    totalSent: Money(amount: totalSentAmount, currency: totalSentCurrency),
    pendingBalance: Money(amount: pendingAmount, currency: pendingCurrency),
  );
}
