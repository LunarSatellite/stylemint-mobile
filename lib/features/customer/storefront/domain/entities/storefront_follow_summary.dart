/// Follower count of an account and whether the viewer follows it.
class StorefrontFollowSummary {
  const StorefrontFollowSummary({
    required this.followers,
    required this.isFollowedByViewer,
  });

  final int followers;
  final bool isFollowedByViewer;
}
