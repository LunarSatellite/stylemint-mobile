class FollowingUser {
  const FollowingUser({
    required this.id,
    required this.displayName,
    required this.avatarUrl,
    required this.handle,
    required this.isFollowing,
    required this.followerCount,
    this.category,
    this.bio,
  });

  final String id;
  final String displayName;
  final String avatarUrl;
  final String handle;
  final bool isFollowing;
  final int followerCount;
  final String? category;
  final String? bio;

  FollowingUser copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? handle,
    bool? isFollowing,
    int? followerCount,
    String? category,
    String? bio,
  }) {
    return FollowingUser(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      handle: handle ?? this.handle,
      isFollowing: isFollowing ?? this.isFollowing,
      followerCount: followerCount ?? this.followerCount,
      category: category ?? this.category,
      bio: bio ?? this.bio,
    );
  }
}
