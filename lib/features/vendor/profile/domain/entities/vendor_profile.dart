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
    this.serviceCategory = 0,
    this.serviceLicenceNumber,
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

  /// service-banks contract v1: 0 product seller, 1 Hotel, 2 TravelAgency,
  /// 3 Bank. Read it through `ServiceCategory.fromWire`.
  final int serviceCategory;

  /// The NRB / tourism licence number the admin approved, if any.
  final String? serviceLicenceNumber;
}
