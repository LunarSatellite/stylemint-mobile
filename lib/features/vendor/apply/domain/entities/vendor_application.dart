enum VendorApplicationStatus {
  pending('Pending'),
  underReview('Under Review'),
  approved('Approved'),
  rejected('Rejected'),
  kycRequired('KYC Required');

  const VendorApplicationStatus(this.label);

  final String label;
}

class VendorApplication {
  const VendorApplication({
    required this.id,
    required this.status,
    this.rejectionReason,
    required this.submittedAt,
    required this.updatedAt,
  });

  final String id;
  final VendorApplicationStatus status;
  final String? rejectionReason;
  final DateTime submittedAt;
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

enum BusinessType {
  individual('Individual'),
  company('Company'),
  llp('LLP');

  const BusinessType(this.label);

  final String label;
}

class VendorApplicationForm {
  const VendorApplicationForm({
    required this.businessName,
    required this.businessType,
    required this.taxId,
    required this.businessRegistrationNumber,
    this.website,
    required this.countryRegion,
    required this.streetAddress,
    required this.city,
    required this.country,
    required this.zipCode,
    required this.state,
  });

  final String businessName;
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

  VendorApplicationForm copyWith({
    String? businessName,
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
  }) {
    return VendorApplicationForm(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      taxId: taxId ?? this.taxId,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      website: website ?? this.website,
      countryRegion: countryRegion ?? this.countryRegion,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      country: country ?? this.country,
      zipCode: zipCode ?? this.zipCode,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorApplicationForm &&
      other.businessName == businessName &&
      other.businessType == businessType &&
      other.taxId == taxId &&
      other.businessRegistrationNumber == businessRegistrationNumber &&
      other.website == website &&
      other.countryRegion == countryRegion &&
      other.streetAddress == streetAddress &&
      other.city == city &&
      other.country == country &&
      other.zipCode == zipCode &&
      other.state == state;

  @override
  int get hashCode => Object.hash(
    businessName, businessType, taxId, businessRegistrationNumber,
    website, countryRegion, streetAddress, city, country, zipCode, state,
  );
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
