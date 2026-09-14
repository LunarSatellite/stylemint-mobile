import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// A creator's audience across connected platforms, computed by the backend
/// from each platform's own numbers (never self-reported).
class AudienceSummary {
  const AudienceSummary({
    required this.totalFollowers,
    required this.averageEngagementRatePercent,
    required this.platforms,
  });

  /// Sum of the follower counts platforms report; null when none reports one.
  final int? totalFollowers;

  /// Engagement rate across platforms; null when no post metrics came back.
  final double? averageEngagementRatePercent;

  final List<PlatformAudience> platforms;
}

class PlatformAudience {
  const PlatformAudience({
    required this.platform,
    required this.handle,
    required this.followerCount,
    required this.engagementRatePercent,
    required this.engagementBasis,
    required this.postsSampled,
  });

  final SocialPlatform platform;
  final String handle;

  /// Null when the platform doesn't share a follower count.
  final int? followerCount;

  /// Null when the platform returned no post metrics.
  final double? engagementRatePercent;

  /// 'followers' or 'views'; null when there is no rate.
  final String? engagementBasis;

  final int postsSampled;
}
