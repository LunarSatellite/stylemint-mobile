class CreatorProfile {
  const CreatorProfile({
    required this.id,
    required this.displayName,
    required this.handle,
    required this.bio,
    required this.tags,
    required this.niches,
    required this.followersCount,
    required this.partnershipsCount,
    required this.reelsCount,
    required this.likesCount,
    required this.rowVersion,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String handle;
  final String? avatarUrl;
  final String bio;
  final List<String> tags;
  final List<String> niches;
  final int followersCount;
  final int partnershipsCount;
  final int reelsCount;
  final int likesCount;
  final String rowVersion;

  CreatorProfile copyWith({
    String? displayName,
    String? handle,
    String? bio,
    List<String>? tags,
    List<String>? niches,
    int? followersCount,
    int? partnershipsCount,
    int? reelsCount,
    int? likesCount,
    String? rowVersion,
    String? avatarUrl,
  }) =>
      CreatorProfile(
        id: id,
        displayName: displayName ?? this.displayName,
        handle: handle ?? this.handle,
        bio: bio ?? this.bio,
        tags: tags ?? this.tags,
        niches: niches ?? this.niches,
        followersCount: followersCount ?? this.followersCount,
        partnershipsCount: partnershipsCount ?? this.partnershipsCount,
        reelsCount: reelsCount ?? this.reelsCount,
        likesCount: likesCount ?? this.likesCount,
        rowVersion: rowVersion ?? this.rowVersion,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}
