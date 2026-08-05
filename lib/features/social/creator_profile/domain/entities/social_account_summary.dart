/// Lightweight projection of a SocialAccount used by the profile popup.
/// Holds just enough to drive the not-connected → connected state and
/// the fallback fields when the YouTube Data API is missing/empty.
class SocialAccountSummary {
  const SocialAccountSummary({
    required this.slug,
    required this.providerUserId,
    required this.handle,
    required this.displayName,
    required this.avatarUrl,
    required this.followerCount,
  });

  /// Platform slug (instagram | tiktok | youtube | facebook).
  final String slug;
  final String providerUserId;
  final String handle;
  final String displayName;
  final String avatarUrl;
  final int followerCount;
}
