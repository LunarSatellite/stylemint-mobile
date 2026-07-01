import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';

/// ISO 3166-1 alpha-2 codes for the Country/Region picker options in
/// [VendorApplyScreen]. Kept here (not in the domain layer) since it's a
/// presentation-facing label→code lookup, not a domain concept.
const Map<String, String> _countryCodes = {
  'Nepal': 'NP',
  'India': 'IN',
  'United States': 'US',
  'United Kingdom': 'GB',
  'Canada': 'CA',
  'Australia': 'AU',
  'Germany': 'DE',
  'France': 'FR',
  'China': 'CN',
  'Japan': 'JP',
  'South Korea': 'KR',
  'Singapore': 'SG',
  'UAE': 'AE',
  'Bangladesh': 'BD',
  'Pakistan': 'PK',
  'Sri Lanka': 'LK',
  'Thailand': 'TH',
  'Vietnam': 'VN',
  'Indonesia': 'ID',
  'Malaysia': 'MY',
  'Philippines': 'PH',
};

class VendorApplyDraft {
  const VendorApplyDraft({
    required this.accountId,
    // Step 1 — required
    required this.brandName,
    required this.legalBusinessName,
    required this.businessType,
    required this.taxId,
    required this.businessRegistrationNumber,
    required this.countryRegion,
    required this.streetAddress,
    required this.city,
    required this.country,
    required this.zipCode,
    required this.state,
    this.website,
    // Step 2 — optional, filled later. No backend field exists for any of
    // this (kept for local review-screen display only, never submitted).
    this.supportEmail = '',
    this.supportPhone = '',
    this.returnPolicyUrl,
    this.contactFullName = '',
    this.contactPosition = '',
    this.contactEmail = '',
    this.contactPhone = '',
    this.businessHours = const [],
    // Step 3 — local only; blocked on a backend file-upload endpoint.
    this.uploadedDocCategories = const [],
    // Step 4
    this.accountHolder = '',
    this.bankName = '',
    this.accountType,
    this.routingNumber = '',
    this.accountNumber = '',
    this.w9FileName,
    this.taxCertified = false,
    // Step 5 — productCategories has no backend field (local display only).
    this.productCategories = const [],
    this.catalogSize,
    this.minPrice,
    this.maxPrice,
    this.commissionMinRate,
    this.commissionMaxRate,
    this.brandStory,
  });

  final String accountId;

  // Step 1
  final String brandName;
  final String legalBusinessName;
  final BusinessType businessType;
  final String taxId;
  final String businessRegistrationNumber;
  final String? website;
  final String countryRegion;
  final String streetAddress;
  final String city;
  final String country;
  final String zipCode;
  final String state;

  // Step 2
  final String supportEmail;
  final String supportPhone;
  final String? returnPolicyUrl;
  final String contactFullName;
  final String contactPosition;
  final String contactEmail;
  final String contactPhone;
  final List<String> businessHours;

  // Step 3
  final List<String> uploadedDocCategories;

  // Step 4
  final String accountHolder;
  final String bankName;
  final String? accountType;
  final String routingNumber;
  final String accountNumber;
  final String? w9FileName;
  final bool taxCertified;

  // Step 5
  final List<String> productCategories;
  final String? catalogSize;
  final String? minPrice;
  final String? maxPrice;
  final String? commissionMinRate;
  final String? commissionMaxRate;
  final String? brandStory;

  VendorApplicationForm toForm() => VendorApplicationForm(
    brandName: brandName,
    legalBusinessName: legalBusinessName,
    countryCode: _countryCodes[countryRegion] ?? countryRegion,
    businessType: businessType,
    taxId: taxId,
    commissionMinPercent: double.tryParse(commissionMinRate ?? '') ?? 0,
    commissionMaxPercent: double.tryParse(commissionMaxRate ?? '') ?? 0,
    website: website,
    addressLine1: streetAddress.isEmpty ? null : streetAddress,
    city: city.isEmpty ? null : city,
    stateProvince: state.isEmpty ? null : state,
    postalCode: zipCode.isEmpty ? null : zipCode,
    catalogSize: CatalogSizeEstimate.fromLabel(catalogSize),
    priceRangeMinAmount: double.tryParse(minPrice ?? ''),
    priceRangeMaxAmount: double.tryParse(maxPrice ?? ''),
    priceRangeCurrency: (minPrice != null || maxPrice != null) ? 'NPR' : null,
    brandStory: brandStory,
    bankAccount: _buildBankAccount(),
  );

  VendorBankAccountForm? _buildBankAccount() {
    final type = BankAccountType.fromLabel(accountType);
    if (accountHolder.isEmpty ||
        bankName.isEmpty ||
        type == null ||
        routingNumber.isEmpty ||
        accountNumber.isEmpty) {
      return null;
    }
    return VendorBankAccountForm(
      accountHolderName: accountHolder,
      bankName: bankName,
      accountType: type,
      routingNumber: routingNumber,
      accountNumber: accountNumber,
      taxAttestationAccepted: taxCertified,
    );
  }

  VendorApplyDraft copyWith({
    String? accountId,
    String? brandName,
    String? legalBusinessName,
    BusinessType? businessType,
    String? taxId,
    String? businessRegistrationNumber,
    String? website,
    String? countryRegion,
    String? streetAddress,
    String? city,
    String? country,
    String? zipCode,
    String? state,
    String? supportEmail,
    String? supportPhone,
    String? returnPolicyUrl,
    String? contactFullName,
    String? contactPosition,
    String? contactEmail,
    String? contactPhone,
    List<String>? businessHours,
    List<String>? uploadedDocCategories,
    String? accountHolder,
    String? bankName,
    String? accountType,
    String? routingNumber,
    String? accountNumber,
    String? w9FileName,
    bool? taxCertified,
    List<String>? productCategories,
    String? catalogSize,
    String? minPrice,
    String? maxPrice,
    String? commissionMinRate,
    String? commissionMaxRate,
    String? brandStory,
  }) {
    return VendorApplyDraft(
      accountId: accountId ?? this.accountId,
      brandName: brandName ?? this.brandName,
      legalBusinessName: legalBusinessName ?? this.legalBusinessName,
      businessType: businessType ?? this.businessType,
      taxId: taxId ?? this.taxId,
      businessRegistrationNumber:
          businessRegistrationNumber ?? this.businessRegistrationNumber,
      website: website ?? this.website,
      countryRegion: countryRegion ?? this.countryRegion,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      state: state ?? this.state,
      supportEmail: supportEmail ?? this.supportEmail,
      supportPhone: supportPhone ?? this.supportPhone,
      returnPolicyUrl: returnPolicyUrl ?? this.returnPolicyUrl,
      contactFullName: contactFullName ?? this.contactFullName,
      contactPosition: contactPosition ?? this.contactPosition,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      businessHours: businessHours ?? this.businessHours,
      uploadedDocCategories:
          uploadedDocCategories ?? this.uploadedDocCategories,
      accountHolder: accountHolder ?? this.accountHolder,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      routingNumber: routingNumber ?? this.routingNumber,
      accountNumber: accountNumber ?? this.accountNumber,
      w9FileName: w9FileName ?? this.w9FileName,
      taxCertified: taxCertified ?? this.taxCertified,
      productCategories: productCategories ?? this.productCategories,
      catalogSize: catalogSize ?? this.catalogSize,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      commissionMinRate: commissionMinRate ?? this.commissionMinRate,
      commissionMaxRate: commissionMaxRate ?? this.commissionMaxRate,
      brandStory: brandStory ?? this.brandStory,
    );
  }
}
