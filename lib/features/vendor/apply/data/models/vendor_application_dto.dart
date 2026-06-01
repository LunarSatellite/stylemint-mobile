import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';

part 'vendor_application_dto.freezed.dart';
part 'vendor_application_dto.g.dart';

@freezed
abstract class VendorApplicationDto with _$VendorApplicationDto {
  const factory VendorApplicationDto({
    required String id,
    required String status,
    String? rejectionReason,
    required DateTime submittedAt,
    required DateTime updatedAt,
  }) = _VendorApplicationDto;

  const VendorApplicationDto._();

  factory VendorApplicationDto.fromJson(Map<String, dynamic> json) =>
      _$VendorApplicationDtoFromJson(json);

  VendorApplication toDomain() => VendorApplication(
    id: id,
    status: _statusFromCode(status),
    rejectionReason: rejectionReason,
    submittedAt: submittedAt,
    updatedAt: updatedAt,
  );

  static VendorApplicationStatus _statusFromCode(String code) {
    switch (code.toLowerCase()) {
      case 'pending':
        return VendorApplicationStatus.pending;
      case 'under_review':
      case 'review':
        return VendorApplicationStatus.underReview;
      case 'approved':
        return VendorApplicationStatus.approved;
      case 'rejected':
        return VendorApplicationStatus.rejected;
      case 'kyc_required':
      case 'kycrequired':
        return VendorApplicationStatus.kycRequired;
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
