class VendorProfile {
  const VendorProfile({
    required this.id,
    required this.accountId,
    required this.businessName,
    required this.businessType,
    required this.commissionRangeMin,
    required this.commissionRangeMax,
    required this.status,
    this.logoUrl,
    this.description,
    this.websiteUrl,
  });

  final String id;
  final String accountId;
  final String businessName;
  final int businessType;
  final double commissionRangeMin;
  final double commissionRangeMax;
  final int status;
  final String? logoUrl;
  final String? description;
  final String? websiteUrl;
}
