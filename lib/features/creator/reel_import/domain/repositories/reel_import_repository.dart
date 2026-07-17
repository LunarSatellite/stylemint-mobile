import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// One provider-native page of importable reels plus the opaque cursor to
/// fetch the next page (null once the provider has no more pages).
class ImportableReelsResult {
  const ImportableReelsResult({required this.reels, required this.nextCursor});

  final List<ImportableReel> reels;
  final String? nextCursor;
}

abstract interface class ReelImportRepository {
  /// [cursor] is the provider-native opaque cursor from a previous page's
  /// [ImportableReelsResult.nextCursor] — omit for the first page.
  Future<Either<NetworkExceptions, ImportableReelsResult>> getImportableReels(
    SocialPlatform platform, {
    String? cursor,
  });

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
