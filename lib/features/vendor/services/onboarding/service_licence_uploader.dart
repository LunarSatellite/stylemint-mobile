import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stylemint_mobile_frontend/core/network/json_read.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/vendor/apply/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_failure.dart';

/// An uploaded licence certificate: what to attach to the application, and
/// what to show the vendor.
typedef UploadedLicence = ({String reference, String fileName});

/// Picks and uploads the operating licence certificate (NRB licence for a
/// bank, tourism licence for a hotel or travel agency) through the same KYC
/// blob upload the other business documents use. The returned
/// `blobReference` is attached to the application as document kind 5
/// OperatingLicence (service-banks contract v1).
abstract class ServiceLicenceUploader {
  /// A photo of the certificate from the gallery; null when cancelled.
  Future<String?> pick();

  Future<Either<ServiceFailure, UploadedLicence>> upload(String filePath);
}

class ImageServiceLicenceUploader implements ServiceLicenceUploader {
  ImageServiceLicenceUploader(this._ref);

  final Ref _ref;

  @override
  Future<String?> pick() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return picked?.path;
  }

  @override
  Future<Either<ServiceFailure, UploadedLicence>> upload(String filePath) =>
      guardedServiceCall(() async {
        var accountId = _ref
            .read(sessionControllerProvider)
            .maybeWhen(authenticated: (id) => id, orElse: () => null);
        accountId ??= await _ref.read(tokenStorageProvider).accountId;
        if (accountId == null || accountId.isEmpty) {
          throw const ServiceFailure(ServiceFailureKind.auth);
        }
        final blob = await _ref
            .read(vendorApplyRemoteDataSourceProvider)
            .uploadKycBlob(accountId, filePath);
        final reference = readOptionalString(blob['blobReference']);
        if (reference == null) {
          throw const ServiceFailure(ServiceFailureKind.unknown);
        }
        return (
          reference: reference,
          fileName:
              readOptionalString(blob['originalFilename']) ??
              filePath.split(RegExp(r'[\\/]')).last,
        );
      });
}

final Provider<ServiceLicenceUploader> serviceLicenceUploaderProvider =
    Provider<ServiceLicenceUploader>(ImageServiceLicenceUploader.new);
