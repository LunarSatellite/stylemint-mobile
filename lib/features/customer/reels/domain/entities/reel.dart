import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/reel_media.dart';

/// One page of the cursor-paginated reels feed.
class ReelsFeedPage {
  const ReelsFeedPage({required this.reels, required this.nextCursor});

  final List<Reel> reels;

  /// Null when this was the last page.
  final String? nextCursor;
}

/// A reel in the feed. Pure-Dart domain entity — no JSON, no Dio.
/// Reels are pointer records: [sourceUrl] deep-links to the external platform.
class Reel implements ReelMedia {
  const Reel({
    required this.id,
    required this.sourceUrl,
    required this.thumbnailUrl,
    required this.creatorId,
    required this.creatorName,
    required this.creatorAvatarUrl,
    required this.caption,
    required this.musicTitle,
    required this.musicArtist,
    required this.taggedProducts,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.createdAt,
    this.platform,
    this.videoUrl,
    this.isLikedByUser,
    this.isWishlistedByUser,
    this.isCreatorFollowed,
  });

  final String id;
  final String sourceUrl; // Deep link to IG / TikTok / YouTube / FB
  final String thumbnailUrl; // Preview image
  final String? videoUrl; // Direct MP4 for inline playback (optional)
  final String creatorId;
  final String creatorName;
  final String creatorAvatarUrl;
  final String caption;
  final String musicTitle;
  final String musicArtist;
  final List<TaggedProductEntity> taggedProducts;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;

  /// Source platform (Instagram / YouTube / TikTok / Facebook). Used by the player
  /// to pick the right playback strategy. Null when the reel is pre-platform-tagging
  /// (legacy data).
  final SocialPlatform? platform;

  final bool? isLikedByUser;
  final bool? isWishlistedByUser;
  final bool? isCreatorFollowed;

  Reel copyWith({
    String? id,
    String? sourceUrl,
    String? thumbnailUrl,
    String? videoUrl,
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
    String? caption,
    String? musicTitle,
    String? musicArtist,
    List<TaggedProductEntity>? taggedProducts,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    DateTime? createdAt,
    SocialPlatform? platform,
    bool? isLikedByUser,
    bool? isWishlistedByUser,
    bool? isCreatorFollowed,
  }) {
    return Reel(
      id: id ?? this.id,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      caption: caption ?? this.caption,
      musicTitle: musicTitle ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      taggedProducts: taggedProducts ?? this.taggedProducts,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
      platform: platform ?? this.platform,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      isWishlistedByUser: isWishlistedByUser ?? this.isWishlistedByUser,
      isCreatorFollowed: isCreatorFollowed ?? this.isCreatorFollowed,
    );
  }

  /// Platform-specific video ID derived from [sourceUrl]. Used by YouTube playback
  /// to identify the video. Null when not parseable.
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

  /// Open URL for the platform's native app / web. Alias of [sourceUrl]
  /// for the [ReelMedia] contract.
  @override
  String get permalink => sourceUrl;
}

/// A product tagged on a reel.
class TaggedProductEntity {
  const TaggedProductEntity({
    required this.id,
    this.taggedProductId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  final String id;

  /// Immutable server-side reel-tag ID. Passing it to Cart preserves the
  /// creator and commission snapshot for a reel-driven purchase.
  final String? taggedProductId;
  final String name;
  final String imageUrl;
  final Money price;
  final int quantity;
}
