/// Follower and following counts of an account, and whether the viewer
/// follows it.
///
/// `following` was parsed by `FollowApi.stats` and then dropped here, so no
/// storefront could render it even though the backend had been returning it
/// all along — which is why a creator's profile showed Followers but never
/// Following.
class StorefrontFollowSummary {
  const StorefrontFollowSummary({
    required this.followers,
    required this.following,
    required this.isFollowedByViewer,
  });

  /// Accounts that follow this one.
  final int followers;

  /// Accounts this one follows.
  final int following;

  final bool isFollowedByViewer;
}
