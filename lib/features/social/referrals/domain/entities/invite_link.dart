/// Mirrors backend `InviteLinkStatus` (1-based: Active=1..Revoked=3).
/// Expiry is NOT a persisted status — it's computed against `expiresAt`
/// at use time, same as the backend does against `ExpiresUtc`.
enum InviteLinkStatus { unknown, active, disabled, revoked }

/// A referral/invite link — backend `Networking.InviteLinkDto`.
class InviteLink {
  const InviteLink({
    required this.id,
    required this.code,
    required this.expiresAt,
    required this.redemptionCap,
    required this.redemptionCount,
    required this.status,
  });

  final String id;
  final String code;
  final DateTime expiresAt;
  final int? redemptionCap;
  final int redemptionCount;
  final InviteLinkStatus status;

  bool get isActive =>
      status == InviteLinkStatus.active && expiresAt.isAfter(DateTime.now());

  String get shareUrl => 'https://stylemint.dev/invite/$code';
}

class InviteRedemption {
  const InviteRedemption({
    required this.id,
    required this.redeemerAccountId,
    required this.redeemedAtUtc,
  });

  final String id;
  final String redeemerAccountId;
  final DateTime redeemedAtUtc;
}
