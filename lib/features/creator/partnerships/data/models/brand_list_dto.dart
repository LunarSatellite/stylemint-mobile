/// Maps a `VendorProfileDto` row from `GET /v1/brands` / `/v1/brands/recommended`.
class BrandListItemDto {
  const BrandListItemDto({
    required this.vendorAccountId,
    required this.businessName,
    this.logoUrl,
    required this.commissionRangeMinPercent,
    required this.commissionRangeMaxPercent,
  });

  factory BrandListItemDto.fromJson(Map<String, dynamic> json) => BrandListItemDto(
        vendorAccountId: json['accountId'] as String? ?? '',
        businessName: json['businessName'] as String? ?? '',
        logoUrl: json['logoUrl'] as String?,
        commissionRangeMinPercent:
            ((json['commissionRangeMin'] as num?)?.toDouble() ?? 0) * 100,
        commissionRangeMaxPercent:
            ((json['commissionRangeMax'] as num?)?.toDouble() ?? 0) * 100,
      );

  final String vendorAccountId;
  final String businessName;
  final String? logoUrl;
  final double commissionRangeMinPercent;
  final double commissionRangeMaxPercent;

  String get commissionRangeLabel =>
      '${commissionRangeMinPercent.toStringAsFixed(0)}-${commissionRangeMaxPercent.toStringAsFixed(0)}%';
}
