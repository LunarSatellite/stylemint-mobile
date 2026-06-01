class Story {
  const Story({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.taggedProductIds,
    required this.expiresAt,
    required this.viewCount,
    required this.hasWatched,
  });

  final String id;
  final String userId;
  final String userName;
  final String userAvatarUrl;
  final String mediaUrl;
  final String mediaType; // 'image' or 'video'
  final String? caption;
  final List<String> taggedProductIds;
  final DateTime expiresAt;
  final int viewCount;
  final bool hasWatched;

  Story copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    String? mediaUrl,
    String? mediaType,
    String? caption,
    List<String>? taggedProductIds,
    DateTime? expiresAt,
    int? viewCount,
    bool? hasWatched,
  }) {
    return Story(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      caption: caption ?? this.caption,
      taggedProductIds: taggedProductIds ?? this.taggedProductIds,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      hasWatched: hasWatched ?? this.hasWatched,
    );
  }
}

class StoryGroup {
  const StoryGroup({
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.stories,
    required this.hasUnwatched,
  });

  final String userId;
  final String userName;
  final String userAvatarUrl;
  final List<Story> stories;
  final bool hasUnwatched;

  StoryGroup copyWith({
    String? userId,
    String? userName,
    String? userAvatarUrl,
    List<Story>? stories,
    bool? hasUnwatched,
  }) {
    return StoryGroup(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      stories: stories ?? this.stories,
      hasUnwatched: hasUnwatched ?? this.hasUnwatched,
    );
  }
}
