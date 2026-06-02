/// `VendorCreatorPerformanceDto` from `GET /v1/vendor/creator-performance` —
/// real per-creator sales/earnings of the vendor's products over a window.
///
/// The endpoint returns a plain JSON array (not wrapped, not paged). Creator
/// handle/display-name/avatar are hydrated server-side; when a creator can't be
/// resolved they're null and the UI falls back to a short id label.
class CreatorPerformanceDto {
  const CreatorPerformanceDto({
    required this.creatorAccountId,
    required this.unitsSold,
    required this.attributedRevenue,
    required this.commissionPaid,
    required this.currency,
    required this.distinctReelCount,
    this.creatorHandle,
    this.creatorDisplayName,
    this.creatorAvatarUrl,
  });

  final String creatorAccountId;
  final int unitsSold;
  final double attributedRevenue;
  final double commissionPaid;
  final String currency;
  final int distinctReelCount;
  final String? creatorHandle;
  final String? creatorDisplayName;
  final String? creatorAvatarUrl;

  /// Best available creator label: display name → @handle → short-id fallback.
  String get label {
    final name = creatorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = creatorHandle?.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';
    return creatorAccountId.length >= 4
        ? 'Creator ••${creatorAccountId.substring(creatorAccountId.length - 4)}'
        : 'Creator';
  }

  factory CreatorPerformanceDto.fromJson(Map<String, dynamic> json) {
    return CreatorPerformanceDto(
      creatorAccountId: (json['creatorAccountId'] as String?) ?? '',
      unitsSold: (json['unitsSold'] as num?)?.toInt() ?? 0,
      attributedRevenue: (json['attributedRevenue'] as num?)?.toDouble() ?? 0,
      commissionPaid: (json['commissionPaid'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'NPR',
      distinctReelCount: (json['distinctReelCount'] as num?)?.toInt() ?? 0,
      creatorHandle: json['creatorHandle'] as String?,
      creatorDisplayName: json['creatorDisplayName'] as String?,
      creatorAvatarUrl: json['creatorAvatarUrl'] as String?,
    );
  }
}
