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
    required this.sourcePlatform,
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
    this.creatorId = '',
    this.creatorHandle = '',
    this.creatorDisplayName = '',
    this.creatorAvatarUrl = '',
    this.isCreatorFollowed,
  });

  final String id;

  /// Backend `sourcePlatform` integer (1=Instagram, 2=TikTok, 3=YouTube Shorts,
  /// 4=Facebook). The single source of truth used to resolve [platform]; do
  /// NOT derive [platform] from [platformLabel] — the human label "YouTube
  /// Shorts" does not parse back to `SocialPlatform.youtube`.
  final int sourcePlatform;

  /// Human-readable platform name (e.g. "YouTube Shorts"). Display only.
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

  // ── Creator strip (added on the top-performing reel play) ────────────────
  // Backend `GET /v1/public/reels/{id}` may not yet ship these — the
  // fields default to empty so the strip degrades gracefully (avatar
  // placeholder, no Follow button, caption still rendered) when the
  // creator payload is missing.

  /// Account id of the reel's creator. Empty when the backend did not
  /// include creator fields. When non-empty, the Follow toggle in
  /// [ReelCreatorStrip] is functional.
  final String creatorId;

  /// Public handle shown in the creator strip (e.g. `footbagoob`).
  /// Rendered as `@handle` and used as the strip's primary text.
  final String creatorHandle;

  /// Human display name (e.g. "Footbag Oob"). Falls back to [creatorHandle]
  /// when blank in the UI layer.
  final String creatorDisplayName;

  /// Avatar CDN URL. Empty when missing → placeholder.
  final String creatorAvatarUrl;

  /// Whether the current viewer already follows this creator. Null when
  /// the backend has not hydrated this field.
  final bool? isCreatorFollowed;

  /// Resolve the backend [sourcePlatform] integer to the [SocialPlatform]
  /// enum used by [ReelPlayer] to pick the playback strategy. Falls back to
  /// `null` (which the player treats as Instagram) only when the backend
  /// sends an unrecognised value.
  @override
  SocialPlatform? get platform => switch (sourcePlatform) {
        1 => SocialPlatform.instagram,
        2 => SocialPlatform.tiktok,
        3 => SocialPlatform.youtube,
        4 => SocialPlatform.facebook,
        _ => null,
      };

  /// Platform-specific video ID parsed from [sourceUrl]. Only YouTube is
  /// supported today (TikTok / Facebook fall back to external app).
  @override
  String? get platformVideoId {
    if (platform != SocialPlatform.youtube) return null;
    final uri = Uri.tryParse(sourceUrl);
    if (uri == null) return null;
    // Standard watch URL: https://www.youtube.com/watch?v=ID
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    // Short URL: https://youtu.be/ID
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      final seg = uri.pathSegments.first;
      if (seg.isNotEmpty) return seg;
    }
    // Shorts URL: https://www.youtube.com/shorts/ID
    final path = uri.pathSegments;
    final shortsIdx = path.indexOf('shorts');
    if (shortsIdx >= 0 && shortsIdx + 1 < path.length) {
      final id = path[shortsIdx + 1];
      if (id.isNotEmpty) return id;
    }
    return null;
  }

  @override
  String get permalink => sourceUrl;
}
