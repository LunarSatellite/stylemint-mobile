/// `CreatorChipDto` from `/api/v1/customer/feed/creators-you-may-like`.
class CreatorChipDto {
  const CreatorChipDto({
    required this.accountId,
    required this.handle,
    required this.displayName,
    required this.avatarUrl,
    required this.followerCount,
    required this.reelCount,
  });

  /// Account identifier for profile navigation and the follow graph.
  final String accountId;

  /// Compatibility alias for older feeds that exposed the account id under a
  /// misleading name. New code must use [accountId].
  @Deprecated('Use accountId. This is an account id, not a profile id.')
  String get creatorProfileId => accountId;
  final String handle;
  final String displayName;
  final String? avatarUrl;
  /// Follower total from the follow graph, or null when the backend could
  /// not measure it. Null must render as absent: a 0 is the claim that
  /// nobody follows this creator, which is a different statement.
  final int? followerCount;
  final int reelCount;

  factory CreatorChipDto.fromJson(Map<String, dynamic> json) {
    return CreatorChipDto(
      accountId: (json['accountId'] as String?) ??
          (json['creatorProfileId'] as String?) ??
          '',
      handle: (json['handle'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt(),
      reelCount: (json['reelCount'] as num?)?.toInt() ?? 0,
    );
  }
}
