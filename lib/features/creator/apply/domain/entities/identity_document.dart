/// Identity document types the backend accepts, mirroring the Identity
/// module's `VerificationDocumentType` enum. Values 1-6 are personal
/// documents; 7-10 are vendor business documents and are deliberately not
/// surfaced in the creator flow.
enum IdentityDocumentType implements WireEnum {
  passport(1),
  nationalIdCard(2),
  driversLicense(3),
  residencePermit(4),
  selfiePhoto(5),
  addressProof(6);

  const IdentityDocumentType(this.wireValue);

  @override
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
///
/// **These start at 1, not 0.** The mirror was previously off by one
/// (`notApplicable(0), front(1), back(2)`), so every registered document was
/// rejected by Postgres rather than by validation:
///
/// * a selfie went up as `0`, which fails `ck_verification_documents_side_range`
///   (`side BETWEEN 1 AND 3`);
/// * an ID front went up as `1`, which the server reads as *NotApplicable* and
///   which fails `ck_verification_documents_side_matches_type` — a two-sided
///   type must carry Front or Back;
/// * an ID back went up as `2`, read as *Front*, failing the same rule.
///
/// Nothing could be registered at all. Keep these numbers identical to
/// `StyleMint.Modules.Identity.Enums.VerificationDocumentSide`.
enum IdentityDocumentSide implements WireEnum {
  notApplicable(1),
  front(2),
  back(3);

  const IdentityDocumentSide(this.wireValue);

  @override
  final int wireValue;
}

/// An enum that travels as a number.
///
/// The API registers no global `JsonStringEnumConverter` — see
/// `StyleMintPlatform.AddControllers`, which adds filters and no JSON options
/// — so a C# enum serialises as its integer value unless it carries its own
/// `[JsonConverter(typeof(JsonStringEnumConverter<T>))]` attribute. Plenty of
/// them do; `KycSessionStatus` and `VerificationDocumentStatus` do not.
abstract interface class WireEnum implements Enum {
  int get wireValue;

  // `name` is deliberately not redeclared here. On an enum it comes from the
  // `EnumName` extension in dart:core, not from the class, so an interface
  // that demands `String get name` can never be satisfied by an enum:
  //
  //   Missing concrete implementation of 'getter WireEnum.name'
  //
  // Implementing `Enum` instead is what makes `value.name` resolve inside
  // `wireEnum` below — the extension applies to anything statically typed as
  // Enum — and every enum here satisfies it for free.
}

/// Resolves [raw] — a number from the wire — to one of [values].
///
/// Accepts a string too, so adding `JsonStringEnumConverter` to one of these
/// enums server-side changes the payload without breaking the client. A
/// casual `as String?` here is what broke the whole KYC flow: the cast threw
/// `_TypeError` on the integer the server actually sends, which is not a
/// `DioException`, so it surfaced as "we could not accept those documents"
/// from a server that had never been sent any.
T? wireEnum<T extends WireEnum>(Object? raw, List<T> values) {
  int? code;
  if (raw is num) {
    code = raw.toInt();
  } else if (raw is String) {
    final name = raw.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    for (final value in values) {
      if (value.name.toLowerCase() == name) return value;
    }
    code = int.tryParse(raw.trim());
  }
  if (code == null) return null;
  for (final value in values) {
    if (value.wireValue == code) return value;
  }
  return null;
}

/// Per-document review state. Mirrors
/// `StyleMint.Modules.Identity.Enums.VerificationDocumentStatus`.
enum IdentityDocumentStatus implements WireEnum {
  /// Registered against the session, nobody has looked at it yet.
  uploaded(1, 'Pending review'),
  underReview(2, 'Under review'),
  approved(3, 'Approved'),
  rejected(4, 'Rejected'),
  expired(5, 'Expired');

  const IdentityDocumentStatus(this.wireValue, this.label);

  @override
  final int wireValue;

  /// Shown to the applicant, so it reads as English rather than as the
  /// server's member name.
  final String label;
}

/// Session-level KYC state. Mirrors
/// `StyleMint.Modules.Identity.Enums.KycSessionStatus`.
enum KycSessionStatus implements WireEnum {
  pending(1, 'Pending'),
  submitted(2, 'Submitted'),
  underReview(3, 'Under review'),
  approved(4, 'Approved'),
  rejected(5, 'Rejected'),
  expired(6, 'Expired');

  const KycSessionStatus(this.wireValue, this.label);

  @override
  final int wireValue;

  final String label;
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

  final IdentityDocumentStatus status;
  final String? originalFilename;

  /// Populated once a reviewer rejects the document, so the rejected screen
  /// can tell the creator which document to replace and why.
  final String? rejectionReason;

  bool get isRejected => status == IdentityDocumentStatus.rejected;
  bool get isApproved => status == IdentityDocumentStatus.approved;
}

/// An identity-verification (KYC) session. Documents attach to one of these.
class KycSession {
  const KycSession({
    required this.id,
    required this.status,
    this.expiresUtc,
  });

  final String id;
  final KycSessionStatus status;

  /// When the applicant's window to finish uploading closes. Null when the
  /// server did not say, which is treated as "no deadline known" rather than
  /// as expired — refusing to reuse a session we simply cannot date would
  /// strand anyone on an older API.
  final DateTime? expiresUtc;

  /// Whether documents can still be added to this session AND the session
  /// can then be submitted.
  ///
  /// Both halves matter. A session past [expiresUtc] is a trap: documents
  /// register into it happily and the submit is then refused with "Cannot
  /// submit an expired KYC session", so the applicant uploads their ID and
  /// selfie and is told it failed. Reuse is only safe while the session is
  /// Pending and inside its window.
  bool isOpenForUpload([DateTime? nowUtc]) {
    if (status != KycSessionStatus.pending) return false;
    final expiry = expiresUtc;
    if (expiry == null) return true;
    return expiry.isAfter(nowUtc ?? DateTime.now().toUtc());
  }
}
