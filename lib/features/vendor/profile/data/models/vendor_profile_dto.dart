import 'package:stylemint_mobile_frontend/features/vendor/profile/domain/entities/vendor_profile.dart';

class VendorProfileDto {
  const VendorProfileDto({
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

  factory VendorProfileDto.fromJson(
    Map<String, dynamic> json,
  ) => VendorProfileDto(
    id: json['id'] as String? ?? '',
    accountId: json['accountId'] as String? ?? '',
    businessName: json['businessName'] as String? ?? '',
    businessType: (json['businessType'] as num?)?.toInt() ?? 0,
    commissionRangeMin: (json['commissionRangeMin'] as num?)?.toDouble() ?? 0,
    commissionRangeMax: (json['commissionRangeMax'] as num?)?.toDouble() ?? 0,
    status: (json['status'] as num?)?.toInt() ?? 0,
    logoUrl: json['logoUrl'] as String?,
    description: json['description'] as String?,
    websiteUrl: json['websiteUrl'] as String?,
  );

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

  VendorProfile toDomain() => VendorProfile(
    id: id,
    accountId: accountId,
    businessName: businessName,
    businessType: businessType,
    commissionRangeMin: commissionRangeMin,
    commissionRangeMax: commissionRangeMax,
    status: status,
    logoUrl: logoUrl,
    description: description,
    websiteUrl: websiteUrl,
  );
}
