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
  int get hashCode => Object.hash(id, status, rejectionReason, submittedAt, updatedAt);
}

/// Legal form of the vendor entity — wire values are confirmed against the
/// backend's `Onboarding.Enums.BusinessType` (ints 1-6), but the backend
/// swagger doesn't expose member names, so the labels below are inferred and
/// unconfirmed. Verify with backend before this ships.
enum BusinessType {
  individual(1, 'Individual'),
  soleProprietorship(2, 'Sole Proprietorship'),
  partnership(3, 'Partnership'),
  limitedLiabilityCompany(4, 'Limited Liability Company'),
  corporation(5, 'Corporation'),
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
  int get hashCode => Object.hash(id, type, fileName, fileUrl, status, uploadedAt);
}
