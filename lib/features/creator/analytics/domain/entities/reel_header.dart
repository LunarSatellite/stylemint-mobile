class ReelHeader {
  const ReelHeader({
    required this.reelId,
    this.title,
    this.thumbnailUrl,
    this.sourcePlatform,
    this.sourceUrl,
    required this.durationSeconds,
    this.publishedAtUtc,
    required this.views,
    required this.likes,
    required this.comments,
  });

  final String reelId;
  final String? title;
  final String? thumbnailUrl;
  final String? sourcePlatform;
  final String? sourceUrl;
  final int durationSeconds;
  final DateTime? publishedAtUtc;
  final int views;
  final int likes;
  final int comments;
}
