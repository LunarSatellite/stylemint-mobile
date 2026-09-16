import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// The reel a product is sold through, as the public product payloads carry
/// it (`ProductDto.reel`, nullable).
///
/// Most products have none: on production data 24 of 106 carry a reel. A
/// product without one is not broken — it simply shows its designed type
/// tile instead of a poster.
///
/// [externalId] and [platform] are the playback coordinates. They are kept
/// even though nothing plays a reel inline in the Mall today (see
/// `MallReelPlaySlotController`), because they are what an inline player
/// would need and dropping them here would mean re-plumbing three DTOs.
class ProductReelRef {
  const ProductReelRef({
    required this.reelId,
    this.posterUrl,
    this.platform,
    this.externalId,
    this.hook,
    this.isAiGenerated = false,
    this.durationSeconds = 0,
  });

  final String reelId;

  /// Poster frame. Null until the platform sync has run, which is why the
  /// reel tile still has to draw something good with no image.
  final String? posterUrl;

  /// Source platform, parsed from the wire's int or string form. Null when
  /// absent or unrecognised.
  final SocialPlatform? platform;

  /// The platform's own video id (YouTube videoId, TikTok item id, ...).
  final String? externalId;

  /// The reel's opening line, without links or hashtags.
  final String? hook;

  /// Reels flagged as AI-generated must carry the visible label. Never
  /// inferred — only ever what the server sent.
  final bool isAiGenerated;

  /// Runtime in whole seconds; 0 when the server did not send one.
  final int durationSeconds;
}
