import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/feed_provenance.dart';
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
    this.isLikedByMe,
    this.isWishlistedByUser,
    this.isCreatorFollowed,
    this.creatorAvatarUrls = const <String>[],
    this.isSavedByMe,
    this.saveCount = 0,
    this.provenance,
    this.durationSeconds,
  });

  final String id;

  /// How long the reel runs, as the source platform reported it. Null when
  /// the payload did not carry one. Only used to judge whether a watch ran
  /// long enough to count as a completed view.
  final int? durationSeconds;

  /// Why the feed served this reel, and whether anything ranked it.
  ///
  /// Null everywhere the reel did not come from the Discovery feed — reel
  /// detail, related reels, a shared link. Null means "we were not told", and
  /// the card draws no label at all rather than guessing one.
  final FeedProvenance? provenance;

  /// The platform's own post/video id (YouTube videoId, TikTok item id,
  /// Instagram media id, Facebook video id) as stored by the backend.
  final String? externalId;

  /// Canonical post URL on IG / TikTok / YouTube / FB. Feeds the official
  /// embedded players; never opened outside StyleMint.
  final String sourceUrl;
  final String thumbnailUrl; // Preview image
  final String? videoUrl; // Direct MP4 for inline playback (optional)
  final String creatorId;
  final String creatorName;
  final String creatorAvatarUrl;

  /// Profile pictures of the creator's connected platforms in rotation order
  /// (Instagram, TikTok, YouTube, Facebook). Empty when none are synced; the
  /// avatar then falls back to [creatorAvatarUrl].
  final List<String> creatorAvatarUrls;
  final String caption;
  final String musicTitle;
  final String musicArtist;
  final List<TaggedProductEntity> taggedProducts;

  /// Platform likes plus StyleMint likes.
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final DateTime createdAt;

  /// Source platform (Instagram / YouTube / TikTok / Facebook). Used by the player
  /// to pick the right playback strategy. Null when the reel is pre-platform-tagging
  /// (legacy data).
  final SocialPlatform? platform;

  /// Whether the viewer liked this reel on StyleMint. Null for guests.
  final bool? isLikedByMe;
  final bool? isWishlistedByUser;
  final bool? isCreatorFollowed;

  /// Whether the viewer saved this reel on StyleMint. Null for guests.
  final bool? isSavedByMe;

  /// Accounts that saved the reel on StyleMint.
  final int saveCount;

  Reel copyWith({
    String? id,
    String? externalId,
    String? sourceUrl,
    String? thumbnailUrl,
    String? videoUrl,
    String? creatorId,
    String? creatorName,
    String? creatorAvatarUrl,
    List<String>? creatorAvatarUrls,
    String? caption,
    String? musicTitle,
    String? musicArtist,
    List<TaggedProductEntity>? taggedProducts,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    DateTime? createdAt,
    SocialPlatform? platform,
    bool? isLikedByMe,
    bool? isWishlistedByUser,
    bool? isCreatorFollowed,
    bool? isSavedByMe,
    int? saveCount,
    FeedProvenance? provenance,
    int? durationSeconds,
  }) {
    return Reel(
      id: id ?? this.id,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
      creatorAvatarUrls: creatorAvatarUrls ?? this.creatorAvatarUrls,
      caption: caption ?? this.caption,
      musicTitle: musicTitle ?? this.musicTitle,
      musicArtist: musicArtist ?? this.musicArtist,
      taggedProducts: taggedProducts ?? this.taggedProducts,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      createdAt: createdAt ?? this.createdAt,
      platform: platform ?? this.platform,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isWishlistedByUser: isWishlistedByUser ?? this.isWishlistedByUser,
      isCreatorFollowed: isCreatorFollowed ?? this.isCreatorFollowed,
      externalId: externalId ?? this.externalId,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
      saveCount: saveCount ?? this.saveCount,
      provenance: provenance ?? this.provenance,
      durationSeconds: durationSeconds ?? this.durationSeconds,
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

  /// Canonical post URL. Alias of [sourceUrl] for the [ReelMedia] contract.
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
