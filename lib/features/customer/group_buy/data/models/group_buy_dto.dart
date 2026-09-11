import 'package:stylemint_mobile_frontend/features/customer/group_buy/domain/entities/group_buy.dart';

/// Manual mapping (not freezed) — backend `GroupBuyState` is a 0-based int
/// enum (Open/Fulfilled/Expired/Cancelled); everything else is a direct
/// field-name match off `GroupBuyDto`.
class GroupBuyDto {
  const GroupBuyDto({
    required this.id,
    required this.productId,
    required this.initiatorAccountId,
    required this.targetBuyerCount,
    required this.discountPercent,
    required this.commitCount,
    required this.state,
    required this.expiresUtc,
  });

  final String id;
  final String productId;
  final String initiatorAccountId;
  final int targetBuyerCount;
  final double discountPercent;
  final int commitCount;
  final int state;
  final DateTime expiresUtc;

  factory GroupBuyDto.fromJson(Map<String, dynamic> json) => GroupBuyDto(
    id: json['id'] as String,
    productId: json['productId'] as String,
    initiatorAccountId: json['initiatorAccountId'] as String? ?? '',
    targetBuyerCount: json['targetBuyerCount'] as int? ?? 0,
    discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
    commitCount: json['commitCount'] as int? ?? 0,
    state: json['state'] as int? ?? 0,
    expiresUtc: DateTime.parse(json['expiresUtc'] as String),
  );

  GroupBuy toDomain() => GroupBuy(
    id: id,
    productId: productId,
    initiatorAccountId: initiatorAccountId,
    targetBuyerCount: targetBuyerCount,
    discountPercent: discountPercent,
    commitCount: commitCount,
    // Backend GroupBuyState is 1-based (Open=1..Cancelled=5); the Dart enum
    // reserves index 0 for "unknown" so the ordinals line up directly.
    state: GroupBuyState.values[state.clamp(0, GroupBuyState.values.length - 1)],
    expiresAt: expiresUtc,
  );
}
