import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/audience_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// Parses `GET /v1/social/accounts/audience-summary` (backend
/// `AudienceSummaryDto`). `provider` is the SocialProvider int enum
/// (1 Instagram, 2 TikTok, 3 YouTube, 4 Facebook). Rows with an unknown
/// provider are dropped rather than shown under the wrong platform.
class AudienceSummaryDto {
  const AudienceSummaryDto._();

  static AudienceSummary fromJson(Map<String, dynamic> json) {
    final rows = (json['platforms'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>();

    return AudienceSummary(
      totalFollowers: (json['totalFollowers'] as num?)?.toInt(),
      averageEngagementRatePercent:
          (json['averageEngagementRatePercent'] as num?)?.toDouble(),
      platforms: [
        for (final row in rows)
          if (SocialPlatform.tryParseWire(row['provider']) case final platform?)
            PlatformAudience(
              platform: platform,
              handle: row['handle'] as String? ?? '',
              followerCount: (row['followerCount'] as num?)?.toInt(),
              engagementRatePercent:
                  (row['engagementRatePercent'] as num?)?.toDouble(),
              engagementBasis: row['engagementBasis'] as String?,
              postsSampled: (row['postsSampled'] as num?)?.toInt() ?? 0,
            ),
      ],
    );
  }
}
