import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';

part 'vendor_application_dto.freezed.dart';
part 'vendor_application_dto.g.dart';

/// Mirrors the backend's `Onboarding.Entity.Dtos.VendorApplicationDto` shape
/// (fields not consumed by the app — brandName, commission %, catalog size,
/// etc. — are intentionally omitted rather than kept in lockstep).
@freezed
abstract class VendorApplicationDto with _$VendorApplicationDto {
  const factory VendorApplicationDto({
    required String id,
    required int state,
    String? rejectionReason,
    DateTime? submittedAtUtc,
    required DateTime updatedUtc,
  }) = _VendorApplicationDto;

  const VendorApplicationDto._();

  factory VendorApplicationDto.fromJson(Map<String, dynamic> json) =>
      _$VendorApplicationDtoFromJson(json);

  VendorApplication toDomain() => VendorApplication(
    id: id,
    status: _statusFromState(state),
    rejectionReason: rejectionReason,
    submittedAt: submittedAtUtc,
    updatedAt: updatedUtc,
  );

  /// `Onboarding.Enums.ApplicationState`: Draft(1) → Submitted(2) →
  /// UnderReview(3) → Approved(4) | Rejected(5).
  static VendorApplicationStatus _statusFromState(int state) {
    switch (state) {
      case 1:
        return VendorApplicationStatus.draft;
      case 2:
        return VendorApplicationStatus.pending;
      case 3:
        return VendorApplicationStatus.underReview;
      case 4:
        return VendorApplicationStatus.approved;
      case 5:
        return VendorApplicationStatus.rejected;
      default:
        return VendorApplicationStatus.pending;
    }
  }
}

/// Wire shape for the backend's `VerificationDocumentDto` (Identity module).
/// `documentType`/`status` are the backend's int enums — see
/// `VerificationDocumentType` (Pan=7, Citizenship=8, BusinessRegistration=9,
/// TaxDocument=10 for vendor docs) and `VerificationDocumentStatus`
/// (Uploaded=1, UnderReview=2, Approved=3, Rejected=4, Expired=5).
/// `fileUrl` is NOT projected by the backend (internal storage detail) —
/// left empty; nothing in the UI currently renders it.
class KYCDocumentDto {
  const KYCDocumentDto({
    required this.id,
    required this.documentType,
    required this.status,
    required this.uploadedUtc,
    this.originalFilename,
  });

  factory KYCDocumentDto.fromJson(Map<String, dynamic> json) =>
      KYCDocumentDto(
        id: json['id'] as String,
        documentType: json['documentType'] as int,
        status: json['status'] as int,
        uploadedUtc: DateTime.parse(json['uploadedUtc'] as String),
        originalFilename: json['originalFilename'] as String?,
      );

  final String id;
  final int documentType;
  final int status;
  final DateTime uploadedUtc;
  final String? originalFilename;

  KYCDocument toDomain() => KYCDocument(
    id: id,
    type: _docTypeFromCode(documentType),
    fileName: originalFilename ?? _labelForCode(documentType),
    fileUrl: '',
    status: _docStatusFromCode(status),
    uploadedAt: uploadedUtc,
  );

  static KYCDocumentType _docTypeFromCode(int code) => switch (code) {
    8 => KYCDocumentType.citizenship,
    9 => KYCDocumentType.businessReg,
    10 => KYCDocumentType.taxDoc,
    _ => KYCDocumentType.pan,
  };

  static String _labelForCode(int code) => switch (code) {
    8 => 'Citizenship',
    9 => 'Business Registration',
    10 => 'Tax Document',
    _ => 'PAN Card',
  };

  static KYCDocumentStatus _docStatusFromCode(int code) => switch (code) {
    3 => KYCDocumentStatus.verified, // Approved
    4 || 5 => KYCDocumentStatus.rejected, // Rejected | Expired
    _ => KYCDocumentStatus.pending, // Uploaded | UnderReview
  };
}
