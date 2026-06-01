import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// A reel in the feed. Pure-Dart domain entity — no JSON, no Dio.
/// Reels are pointer records: [sourceUrl] deep-links to the external platform.
class Reel {
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
    this.isLikedByUser,
    this.isWishlistedByUser,
    this.isCreatorFollowed,
  });

  final String id;
  final String sourceUrl; // Deep link to IG / TikTok / YouTube / FB
  final String thumbnailUrl; // Preview image
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
  final bool? isLikedByUser;
  final bool? isWishlistedByUser;
  final bool? isCreatorFollowed;

  Reel copyWith({
    String? id,
    String? sourceUrl,
    String? thumbnailUrl,
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
    bool? isLikedByUser,
    bool? isWishlistedByUser,
    bool? isCreatorFollowed,
  }) {
    return Reel(
      id: id ?? this.id,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
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
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      isWishlistedByUser: isWishlistedByUser ?? this.isWishlistedByUser,
      isCreatorFollowed: isCreatorFollowed ?? this.isCreatorFollowed,
    );
  }
}

/// A product tagged on a reel.
class TaggedProductEntity {
  const TaggedProductEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  final String id;
  final String name;
  final String imageUrl;
  final Money price;
  final int quantity;
}
