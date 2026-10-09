import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/features/customer/kyc/domain/entities/customer_kyc.dart';

/// `CustomerKycDocumentDto`, or null when its `kind` is not one this build
/// knows — an unknown page cannot be placed on the form.
CustomerKycDocument? readCustomerKycDocument(Map<String, dynamic> json) {
  final kind = KycDocumentKind.fromWire(json['kind']);
  if (kind == null) return null;
  return CustomerKycDocument(
    id: readString(json['id']),
    kind: kind,
    uploadedUtc: readDate(json['uploadedUtc']),
    thumbnailUrl: readOptionalString(json['thumbnailUrl']),
  );
}

/// `CustomerKycDto`.
CustomerKyc readCustomerKyc(Map<String, dynamic> json) {
  final documents = <CustomerKycDocument>[
    for (final raw
        in json['documents'] is List
            ? json['documents'] as List
            : const <dynamic>[])
      if (raw is Map<String, dynamic>) ?readCustomerKycDocument(raw),
  ];
  final missing = <KycDocumentKind>[
    for (final raw
        in json['missingDocuments'] is List
            ? json['missingDocuments'] as List
            : const <dynamic>[])
      ?KycDocumentKind.fromWire(raw),
  ];
  return CustomerKyc(
    tier: readInt(json['tier']),
    status: KycStatus.fromWire(json['status']),
    sessionId: readOptionalString(json['sessionId']),
    documentType: KycDocumentType.fromWire(json['documentType']),
    documents: List.unmodifiable(documents),
    missingDocuments: List.unmodifiable(missing),
    rejectionReason: readOptionalString(json['rejectionReason']),
    canResubmit: readBool(json['canResubmit']),
    submittedUtc: readDate(json['submittedUtc']),
    reviewedUtc: readDate(json['reviewedUtc']),
    expiresUtc: readDate(json['expiresUtc']),
  );
}
