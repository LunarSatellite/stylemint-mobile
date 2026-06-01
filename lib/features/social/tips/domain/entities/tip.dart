import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class Tip {
  const Tip({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatarUrl,
    required this.amount,
    required this.message,
    required this.createdAt,
    this.reelId,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String receiverId;
  final String receiverName;
  final String receiverAvatarUrl;
  final Money amount;
  final String message;
  final String? reelId;
  final DateTime createdAt;

  Tip copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? receiverId,
    String? receiverName,
    String? receiverAvatarUrl,
    Money? amount,
    String? message,
    String? reelId,
    DateTime? createdAt,
  }) {
    return Tip(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverAvatarUrl: receiverAvatarUrl ?? this.receiverAvatarUrl,
      amount: amount ?? this.amount,
      message: message ?? this.message,
      reelId: reelId ?? this.reelId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class TipBalance {
  const TipBalance({
    required this.availableBalance,
    required this.totalReceived,
    required this.totalSent,
    required this.pendingBalance,
  });

  final Money availableBalance;
  final Money totalReceived;
  final Money totalSent;
  final Money pendingBalance;

  TipBalance copyWith({
    Money? availableBalance,
    Money? totalReceived,
    Money? totalSent,
    Money? pendingBalance,
  }) {
    return TipBalance(
      availableBalance: availableBalance ?? this.availableBalance,
      totalReceived: totalReceived ?? this.totalReceived,
      totalSent: totalSent ?? this.totalSent,
      pendingBalance: pendingBalance ?? this.pendingBalance,
    );
  }
}
