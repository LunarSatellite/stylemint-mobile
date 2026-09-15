import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_storefront/domain/entities/creator_reel_stats.dart';

/// Reels `CreatorReelStatsDto`. Missing totals read as zero.
class CreatorReelStatsDto {
  const CreatorReelStatsDto({
    this.publishedReelCount = 0,
    this.totalStyleMintLikes = 0,
    this.totalViewsSnapshot = 0,
  });

  factory CreatorReelStatsDto.fromJson(Map<String, dynamic> json) =>
      CreatorReelStatsDto(
        publishedReelCount: readInt(json['publishedReelCount']),
        totalStyleMintLikes: readInt(json['totalStyleMintLikes']),
        totalViewsSnapshot: readInt(json['totalViewsSnapshot']),
      );

  final int publishedReelCount;
  final int totalStyleMintLikes;
  final int totalViewsSnapshot;

  CreatorReelStats toDomain() => CreatorReelStats(
    publishedReelCount: publishedReelCount < 0 ? 0 : publishedReelCount,
    totalLikes: totalStyleMintLikes < 0 ? 0 : totalStyleMintLikes,
    totalViews: totalViewsSnapshot < 0 ? 0 : totalViewsSnapshot,
  );
}
