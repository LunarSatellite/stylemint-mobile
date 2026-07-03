import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';

/// DTO for items in `GET /v1/creator/reels` response.
class CreatorReelSummaryDto {
  const CreatorReelSummaryDto({
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

  factory CreatorReelSummaryDto.fromJson(Map<String, dynamic> json) {
    return CreatorReelSummaryDto(
      id: (json['id'] as String?) ?? '',
      thumbnailUrl: json['thumbnailCdnUrl'] as String?,
      views: (json['viewsSnapshot'] as num?)?.toInt() ?? 0,
      likes: (json['likesSnapshot'] as num?)?.toInt() ?? 0,
      publishedAtUtc:
          DateTime.tryParse(json['publishedAtUtc'] as String? ?? ''),
    );
  }

  CreatorReelSummary toDomain() => CreatorReelSummary(
        id: id,
        thumbnailUrl: thumbnailUrl,
        views: views,
        likes: likes,
        publishedAtUtc: publishedAtUtc,
      );
}
