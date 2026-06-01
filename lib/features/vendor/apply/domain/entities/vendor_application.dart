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
    required this.ownerFullName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.description,
    this.website,
    required this.categories,
  });

  final String businessName;
  final BusinessType businessType;
  final String taxId;
  final String ownerFullName;
  final String ownerPhone;
  final String ownerEmail;
  final String description;
  final String? website;
  final List<String> categories;

  VendorApplicationForm copyWith({
    String? businessName,
    BusinessType? businessType,
    String? taxId,
    String? ownerFullName,
    String? ownerPhone,
    String? ownerEmail,
    String? description,
    String? website,
    List<String>? categories,
  }) {
    return VendorApplicationForm(
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      taxId: taxId ?? this.taxId,
      ownerFullName: ownerFullName ?? this.ownerFullName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      description: description ?? this.description,
      website: website ?? this.website,
      categories: categories ?? this.categories,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is VendorApplicationForm &&
      other.businessName == businessName &&
      other.businessType == businessType &&
      other.taxId == taxId &&
      other.ownerFullName == ownerFullName &&
      other.ownerPhone == ownerPhone &&
      other.ownerEmail == ownerEmail &&
      other.description == description &&
      other.website == website &&
      _listEquals(other.categories, categories);

  @override
  int get hashCode => Object.hash(businessName, businessType, taxId, ownerFullName, ownerPhone, ownerEmail, description, website, categories.length);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
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
