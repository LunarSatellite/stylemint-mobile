import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/content_freshness.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_import/domain/entities/imported_reel.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

/// One page of importable reels plus the opaque cursor to fetch the next page
/// (null once there are no more pages) and where the page came from.
class ImportableReelsResult {
  const ImportableReelsResult({
    required this.reels,
    required this.nextCursor,
    this.freshness = const ContentFreshness(),
  });

  final List<ImportableReel> reels;

  /// A provider cursor continues a live listing; a cursor starting `sm1.`
  /// continues through saved posts. Either way it is opaque to the client.
  final String? nextCursor;
  final ContentFreshness freshness;
}

abstract interface class ReelImportRepository {
  /// [cursor] is the opaque cursor from a previous page's
  /// [ImportableReelsResult.nextCursor] — omit for the first page.
  /// [refresh] asks the backend for a live read instead of saved posts.
  ///
  /// Provider problems come back as `NetworkExceptions.validation(code:)`
  /// carrying the backend `errorCode` (see [ContentProviderIssue.fromCode]);
  /// a missing connection is `NetworkExceptions.notFound()`.
  Future<Either<NetworkExceptions, ImportableReelsResult>> getImportableReels(
    SocialPlatform platform, {
    String? cursor,
    bool refresh = false,
  });

  /// [caption] is the caption to store on StyleMint — the Review screen
  /// passes the one composed with the Reel Caption Standard. Falls back to
  /// the platform's [ImportableReel.caption] when null.
  Future<Either<NetworkExceptions, ImportedReel>> importReel(
    ImportableReel reel, {
    String? caption,
  });

  Future<Either<NetworkExceptions, List<TaggedProductForImport>>>
  searchProducts(
    String query,
  );

  /// Suggested products for an importable reel. Returned by the backend
  /// before the reel is imported (so the reel has no backend id yet) and
  /// kept in its own dedicated state on the client so the search sheet
  /// can never leak into this list.
  Future<Either<NetworkExceptions, List<TaggedProductForImport>>>
  getSuggestedProducts({
    required SocialPlatform platform,
    required String externalId,
  });

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

  Future<Either<NetworkExceptions, BulkImportResult>> importBulk(
    List<ImportableReel> reels,
  );

  Future<Either<NetworkExceptions, ReelIntent>> launchReelIntent(
    SocialPlatform platform,
  );

  Future<Either<NetworkExceptions, ReelIntent>> completeReelIntent({
    required String intentId,
    required String resultingReelId,
  });
}
