import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';

class ReelTaggedProductDto {
  const ReelTaggedProductDto({
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

  factory ReelTaggedProductDto.fromJson(Map<String, dynamic> json) {
    final amount =
        (json['productPriceSnapshotAmount'] as num?)?.toDouble() ?? 0;
    final currency =
        (json['productPriceSnapshotCurrency'] as String?) ?? 'NPR';
    final symbol = currency.toUpperCase() == 'NPR' ? 'Rs' : currency;
    return ReelTaggedProductDto(
      productId: (json['productId'] as String?) ?? '',
      name: json['productName'] as String?,
      priceLabel: '$symbol ${amount.toStringAsFixed(0)}',
      imageUrl: json['productPrimaryImageUrl'] as String?,
      commissionPercent:
          (json['commissionRateSnapshotPercent'] as num?)?.toDouble() ?? 0,
    );
  }

  ReelTaggedProduct toDomain() => ReelTaggedProduct(
        productId: productId,
        name: name,
        priceLabel: priceLabel,
        imageUrl: imageUrl,
        commissionPercent: commissionPercent,
      );
}

/// DTO for `GET /v1/public/reels/{id}` → backend `ReelDto`.
/// Platform serialized as int (1=Instagram, 2=TikTok, 3=YouTube Shorts, 4=Facebook).
class CreatorReelDetailDto {
  const CreatorReelDetailDto({
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
  final List<ReelTaggedProductDto> taggedProducts;

  static const _platforms = {
    1: 'Instagram',
    2: 'TikTok',
    3: 'YouTube Shorts',
    4: 'Facebook',
  };

  factory CreatorReelDetailDto.fromJson(Map<String, dynamic> json) {
    final track = json['musicTrackTitle'] as String?;
    final artist = json['musicArtistName'] as String?;
    final music =
        [artist, track].where((e) => e != null && e.isNotEmpty).join(' - ');
    final rawProducts =
        json['taggedProducts'] as List<dynamic>? ?? const [];
    return CreatorReelDetailDto(
      id: (json['id'] as String?) ?? '',
      platformLabel:
          _platforms[(json['sourcePlatform'] as num?)?.toInt() ?? 0] ??
              'External',
      sourceUrl: (json['sourceUrl'] as String?) ?? '',
      caption: json['caption'] as String?,
      thumbnailUrl: json['thumbnailCdnUrl'] as String?,
      videoUrl: json['VideoCdnUrl'] as String?,
      musicLabel: music.isEmpty ? null : music,
      views: (json['viewsSnapshot'] as num?)?.toInt() ?? 0,
      likes: (json['likesSnapshot'] as num?)?.toInt() ?? 0,
      comments: (json['commentsSnapshot'] as num?)?.toInt() ?? 0,
      publishedAtUtc:
          DateTime.tryParse(json['publishedAtUtc'] as String? ?? ''),
      taggedProducts: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(ReelTaggedProductDto.fromJson)
          .toList(growable: false),
    );
  }

  CreatorReelDetail toDomain() => CreatorReelDetail(
        id: id,
        platformLabel: platformLabel,
        sourceUrl: sourceUrl,
        caption: caption,
        thumbnailUrl: thumbnailUrl,
        videoUrl: videoUrl,
        musicLabel: musicLabel,
        views: views,
        likes: likes,
        comments: comments,
        publishedAtUtc: publishedAtUtc,
        taggedProducts:
            taggedProducts.map((p) => p.toDomain()).toList(growable: false),
      );
}

/// DTO for `GET /v1/creator/reels/{id}/tagged-products` and
/// `POST /v1/creator/reels/{id}/tagged-products` (management endpoints).
class ReelTagManagementDto {
  const ReelTagManagementDto({
    required this.id,
    required this.reelId,
    required this.productId,
    this.partnershipIdSnapshot,
    required this.commissionRateSnapshotPercent,
    required this.productPriceSnapshotAmount,
    this.productPriceSnapshotCurrency,
    required this.commissionPerSaleSnapshotAmount,
    this.commissionPerSaleSnapshotCurrency,
    required this.overlayPositionX,
    required this.overlayPositionY,
    this.createdUtc,
    this.productName,
    this.productPrimaryImageUrl,
    this.vendorAccountId,
    this.vendorDisplayName,
  });

  final String id;
  final String reelId;
  final String productId;
  final String? partnershipIdSnapshot;
  final double commissionRateSnapshotPercent;
  final double productPriceSnapshotAmount;
  final String? productPriceSnapshotCurrency;
  final double commissionPerSaleSnapshotAmount;
  final String? commissionPerSaleSnapshotCurrency;
  final double overlayPositionX;
  final double overlayPositionY;
  final DateTime? createdUtc;
  final String? productName;
  final String? productPrimaryImageUrl;
  final String? vendorAccountId;
  final String? vendorDisplayName;

  factory ReelTagManagementDto.fromJson(Map<String, dynamic> json) =>
      ReelTagManagementDto(
        id: (json['id'] as String?) ?? '',
        reelId: (json['reelId'] as String?) ?? '',
        productId: (json['productId'] as String?) ?? '',
        partnershipIdSnapshot: json['partnershipIdSnapshot'] as String?,
        commissionRateSnapshotPercent:
            (json['commissionRateSnapshotPercent'] as num?)?.toDouble() ?? 0,
        productPriceSnapshotAmount:
            (json['productPriceSnapshotAmount'] as num?)?.toDouble() ?? 0,
        productPriceSnapshotCurrency:
            json['productPriceSnapshotCurrency'] as String?,
        commissionPerSaleSnapshotAmount:
            (json['commissionPerSaleSnapshotAmount'] as num?)?.toDouble() ?? 0,
        commissionPerSaleSnapshotCurrency:
            json['commissionPerSaleSnapshotCurrency'] as String?,
        overlayPositionX:
            (json['overlayPositionX'] as num?)?.toDouble() ?? 0,
        overlayPositionY:
            (json['overlayPositionY'] as num?)?.toDouble() ?? 0,
        createdUtc: DateTime.tryParse(json['createdUtc'] as String? ?? ''),
        productName: json['productName'] as String?,
        productPrimaryImageUrl: json['productPrimaryImageUrl'] as String?,
        vendorAccountId: json['vendorAccountId'] as String?,
        vendorDisplayName: json['vendorDisplayName'] as String?,
      );
}
