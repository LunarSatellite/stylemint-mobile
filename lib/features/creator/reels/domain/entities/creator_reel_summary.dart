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

/// One page of a creator's own reels, plus their total across every page.
///
/// The dashboard used to show `topReels.length` as the creator's reel count.
/// That list is the analytics overview's *top performers*: capped by the
/// server's TopReelsLimit and scoped to the selected analytics window, so a
/// newly imported reel with no views was not in it and the number did not
/// move. [totalCount] is the real figure, straight from the paged response.
class CreatorReelsSummaryPage {
  const CreatorReelsSummaryPage({
    required this.items,
    required this.totalCount,
  });

  final List<CreatorReelSummary> items;
  final int totalCount;
}
