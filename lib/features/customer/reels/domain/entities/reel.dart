import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Reel entity - represents a reel/video in the feed
/// Pure Dart entity with no JSON serialization (that's for DTOs in data layer)
class Reel {
  final String id;
  final String sourceUrl; // Deep link to IG/TikTok/YouTube/FB
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
  final bool? isLikedByUser;
  final bool? isWishlistedByUser;
  final bool? isCreatorFollowed;
  final DateTime createdAt;

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
    this.isLikedByUser,
    this.isWishlistedByUser,
    this.isCreatorFollowed,
    required this.createdAt,
  });

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
    bool? isLikedByUser,
    bool? isWishlistedByUser,
    bool? isCreatorFollowed,
    DateTime? createdAt,
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
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      isWishlistedByUser: isWishlistedByUser ?? this.isWishlistedByUser,
      isCreatorFollowed: isCreatorFollowed ?? this.isCreatorFollowed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Tagged product entity - product shown in a reel
class TaggedProductEntity {
  final String id;
  final String name;
  final String imageUrl;
  final Money price;
  final int quantity;

  const TaggedProductEntity({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });
}
