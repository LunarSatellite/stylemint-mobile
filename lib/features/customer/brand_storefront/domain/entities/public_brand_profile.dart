import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/domain/country_names.dart';

/// `GET v1/public/brands/{vendorAccountId}`: an approved brand's public
/// profile.
class PublicBrandProfile {
  const PublicBrandProfile({
    required this.accountId,
    required this.name,
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

  /// The vendor's account id (the storefront route key).
  final String accountId;
  final String name;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? description;
  final String? websiteUrl;
  final String? tagline;
  final String? brandStory;
  final String? originCity;

  /// ISO 3166-1 alpha-2, upper case.
  final String? originCountryCode;
  final int? foundedYear;
  final bool isVerified;
  final String? returnPolicySummary;
  final String? supportUrl;

  /// The brand story, or the description when there is no story.
  String? get story => brandStory ?? description;

  /// "Kathmandu, Nepal", or null when neither city nor country is known.
  String? get origin {
    final parts = [?originCity, ?countryName(originCountryCode)];
    return parts.isEmpty ? null : parts.join(', ');
  }

  /// "Kathmandu, Nepal · Since 2019", or null when nothing is known.
  String? get originLine {
    final year = foundedYear;
    final parts = [?origin, if (year != null) 'Since $year'];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// [supportUrl] when it is an absolute https link; nothing else is opened.
  Uri? get supportUri {
    final uri = Uri.tryParse(supportUrl?.trim() ?? '');
    if (uri == null ||
        uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty) {
      return null;
    }
    return uri;
  }
}
