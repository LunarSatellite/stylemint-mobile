/// `VendorCreatorPerformanceDto` from `GET /v1/vendor/creator-performance` —
/// real per-creator sales/earnings of the vendor's products over a window.
///
/// The endpoint returns a plain JSON array (not wrapped, not paged). Only the
/// creator's account id is included; handle/display-name hydration is a future
/// enrichment, so the UI shows a short id fallback.
class CreatorPerformanceDto {
  const CreatorPerformanceDto({
    required this.creatorAccountId,
    required this.unitsSold,
    required this.attributedRevenue,
    required this.commissionPaid,
    required this.currency,
    required this.distinctReelCount,
  });

  final String creatorAccountId;
  final int unitsSold;
  final double attributedRevenue;
  final double commissionPaid;
  final String currency;
  final int distinctReelCount;

  /// Short, human-friendly fallback label until handles are hydrated.
  String get shortLabel => creatorAccountId.length >= 4
      ? 'Creator ••${creatorAccountId.substring(creatorAccountId.length - 4)}'
      : 'Creator';

  factory CreatorPerformanceDto.fromJson(Map<String, dynamic> json) {
    return CreatorPerformanceDto(
      creatorAccountId: (json['creatorAccountId'] as String?) ?? '',
      unitsSold: (json['unitsSold'] as num?)?.toInt() ?? 0,
      attributedRevenue: (json['attributedRevenue'] as num?)?.toDouble() ?? 0,
      commissionPaid: (json['commissionPaid'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'NPR',
      distinctReelCount: (json['distinctReelCount'] as num?)?.toInt() ?? 0,
    );
  }
}
