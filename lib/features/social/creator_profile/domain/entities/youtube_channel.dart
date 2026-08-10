class YouTubeChannel {
  const YouTubeChannel({
    required this.id,
    required this.title,
    required this.handle,
    required this.description,
    required this.avatarUrl,
    required this.bannerUrl,
    required this.subscriberCount,
    required this.videoCount,
    required this.viewCount,
    required this.lastSyncedUtc,
  });

  final String id;
  final String title;
  final String handle;
  final String description;
  final String avatarUrl;
  final String bannerUrl;
  final int subscriberCount;
  final int videoCount;
  final int viewCount;
  final DateTime lastSyncedUtc;
}
