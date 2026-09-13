import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/playback/platform_video_id.dart';
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
    this.externalId,
    this.videoUrl,
    this.isLikedByUser,
    this.isWishlistedByUser,
    this.isCreatorFollowed,
  });

  final String id;

  /// The platform's own post/video id (YouTube videoId, TikTok item id,
  /// Instagram media id, Facebook video id) as stored by the backend.
  final String? externalId;
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
    String? externalId,
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
      externalId: externalId ?? this.externalId,
    );
  }

  /// The platform's video id: the backend-stored [externalId] when present,
  /// otherwise read from [sourceUrl]. Null when neither yields one.
  @override
  String? get platformVideoId {
    final stored = externalId;
    if (stored != null && stored.isNotEmpty) return stored;
    return parsePlatformVideoId(platform, sourceUrl);
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
