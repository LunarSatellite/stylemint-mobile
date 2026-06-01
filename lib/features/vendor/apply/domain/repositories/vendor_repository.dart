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
    KYCDocumentType documentType,
  );
  Future<Either<NetworkExceptions, List<KYCDocument>>> getKYCDocuments();
}
