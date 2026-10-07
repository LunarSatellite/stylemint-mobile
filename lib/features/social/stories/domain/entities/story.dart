/// How long a story stays up. The backend stamps `ExpiresUtc = PostedUtc +
/// 24h`, and deriving the posted time from the expiry spares the DTO a field.
const Duration storyLifetime = Duration(hours: 24);

/// Shown for a story whose payload carried no author name. The viewer's own
/// new story is filled from their profile instead (see StoriesNotifier).
const String unknownStoryAuthorName = 'StyleMint user';

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

  bool get isVideo => mediaType == 'video';

  /// When the story went up — exact for backend stories (see [storyLifetime]).
  DateTime get postedAt => expiresAt.subtract(storyLifetime);

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
