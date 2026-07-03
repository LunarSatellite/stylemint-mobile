class CreatorReelSummary {
  const CreatorReelSummary({
    required this.id,
    required this.thumbnailUrl,
    required this.views,
    required this.likes,
    required this.publishedAtUtc,
  });

  final String id;
  final String? thumbnailUrl;
  final int views;
  final int likes;
  final DateTime? publishedAtUtc;
}
