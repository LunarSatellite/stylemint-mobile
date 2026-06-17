import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/apply/domain/entities/creator_application.dart';

abstract class CreatorRepository {
  /// Active creator content categories for the apply form
  /// (`GET /v1/public/creator-categories`), ordered for display.
  Future<Either<NetworkExceptions, List<CreatorContentCategory>>>
      getContentCategories();

  /// Instant creator onboarding (`POST /v1/creator/activate`). Both fields
  /// optional. On success the account holds the Creator role server-side — the
  /// caller must refresh its token before hitting `/v1/creator/*`.
  Future<Either<NetworkExceptions, Unit>> activate({
    String? bio,
    String? expression,
  });

  Future<Either<NetworkExceptions, CreatorApplication>> getApplicationStatus();
  Future<Either<NetworkExceptions, CreatorApplication>> submitApplication(
    CreatorApplicationForm form,
  );
  Future<Either<NetworkExceptions, String>> uploadIdentityDoc(String filePath);
}
