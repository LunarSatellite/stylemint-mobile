import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/entities/public_brand_profile.dart';

/// Identity `PublicBrandProfileDto` (the anonymous, allow-listed brand read).
class PublicBrandProfileDto {
  const PublicBrandProfileDto({
    required this.accountId,
    required this.businessName,
    this.logoUrl,
    this.coverImageUrl,
    this.description,
    this.websiteUrl,
    this.tagline,
    this.brandStory,
    this.originCity,
    this.originCountryCode,
    this.foundedYear,
    this.isVerified = false,
    this.returnPolicySummary,
    this.supportUrl,
  });

  factory PublicBrandProfileDto.fromJson(Map<String, dynamic> json) {
    final year = json['foundedYear'] == null ? 0 : readInt(json['foundedYear']);
    return PublicBrandProfileDto(
      accountId: readString(json['accountId']),
      businessName: readString(json['businessName']),
      logoUrl: readOptionalString(json['logoUrl']),
      coverImageUrl: readOptionalString(json['coverImageUrl']),
      description: readOptionalString(json['description']),
      websiteUrl: readOptionalString(json['websiteUrl']),
      tagline: readOptionalString(json['tagline']),
      brandStory: readOptionalString(json['brandStory']),
      originCity: readOptionalString(json['originCity']),
      originCountryCode: readOptionalString(
        json['originCountryCode'],
      )?.toUpperCase(),
      foundedYear: year >= minFoundedYear ? year : null,
      isVerified: readBool(json['isVerified']),
      returnPolicySummary: readOptionalString(json['returnPolicySummary']),
      supportUrl: readOptionalString(json['supportUrl']),
    );
  }

  /// The backend accepts 1800..current year.
  static const int minFoundedYear = 1800;

  final String accountId;
  final String businessName;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? description;
  final String? websiteUrl;
  final String? tagline;
  final String? brandStory;
  final String? originCity;
  final String? originCountryCode;
  final int? foundedYear;
  final bool isVerified;
  final String? returnPolicySummary;
  final String? supportUrl;

  /// [requestedVendorAccountId] fills a missing account id.
  PublicBrandProfile toDomain(String requestedVendorAccountId) =>
      PublicBrandProfile(
        accountId: accountId.isEmpty ? requestedVendorAccountId : accountId,
        name: businessName.isEmpty ? 'StyleMint brand' : businessName,
        logoUrl: logoUrl,
        coverImageUrl: coverImageUrl,
        description: description,
        websiteUrl: websiteUrl,
        tagline: tagline,
        brandStory: brandStory,
        originCity: originCity,
        originCountryCode: originCountryCode,
        foundedYear: foundedYear,
        isVerified: isVerified,
        returnPolicySummary: returnPolicySummary,
        supportUrl: supportUrl,
      );
}
