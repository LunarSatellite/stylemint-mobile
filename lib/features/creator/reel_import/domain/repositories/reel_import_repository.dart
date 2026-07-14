import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

abstract interface class ReelImportRepository {
  Future<Either<NetworkExceptions, List<ImportableReel>>> getImportableReels(
    SocialPlatform platform,
  );

  Future<Either<NetworkExceptions, ImportedReel>> importReel(
    ImportableReel reel,
  );

  Future<Either<NetworkExceptions, List<TaggedProductForImport>>>
      searchProducts(
    String query,
  );

  Future<Either<NetworkExceptions, Unit>> publishReel({
    required String reelId,
  });

  Future<Either<NetworkExceptions, Unit>> tagProduct({
    required String reelId,
    required String productId,
  });

  Future<Either<NetworkExceptions, List<ImportedReel>>> getImportHistory({
    int pageSize,
    String? cursor,
  });
}
