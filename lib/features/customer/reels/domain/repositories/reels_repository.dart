import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/error/failure.dart';
import '../entities/reel.dart';

/// Abstract repository interface for reels operations
/// Implemented by data layer
abstract class ReelsRepository {
  /// Fetches the reels feed
  /// Returns Either<Failure, List<Reel>>
  Future<Either<Failure, List<Reel>>> getReelsFeed({
    required int limit,
    String? cursor,
  });

  /// Gets detailed info for a single reel
  Future<Either<Failure, Reel>> getReelDetail(String reelId);

  /// Likes a reel
  Future<Either<Failure, bool>> likeReel(String reelId);

  /// Unlikes a reel
  Future<Either<Failure, bool>> unlikeReel(String reelId);

  /// Adds reel to wishlist
  Future<Either<Failure, bool>> addToWishlist(String reelId);

  /// Removes reel from wishlist
  Future<Either<Failure, bool>> removeFromWishlist(String reelId);

  /// Follows a creator
  Future<Either<Failure, bool>> followCreator(String creatorId);

  /// Unfollows a creator
  Future<Either<Failure, bool>> unfollowCreator(String creatorId);

  /// Comments on a reel
  Future<Either<Failure, bool>> commentOnReel(
    String reelId,
    String commentText,
  );

  /// Shares a reel
  Future<Either<Failure, bool>> shareReel(String reelId);
}
