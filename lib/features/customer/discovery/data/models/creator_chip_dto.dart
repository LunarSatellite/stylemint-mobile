/// `CreatorChipDto` from `/api/v1/customer/feed/creators-you-may-like`.
class CreatorChipDto {
  const CreatorChipDto({
    required this.creatorProfileId,
    required this.handle,
    required this.displayName,
    required this.avatarUrl,
    required this.followerCount,
    required this.reelCount,
  });

  final String creatorProfileId;
  final String handle;
  final String displayName;
  final String? avatarUrl;
  final int followerCount;
  final int reelCount;

  factory CreatorChipDto.fromJson(Map<String, dynamic> json) {
    return CreatorChipDto(
      creatorProfileId: (json['creatorProfileId'] as String?) ?? '',
      handle: (json['handle'] as String?) ?? '',
      displayName: (json['displayName'] as String?) ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
      reelCount: (json['reelCount'] as num?)?.toInt() ?? 0,
    );
  }
}
