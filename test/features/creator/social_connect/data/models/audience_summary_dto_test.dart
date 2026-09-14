import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/data/models/audience_summary_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

void main() {
  group('AudienceSummaryDto.fromJson', () {
    test('maps totals and per-platform rows', () {
      final summary = AudienceSummaryDto.fromJson(<String, dynamic>{
        'totalFollowers': 1250,
        'averageEngagementRatePercent': 5.0,
        'platforms': [
          {
            'provider': 1,
            'handle': 'stylemint2026',
            'followerCount': 1000,
            'engagementRatePercent': 4.0,
            'engagementBasis': 'followers',
            'postsSampled': 3,
          },
          {
            'provider': 2,
            'handle': 'Stylemint',
            'followerCount': null,
            'engagementRatePercent': 8.25,
            'engagementBasis': 'views',
            'postsSampled': 1,
          },
        ],
      });

      expect(summary.totalFollowers, 1250);
      expect(summary.averageEngagementRatePercent, 5.0);
      expect(summary.platforms, hasLength(2));
      expect(summary.platforms[0].platform, SocialPlatform.instagram);
      expect(summary.platforms[0].followerCount, 1000);
      expect(summary.platforms[1].platform, SocialPlatform.tiktok);
      expect(summary.platforms[1].followerCount, isNull);
      expect(summary.platforms[1].engagementRatePercent, 8.25);
      expect(summary.platforms[1].engagementBasis, 'views');
    });

    test('keeps nulls when nothing is reported', () {
      final summary = AudienceSummaryDto.fromJson(<String, dynamic>{
        'totalFollowers': null,
        'averageEngagementRatePercent': null,
        'platforms': [
          {'provider': 4, 'handle': 'Stylemint Nepal', 'postsSampled': 0},
        ],
      });

      expect(summary.totalFollowers, isNull);
      expect(summary.averageEngagementRatePercent, isNull);
      expect(summary.platforms.single.platform, SocialPlatform.facebook);
      expect(summary.platforms.single.engagementRatePercent, isNull);
    });

    test('drops rows with an unknown provider', () {
      final summary = AudienceSummaryDto.fromJson(<String, dynamic>{
        'platforms': [
          {'provider': 99, 'handle': 'x'},
          {'provider': 3, 'handle': 'stylemintnepal', 'followerCount': 12},
        ],
      });

      expect(summary.platforms, hasLength(1));
      expect(summary.platforms.single.platform, SocialPlatform.youtube);
      expect(summary.platforms.single.postsSampled, 0);
    });
  });
}
