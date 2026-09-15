import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/domain/entities/storefront_reel.dart';

/// The fields of the Reels `ReelDto` a storefront tile needs.
class StorefrontReelDto {
  const StorefrontReelDto({
    required this.id,
    required this.creatorAccountId,
    this.creatorDisplayName,
    this.creatorAvatarUrl,
    this.caption,
    this.thumbnailCdnUrl,
    this.likeCount = 0,
    this.viewsSnapshot = 0,
    this.taggedProductCount = 0,
    this.isSavedByMe,
    this.createdUtc,
  });

  factory StorefrontReelDto.fromJson(Map<String, dynamic> json) {
    final tagged = json['taggedProducts'];
    final saved = json['isSavedByMe'];
    return StorefrontReelDto(
      id: readString(json['id']),
      creatorAccountId: readString(json['creatorAccountId']),
      creatorDisplayName: readOptionalString(json['creatorDisplayName']),
      creatorAvatarUrl: readOptionalString(json['creatorAvatarUrl']),
      caption: readOptionalString(json['caption']),
      thumbnailCdnUrl: readOptionalString(json['thumbnailCdnUrl']),
      // `likeCount` is provider likes + StyleMint likes; older payloads only
      // carry the two parts.
      likeCount: json.containsKey('likeCount')
          ? readInt(json['likeCount'])
          : readInt(json['likesSnapshot']) +
                readInt(json['styleMintLikeCount']),
      viewsSnapshot: readInt(json['viewsSnapshot']),
      taggedProductCount: tagged is List ? tagged.length : 0,
      isSavedByMe: saved is bool ? saved : null,
      createdUtc: readDate(json['createdUtc']),
    );
  }

  final String id;
  final String creatorAccountId;
  final String? creatorDisplayName;
  final String? creatorAvatarUrl;
  final String? caption;
  final String? thumbnailCdnUrl;
  final int likeCount;
  final int viewsSnapshot;
  final int taggedProductCount;
  final bool? isSavedByMe;
  final DateTime? createdUtc;

  /// Null when the reel has no id to open.
  StorefrontReel? toDomain() => id.isEmpty
      ? null
      : StorefrontReel(
          id: id,
          creatorAccountId: creatorAccountId,
          creatorName: creatorDisplayName,
          creatorAvatarUrl: creatorAvatarUrl,
          caption: caption,
          posterUrl: thumbnailCdnUrl,
          likeCount: likeCount < 0 ? 0 : likeCount,
          viewCount: viewsSnapshot < 0 ? 0 : viewsSnapshot,
          taggedProductCount: taggedProductCount,
          isSavedByMe: isSavedByMe,
          createdUtc: createdUtc,
        );
}
