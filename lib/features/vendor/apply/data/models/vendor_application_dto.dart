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

@freezed
abstract class KYCDocumentDto with _$KYCDocumentDto {
  const factory KYCDocumentDto({
    required String id,
    required String type,
    required String fileName,
    required String fileUrl,
    required String status,
    required DateTime uploadedAt,
  }) = _KYCDocumentDto;

  const KYCDocumentDto._();

  factory KYCDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$KYCDocumentDtoFromJson(json);

  KYCDocument toDomain() => KYCDocument(
    id: id,
    type: _docTypeFromCode(type),
    fileName: fileName,
    fileUrl: fileUrl,
    status: _docStatusFromCode(status),
    uploadedAt: uploadedAt,
  );

  static KYCDocumentType _docTypeFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'pan':
        return KYCDocumentType.pan;
      case 'citizenship':
        return KYCDocumentType.citizenship;
      case 'business_reg':
      case 'businessreg':
      case 'business_registration':
        return KYCDocumentType.businessReg;
      case 'tax_doc':
      case 'taxdoc':
      case 'tax_document':
        return KYCDocumentType.taxDoc;
      default:
        return KYCDocumentType.pan;
    }
  }

  static KYCDocumentStatus _docStatusFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'verified':
        return KYCDocumentStatus.verified;
      case 'rejected':
        return KYCDocumentStatus.rejected;
      case 'pending':
      default:
        return KYCDocumentStatus.pending;
    }
  }
}
