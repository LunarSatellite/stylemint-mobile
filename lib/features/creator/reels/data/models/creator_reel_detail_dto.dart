/// Tagged product on a reel (subset of backend TaggedProductDto).
class ReelTaggedProductLite {
  const ReelTaggedProductLite({
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

  factory ReelTaggedProductLite.fromJson(Map<String, dynamic> json) {
    final amount =
        (json['productPriceSnapshotAmount'] as num?)?.toDouble() ?? 0;
    final currency =
        (json['productPriceSnapshotCurrency'] as String?) ?? 'NPR';
    final symbol = currency.toUpperCase() == 'NPR' ? 'Rs' : currency;
    return ReelTaggedProductLite(
      productId: (json['productId'] as String?) ?? '',
      name: json['productName'] as String?,
      priceLabel: '$symbol ${amount.toStringAsFixed(0)}',
      imageUrl: json['productPrimaryImageUrl'] as String?,
      commissionPercent:
          (json['commissionRateSnapshotPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Creator-facing single reel detail — backend `ReelDto`
/// (`GET /v1/public/reels/{id}`). Platform serialized as int (1..4).
class CreatorReelDetail {
  const CreatorReelDetail({
    required this.id,
    required this.platformLabel,
    required this.sourceUrl,
    required this.caption,
    required this.thumbnailUrl,
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
  final String? musicLabel;
  final int views;
  final int likes;
  final int comments;
  final DateTime? publishedAtUtc;
  final List<ReelTaggedProductLite> taggedProducts;

  static const _platforms = {
    1: 'Instagram',
    2: 'TikTok',
    3: 'YouTube Shorts',
    4: 'Facebook',
  };

  factory CreatorReelDetail.fromJson(Map<String, dynamic> json) {
    final track = json['musicTrackTitle'] as String?;
    final artist = json['musicArtistName'] as String?;
    final music = [artist, track].where((e) => e != null && e.isNotEmpty).join(' - ');
    final rawProducts = (json['taggedProducts'] as List<dynamic>? ?? const []);
    return CreatorReelDetail(
      id: (json['id'] as String?) ?? '',
      platformLabel:
          _platforms[(json['sourcePlatform'] as num?)?.toInt() ?? 0] ?? 'External',
      sourceUrl: (json['sourceUrl'] as String?) ?? '',
      caption: json['caption'] as String?,
      thumbnailUrl: json['thumbnailCdnUrl'] as String?,
      musicLabel: music.isEmpty ? null : music,
      views: (json['viewsSnapshot'] as num?)?.toInt() ?? 0,
      likes: (json['likesSnapshot'] as num?)?.toInt() ?? 0,
      comments: (json['commentsSnapshot'] as num?)?.toInt() ?? 0,
      publishedAtUtc: DateTime.tryParse(json['publishedAtUtc'] as String? ?? ''),
      taggedProducts: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(ReelTaggedProductLite.fromJson)
          .toList(growable: false),
    );
  }
}
