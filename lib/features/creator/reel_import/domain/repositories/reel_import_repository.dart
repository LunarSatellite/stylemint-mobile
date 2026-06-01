import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

abstract interface class ReelImportRepository {
  Future<Either<NetworkExceptions, List<ImportableReel>>> getImportableReels(
    SocialPlatform platform,
  );

  Future<Either<NetworkExceptions, ImportedReel>> importReel(
    String platformPostId,
    String caption,
    List<String> taggedProductIds,
  );

  Future<Either<NetworkExceptions, List<TaggedProductForImport>>> searchProducts(
    String query,
  );

  Future<Either<NetworkExceptions, List<ImportedReel>>> getImportHistory({
    int limit,
    String? cursor,
  });
}
