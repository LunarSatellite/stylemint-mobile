import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_detail.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/creator_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/entities/reel_product_tag.dart';

abstract class CreatorReelsRepository {
  Future<NetworkEither<CreatorReelDetail>> getReelDetail(String reelId);

  Future<NetworkEither<List<CreatorReelSummary>>> listCreatorReels({
    String sortBy = 'publishedAt',
    String order = 'desc',
    int limit = 6,
  });

  /// Makes the reel publicly visible and shoppable.
  Future<NetworkEither<Unit>> publishReel(String reelId);

  /// Hides the reel from the public feed. Existing tags and their commission
  /// snapshots are retained so republishing does not re-price them.
  Future<NetworkEither<Unit>> unpublishReel(String reelId);

  Future<NetworkEither<List<ReelProductTag>>> listTaggedProducts(String reelId);

  /// Overlay coordinates are fractions of the video frame (0.0–1.0).
  Future<NetworkEither<ReelProductTag>> tagProduct(
    String reelId, {
    required String productId,
    required double overlayPositionX,
    required double overlayPositionY,
  });

  /// [taggedProductId] is the tag's own id — see [ReelProductTag.id].
  Future<NetworkEither<Unit>> untagProduct(
    String reelId,
    String taggedProductId,
  );
}
