/// `GET v1/public/creators/{accountId}/reel-stats`: totals over public reels.
class CreatorReelStats {
  const CreatorReelStats({
    required this.publishedReelCount,
    required this.totalLikes,
    required this.totalViews,
  });

  final int publishedReelCount;

  /// Native StyleMint likes.
  final int totalLikes;

  /// Provider-synced views.
  final int totalViews;
}
