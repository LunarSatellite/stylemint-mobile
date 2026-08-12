/// Identity document types the backend accepts, mirroring the Identity
/// module's `VerificationDocumentType` enum. Values 1-6 are personal
/// documents; 7-10 are vendor business documents and are deliberately not
/// surfaced in the creator flow.
enum IdentityDocumentType {
  passport(1),
  nationalIdCard(2),
  driversLicense(3),
  residencePermit(4),
  selfiePhoto(5),
  addressProof(6);

  const IdentityDocumentType(this.wireValue);

  final int wireValue;

  String get label => switch (this) {
        IdentityDocumentType.passport => 'Passport',
        IdentityDocumentType.nationalIdCard => 'National ID card',
        IdentityDocumentType.driversLicense => "Driver's license",
        IdentityDocumentType.residencePermit => 'Residence permit',
        IdentityDocumentType.selfiePhoto => 'Selfie photo',
        IdentityDocumentType.addressProof => 'Proof of address',
      };

  /// Passport, selfie and address proof are single-page; ID cards and
  /// licenses need both sides.
  bool get needsBothSides =>
      this == IdentityDocumentType.nationalIdCard ||
      this == IdentityDocumentType.driversLicense ||
      this == IdentityDocumentType.residencePermit;
}

/// Which face of a two-sided document this file is. Mirrors the backend's
/// `VerificationDocumentSide`.
enum IdentityDocumentSide {
  notApplicable(0),
  front(1),
  back(2);

  const IdentityDocumentSide(this.wireValue);

  final int wireValue;
}

/// A file that has been pushed to blob storage but not yet registered
/// against a KYC session. Step 1 of 2 — see [IdentityDocument].
class UploadedDocumentBlob {
  const UploadedDocumentBlob({
    required this.blobReference,
    required this.contentHash,
    required this.contentSizeBytes,
    required this.contentType,
    this.originalFilename,
  });

  final String blobReference;
  final String contentHash;
  final int contentSizeBytes;
  final String contentType;
  final String? originalFilename;
}

/// A document registered against a KYC session and awaiting review.
class IdentityDocument {
  const IdentityDocument({
    required this.id,
    required this.sessionId,
    required this.type,
    required this.side,
    required this.status,
    this.originalFilename,
    this.rejectionReason,
  });

  final String id;
  final String sessionId;
  final IdentityDocumentType type;
  final IdentityDocumentSide side;

  /// Raw backend status string (Pending / UnderReview / Approved / Rejected).
  final String status;
  final String? originalFilename;

  /// Populated once a reviewer rejects the document, so the rejected screen
  /// can tell the creator which document to replace and why.
  final String? rejectionReason;

  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isApproved => status.toLowerCase() == 'approved';
}

/// An identity-verification (KYC) session. Documents attach to one of these.
class KycSession {
  const KycSession({required this.id, required this.status});

  final String id;
  final String status;
}
