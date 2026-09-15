import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/product_reel.dart';

/// One reel of `GET /v1/public/reels/by-product/{productId}` — backend
/// `ReelDto`: `{ id, sourcePlatform, sourceUrl, externalId, caption,
/// thumbnailCdnUrl?, videoCdnUrl?, creatorDisplayName?, likeCount, … }`.
/// The feed card's spellings (`reelId`, `externalUrl`, `thumbnailUrl`,
/// `creatorHandle`) are accepted too.
class ProductReelDto {
  const ProductReelDto({
    required this.id,
    required this.sourceUrl,
    this.thumbnailUrl,
    this.videoUrl,
    this.platform,
    this.externalId,
    this.creatorName = '',
    this.caption = '',
    this.likeCount = 0,
  });

  factory ProductReelDto.fromJson(Map<String, dynamic> json) {
    String first(List<String> keys) {
      for (final key in keys) {
        final value = readString(json[key]);
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    String? optional(List<String> keys) {
      final value = first(keys);
      return value.isEmpty ? null : value;
    }

    return ProductReelDto(
      id: first(['id', 'reelId']),
      sourceUrl: first(['sourceUrl', 'externalUrl']),
      thumbnailUrl: optional(['thumbnailCdnUrl', 'thumbnailUrl']),
      videoUrl: optional(['videoCdnUrl', 'videoUrl']),
      platform: SocialPlatform.tryParseWire(json['sourcePlatform']),
      externalId: optional(['externalId']),
      creatorName: first(['creatorDisplayName', 'creatorHandle']),
      caption: first(['caption']),
      likeCount: readInt(json['likeCount'] ?? json['likesSnapshot']),
    );
  }

  /// The `items` of the page; reels without an id can't be opened, so they
  /// are dropped.
  static List<ProductReelDto> listFromPage(Object? raw) => readPagedItems(raw)
      .map(ProductReelDto.fromJson)
      .where((reel) => reel.id.isNotEmpty)
      .toList(growable: false);

  final String id;
  final String sourceUrl;
  final String? thumbnailUrl;
  final String? videoUrl;
  final SocialPlatform? platform;
  final String? externalId;
  final String creatorName;
  final String caption;
  final int likeCount;

  ProductReel toDomain() => ProductReel(
    id: id,
    permalink: sourceUrl,
    thumbnailUrl: thumbnailUrl,
    videoUrl: videoUrl,
    platform: platform,
    externalId: externalId,
    creatorName: creatorName,
    caption: caption,
    likeCount: likeCount,
  );
}
