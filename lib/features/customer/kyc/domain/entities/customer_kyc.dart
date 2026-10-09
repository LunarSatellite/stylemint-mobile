/// Buyer KYC Tier 2, as `GET /v1/customer/kyc` describes it.
///
/// Built on Identity's existing verification session, documents, selfie and
/// address — not a parallel KYC system. The wire values are strings; anything
/// this build does not know reads as [KycStatus.unknown] rather than as a
/// status it might be mistaken for.
library;

enum KycStatus {
  none('None'),
  pending('Pending'),
  submitted('Submitted'),
  underReview('UnderReview'),
  approved('Approved'),
  rejected('Rejected'),
  expired('Expired'),
  unknown('');

  const KycStatus(this.wire);

  final String wire;

  static KycStatus fromWire(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return unknown;
    final needle = raw.trim().toLowerCase().replaceAll('_', '');
    for (final status in values) {
      if (status != unknown && status.wire.toLowerCase() == needle) {
        return status;
      }
    }
    return unknown;
  }

  /// Sent for review and not yet decided.
  bool get isInReview => this == submitted || this == underReview;

  /// Nothing has been sent yet — the buyer may (still) fill the form in.
  bool get isNotStarted => this == none || this == pending;
}

/// The identity document a buyer verifies with.
enum KycDocumentType {
  citizenship('Citizenship', 'Citizenship certificate'),
  nationalId('NationalId', 'National ID card'),
  passport('Passport', 'Passport');

  const KycDocumentType(this.wire, this.label);

  final String wire;
  final String label;

  static KycDocumentType? fromWire(Object? raw) {
    if (raw is! String) return null;
    final needle = raw.trim().toLowerCase();
    for (final type in values) {
      if (type.wire.toLowerCase() == needle) return type;
    }
    return null;
  }

  /// The photos the server requires before it accepts a submit: front, back
  /// and a selfie — or, for a passport, the bio page and a selfie.
  List<KycDocumentKind> get requiredKinds => switch (this) {
    citizenship => const [
      KycDocumentKind.citizenshipFront,
      KycDocumentKind.citizenshipBack,
      KycDocumentKind.selfie,
    ],
    nationalId => const [
      KycDocumentKind.nationalIdFront,
      KycDocumentKind.nationalIdBack,
      KycDocumentKind.selfie,
    ],
    passport => const [KycDocumentKind.passportBio, KycDocumentKind.selfie],
  };
}

/// One photo the buyer uploads — the multipart `kind` field.
enum KycDocumentKind {
  citizenshipFront('CitizenshipFront', 'Front of your citizenship'),
  citizenshipBack('CitizenshipBack', 'Back of your citizenship'),
  nationalIdFront('NationalIdFront', 'Front of your national ID'),
  nationalIdBack('NationalIdBack', 'Back of your national ID'),
  passportBio('PassportBio', 'Passport photo page'),
  selfie('Selfie', 'Selfie');

  const KycDocumentKind(this.wire, this.label);

  final String wire;
  final String label;

  static KycDocumentKind? fromWire(Object? raw) {
    if (raw is! String) return null;
    final needle = raw.trim().toLowerCase();
    for (final kind in values) {
      if (kind.wire.toLowerCase() == needle) return kind;
    }
    return null;
  }

  /// The selfie must come from the camera; an ID page may be picked.
  bool get isSelfie => this == selfie;
}

/// A document already on the server — `CustomerKycDocumentDto`.
class CustomerKycDocument {
  const CustomerKycDocument({
    required this.id,
    required this.kind,
    this.uploadedUtc,
    this.thumbnailUrl,
  });

  final String id;
  final KycDocumentKind kind;
  final DateTime? uploadedUtc;
  final String? thumbnailUrl;
}

/// `CustomerKycDto`.
class CustomerKyc {
  const CustomerKyc({
    required this.tier,
    required this.status,
    this.sessionId,
    this.documentType,
    this.documents = const <CustomerKycDocument>[],
    this.missingDocuments = const <KycDocumentKind>[],
    this.rejectionReason,
    this.canResubmit = false,
    this.submittedUtc,
    this.reviewedUtc,
    this.expiresUtc,
  });

  /// The empty record — nothing started.
  static const notStarted = CustomerKyc(tier: 0, status: KycStatus.none);

  final int tier;
  final KycStatus status;
  final String? sessionId;
  final KycDocumentType? documentType;
  final List<CustomerKycDocument> documents;
  final List<KycDocumentKind> missingDocuments;
  final String? rejectionReason;
  final bool canResubmit;
  final DateTime? submittedUtc;
  final DateTime? reviewedUtc;
  final DateTime? expiresUtc;

  bool get isVerified => status == KycStatus.approved && tier >= 2;

  /// The uploaded document of [kind] in the open session, if any.
  CustomerKycDocument? documentOf(KycDocumentKind kind) {
    for (final document in documents) {
      if (document.kind == kind) return document;
    }
    return null;
  }

  /// Whether the buyer can fill in (or re-fill) the form now.
  bool get canStartOrResume =>
      status.isNotStarted ||
      status == KycStatus.expired ||
      (status == KycStatus.rejected && canResubmit);
}

/// What the buyer typed on the details step — the submit body minus the
/// session.
class KycDetails {
  const KycDetails({
    required this.fullName,
    required this.dateOfBirth,
    required this.documentType,
    required this.documentNumber,
    required this.addressId,
  });

  final String fullName;
  final DateTime dateOfBirth;
  final KycDocumentType documentType;
  final String documentNumber;
  final String addressId;

  /// `yyyy-MM-dd`, the contract's date-only form.
  String get dateOfBirthWire =>
      '${dateOfBirth.year.toString().padLeft(4, '0')}-'
      '${dateOfBirth.month.toString().padLeft(2, '0')}-'
      '${dateOfBirth.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'fullName': fullName.trim(),
    'dateOfBirth': dateOfBirthWire,
    'documentType': documentType.wire,
    'documentNumber': documentNumber.trim(),
    'addressId': addressId,
  };
}

/// Whether someone born on [dateOfBirth] is 18 or older on [today]. Compares
/// calendar dates, so the 18th birthday itself counts.
bool isAtLeast18(DateTime dateOfBirth, DateTime today) {
  final eighteenth = DateTime(
    dateOfBirth.year + 18,
    dateOfBirth.month,
    dateOfBirth.day,
  );
  final date = DateTime(today.year, today.month, today.day);
  return !date.isBefore(eighteenth);
}
