/// An approved vendor as shown in the creator-facing brand catalog
/// (`GET /v1/brands` and `/v1/brands/recommended`).
class Brand {
  const Brand({
    required this.vendorAccountId,
    required this.businessName,
    required this.commissionRangeMinPercent,
    required this.commissionRangeMaxPercent,
    this.logoUrl,
  });

  final String vendorAccountId;
  final String businessName;

  /// Already expressed as a percentage (the wire format sends a fraction).
  final double commissionRangeMinPercent;
  final double commissionRangeMaxPercent;
  final String? logoUrl;

  String get commissionRangeLabel =>
      '${commissionRangeMinPercent.toStringAsFixed(0)}-'
      '${commissionRangeMaxPercent.toStringAsFixed(0)}%';
}
