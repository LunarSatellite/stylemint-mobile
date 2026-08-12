/// A product tag as returned by the creator-scoped tag-management endpoints
/// (`/v1/creator/reels/{reelId}/tagged-products`).
///
/// Distinct from `ReelTaggedProduct`, which is the read-only projection
/// embedded in the public reel detail. This one carries the tag's own [id] —
/// required to untag — plus the commission snapshot taken when the tag was
/// created, so the creator sees what they will actually earn rather than the
/// product's present-day rate.
class ReelProductTag {
  const ReelProductTag({
    required this.id,
    required this.reelId,
    required this.productId,
    required this.commissionPercent,
    required this.priceLabel,
    required this.commissionPerSaleLabel,
    required this.overlayPositionX,
    required this.overlayPositionY,
    this.productName,
    this.productImageUrl,
    this.vendorDisplayName,
    this.createdUtc,
  });

  /// The tag's identifier — pass to untag, not [productId].
  final String id;
  final String reelId;
  final String productId;
  final double commissionPercent;
  final String priceLabel;
  final String commissionPerSaleLabel;
  final double overlayPositionX;
  final double overlayPositionY;
  final String? productName;
  final String? productImageUrl;
  final String? vendorDisplayName;
  final DateTime? createdUtc;
}
