import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/domain/entities/vendor_application.dart';

abstract class VendorRepository {
  Future<Either<NetworkExceptions, VendorApplication>> getApplicationStatus();
  Future<Either<NetworkExceptions, VendorApplication>> submitApplication(
    VendorApplicationForm form,
  );
  Future<Either<NetworkExceptions, KYCDocument>> uploadKYCDocument(
    String filePath,
    KYCDocumentType documentType, {
    required String accountId,
  });
  Future<Either<NetworkExceptions, List<KYCDocument>>> getKYCDocuments({
    required String accountId,
    required String sessionId,
  });

  /// The account's current KYC session id, or `null` if none exists yet
  /// (no documents have ever been uploaded).
  Future<Either<NetworkExceptions, String?>> getActiveKycSessionId({
    required String accountId,
  });
}
