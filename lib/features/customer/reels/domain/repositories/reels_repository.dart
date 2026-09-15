import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_like_result.dart';

abstract interface class ReelsRepository {
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId);

  /// Reels to keep watching after [reelId]: the creator's other reels, then
  /// reels sharing a tagged product, then the latest reels. Never [reelId].
  Future<Either<NetworkExceptions, ReelsFeedPage>> getRelatedReels(
    String reelId, {
    int limit,
    String? cursor,
  });

  /// Likes the reel on StyleMint (not on its source platform).
  Future<Either<NetworkExceptions, ReelLikeResult>> likeReel(String reelId);

  /// Removes the viewer's StyleMint like.
  Future<Either<NetworkExceptions, ReelLikeResult>> unlikeReel(String reelId);

  Future<Either<NetworkExceptions, Unit>> addToWishlist(String reelId);

  Future<Either<NetworkExceptions, Unit>> removeFromWishlist(String reelId);

  Future<Either<NetworkExceptions, Unit>> followCreator(String creatorId);

  Future<Either<NetworkExceptions, Unit>> unfollowCreator(String creatorId);

  Future<Either<NetworkExceptions, Unit>> commentOnReel(
    String reelId,
    String commentText,
  );

  Future<Either<NetworkExceptions, Unit>> shareReel(String reelId);
}
