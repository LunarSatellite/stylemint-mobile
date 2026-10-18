enum VendorApplicationStatus {
  draft('Draft'),
  pending('Pending'),
  underReview('Under Review'),
  approved('Approved'),
  rejected('Rejected');

  const VendorApplicationStatus(this.label);

  final String label;
}

class VendorApplication {
  const VendorApplication({
    required this.id,
    required this.status,
    this.rejectionReason,
    this.submittedAt,
    required this.updatedAt,
  });

  final String id;
  final VendorApplicationStatus status;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime updatedAt;

  VendorApplication copyWith({
    String? id,
    VendorApplicationStatus? status,
    String? rejectionReason,
    DateTime? submittedAt,
    DateTime? updatedAt,
  }) {
    return VendorApplication(
      id: id ?? this.id,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorApplication &&
      other.id == id &&
      other.status == status &&
      other.rejectionReason == rejectionReason &&
      other.submittedAt == submittedAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, status, rejectionReason, submittedAt, updatedAt);
}

/// Legal form of the vendor entity — the backend's
/// `Onboarding.Enums.BusinessType` (and Identity's copy): 1 Individual,
/// 2 SoleProprietorship, 3 LimitedLiability, 4 Corporation, 5 Partnership,
/// 6 NonProfit. Until 2026-10-18 the labels here were guessed and 3–5 were
/// mislabelled (Partnership sent 3 = LimitedLiability); a bank must apply
/// as 3 or 4 (service-banks contract v1), so the codes now match.
enum BusinessType {
  individual(1, 'Individual'),
  soleProprietorship(2, 'Sole Proprietorship'),
  limitedLiabilityCompany(3, 'Limited Liability Company (Pvt Ltd)'),
  corporation(4, 'Corporation'),
  partnership(5, 'Partnership'),
  nonProfit(6, 'Non-Profit');

  const BusinessType(this.code, this.label);

  final int code;
  final String label;

  static BusinessType fromCode(int code) => values.firstWhere(
    (e) => e.code == code,
    orElse: () => BusinessType.individual,
  );
}

/// Self-reported catalog size band — matches the 5 options on the Vendor
/// Screen 1E product-information dropdown 1:1 with backend's
/// `CatalogSizeEstimate` (ints 1-5).
enum CatalogSizeEstimate {
  tiny(1, '1-10 products'),
  small(2, '11-50 products'),
  medium(3, '51-100 products'),
  large(4, '101-500 products'),
  extraLarge(5, '500+ products');

  const CatalogSizeEstimate(this.code, this.label);

  final int code;
  final String label;

  static CatalogSizeEstimate? fromLabel(String? label) {
    for (final e in values) {
      if (e.label == label) return e;
    }
    return null;
  }
}

/// Wire values confirmed against backend's `BankAccountType` (ints 1-2).
enum BankAccountType {
  checking(1, 'Checking'),
  savings(2, 'Savings');

  const BankAccountType(this.code, this.label);

  final int code;
  final String label;

  static BankAccountType? fromLabel(String? label) {
    for (final e in values) {
      if (e.label == label) return e;
    }
    return null;
  }
}

class VendorBankAccountForm {
  const VendorBankAccountForm({
    required this.accountHolderName,
    required this.bankName,
    required this.accountType,
    required this.routingNumber,
    required this.accountNumber,
    this.w9StorageUri,
    this.taxAttestationAccepted = false,
  });

  final String accountHolderName;
  final String bankName;
  final BankAccountType accountType;
  final String routingNumber;
  final String accountNumber;
  final String? w9StorageUri;
  final bool taxAttestationAccepted;
}

/// Fields required by the backend's vendor-application wizard
/// (`brandName`/`legalBusinessName`/`countryCode`/`businessType` via
/// `draft/step-1`, `website`/`taxId` via `step-3`, commission % via
/// `step-2`) plus fields that only exist on the legacy single-shot
/// `POST /v1/vendor/apply` endpoint (address, catalog size, price range,
/// brand story, bank account) — the draft wizard has no step for those yet.
class VendorApplicationForm {
  const VendorApplicationForm({
    required this.brandName,
    required this.legalBusinessName,
    required this.countryCode,
    required this.businessType,
    required this.taxId,
    required this.businessRegistrationNumber,
    required this.commissionMinPercent,
    required this.commissionMaxPercent,
    this.website,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.stateProvince,
    this.postalCode,
    this.catalogSize,
    this.priceRangeMinAmount,
    this.priceRangeMaxAmount,
    this.priceRangeCurrency,
    this.brandStory,
    this.bankAccount,
    this.serviceCategory = 0,
    this.licenceNumber,
    this.licenceIssuer,
    this.licenceExpiresOn,
    this.licenceDocumentRef,
  });

  final String brandName;
  final String legalBusinessName;
  final String countryCode;
  final BusinessType businessType;
  final String taxId;
  final String businessRegistrationNumber;
  final double commissionMinPercent;
  final double commissionMaxPercent;
  final String? website;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? stateProvince;
  final String? postalCode;
  final CatalogSizeEstimate? catalogSize;
  final double? priceRangeMinAmount;
  final double? priceRangeMaxAmount;
  final String? priceRangeCurrency;
  final String? brandStory;
  final VendorBankAccountForm? bankAccount;

  /// service-banks contract v1: 0 product seller, 1 Hotel, 2 TravelAgency,
  /// 3 Bank. The licence fields are only sent for a service vendor.
  final int serviceCategory;

  /// Bank: the NRB licence number (required). Hotel / travel: the tourism
  /// licence (optional).
  final String? licenceNumber;
  final String? licenceIssuer;
  final DateTime? licenceExpiresOn;

  /// The uploaded licence certificate (`blobReference` from the KYC blob
  /// upload), attached to the draft as document kind 5 OperatingLicence.
  final String? licenceDocumentRef;

  bool get isServiceVendor => serviceCategory != 0;
}

enum KYCDocumentType {
  pan('PAN'),
  citizenship('Citizenship'),
  businessReg('Business Registration'),
  taxDoc('Tax Document');

  const KYCDocumentType(this.label);

  final String label;
}

enum KYCDocumentStatus {
  pending('Pending'),
  verified('Verified'),
  rejected('Rejected');

  const KYCDocumentStatus(this.label);

  final String label;
}

class KYCDocument {
  const KYCDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.fileUrl,
    required this.status,
    required this.uploadedAt,
  });

  final String id;
  final KYCDocumentType type;
  final String fileName;
  final String fileUrl;
  final KYCDocumentStatus status;
  final DateTime uploadedAt;

  KYCDocument copyWith({
    String? id,
    KYCDocumentType? type,
    String? fileName,
    String? fileUrl,
    KYCDocumentStatus? status,
    DateTime? uploadedAt,
  }) {
    return KYCDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      fileUrl: fileUrl ?? this.fileUrl,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KYCDocument &&
      other.id == id &&
      other.type == type &&
      other.fileName == fileName &&
      other.fileUrl == fileUrl &&
      other.status == status &&
      other.uploadedAt == uploadedAt;

  @override
  int get hashCode =>
      Object.hash(id, type, fileName, fileUrl, status, uploadedAt);
}
