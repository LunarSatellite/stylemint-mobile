import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

class ReelTaggedProduct {
  const ReelTaggedProduct({
    required this.productId,
    required this.name,
    required this.priceLabel,
    required this.imageUrl,
    required this.commissionPercent,
  });

  final String productId;
  final String? name;
  final String priceLabel;
  final String? imageUrl;
  final double commissionPercent;
}

class CreatorReelDetail implements ReelMedia {
  const CreatorReelDetail({
    required this.id,
    required this.platformLabel,
    required this.sourceUrl,
    required this.caption,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.musicLabel,
    required this.views,
    required this.likes,
    required this.comments,
    required this.publishedAtUtc,
    required this.taggedProducts,
  });

  final String id;
  final String platformLabel;
  final String sourceUrl;
  final String? caption;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? musicLabel;
  final int views;
  final int likes;
  final int comments;
  final DateTime? publishedAtUtc;
  final List<ReelTaggedProduct> taggedProducts;

  /// Resolve [platformLabel] (e.g. "YouTube") to the [SocialPlatform]
  /// enum. Used by the player to pick the playback strategy.
  @override
  SocialPlatform? get platform {
    final normalised = platformLabel.toLowerCase().replaceAll(' ', '');
    for (final p in SocialPlatform.values) {
      if (p.name.toLowerCase() == normalised) return p;
    }
    return null;
  }

  /// Platform-specific video ID parsed from [sourceUrl]. Only YouTube is
  /// supported today (TikTok / Facebook fall back to external app).
  @override
  String? get platformVideoId {
    if (platform != SocialPlatform.youtube) return null;
    final uri = Uri.tryParse(sourceUrl);
    return uri?.queryParameters['v'];
  }

  @override
  String get permalink => sourceUrl;
}
