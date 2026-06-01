import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';

abstract interface class ReelsRepository {
  Future<Either<NetworkExceptions, List<Reel>>> getReelsFeed({
    int limit,
    String? cursor,
  });

  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId);

  Future<Either<NetworkExceptions, Unit>> likeReel(String reelId);

  Future<Either<NetworkExceptions, Unit>> unlikeReel(String reelId);

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
