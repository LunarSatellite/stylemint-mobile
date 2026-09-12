import 'package:stylemint_mobile_frontend/features/social/referrals/domain/entities/invite_link.dart';

class InviteLinkDto {
  const InviteLinkDto({
    required this.id,
    required this.code,
    required this.expiresUtc,
    required this.redemptionCap,
    required this.redemptionCount,
    required this.status,
  });

  final String id;
  final String code;
  final DateTime expiresUtc;
  final int? redemptionCap;
  final int redemptionCount;
  final int status;

  factory InviteLinkDto.fromJson(Map<String, dynamic> json) => InviteLinkDto(
    id: json['id'] as String,
    code: json['code'] as String? ?? '',
    expiresUtc: DateTime.parse(json['expiresUtc'] as String),
    redemptionCap: json['redemptionCap'] as int?,
    redemptionCount: json['redemptionCount'] as int? ?? 0,
    status: json['status'] as int? ?? 0,
  );

  InviteLink toDomain() => InviteLink(
    id: id,
    code: code,
    expiresAt: expiresUtc,
    redemptionCap: redemptionCap,
    redemptionCount: redemptionCount,
    status: InviteLinkStatus.values[status.clamp(0, InviteLinkStatus.values.length - 1)],
  );
}

class InviteRedemptionDto {
  const InviteRedemptionDto({
    required this.id,
    required this.redeemerAccountId,
    required this.redeemedAtUtc,
  });

  final String id;
  final String redeemerAccountId;
  final DateTime redeemedAtUtc;

  factory InviteRedemptionDto.fromJson(Map<String, dynamic> json) => InviteRedemptionDto(
    id: json['id'] as String,
    redeemerAccountId: json['redeemerAccountId'] as String? ?? '',
    redeemedAtUtc: DateTime.parse(json['redeemedAtUtc'] as String),
  );

  InviteRedemption toDomain() => InviteRedemption(
    id: id,
    redeemerAccountId: redeemerAccountId,
    redeemedAtUtc: redeemedAtUtc,
  );
}
