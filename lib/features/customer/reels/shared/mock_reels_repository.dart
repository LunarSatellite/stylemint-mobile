import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel_like_result.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/reels_mock_data.dart';

/// In-memory repository that returns [kMockReels].
/// A small artificial delay simulates network latency so loading states are
/// visible during development.
///
/// Replace [reelsRepositoryProvider] with [ReelsRepositoryImpl] for production.
class MockReelsRepository implements ReelsRepository {
  final List<Reel> _reels = List.of(kMockReels);

  @override
  Future<Either<NetworkExceptions, ReelsFeedPage>> getReelsFeed({
    int limit = 20,
    String? cursor,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return right(ReelsFeedPage(reels: _reels, nextCursor: null));
  }

  @override
  Future<Either<NetworkExceptions, Reel>> getReelDetail(String reelId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final reel = _reels.where((r) => r.id == reelId).firstOrNull;
    if (reel == null) return left(const NetworkExceptions.notFound());
    return right(reel);
  }

  @override
  Future<Either<NetworkExceptions, ReelLikeResult>> likeReel(
    String reelId,
  ) async {
    _toggle(reelId, (r) => r.copyWith(
      isLikedByMe: true,
      likeCount: r.likeCount + 1,
    ));
    return right(_likeResult(reelId, liked: true));
  }

  @override
  Future<Either<NetworkExceptions, ReelLikeResult>> unlikeReel(
    String reelId,
  ) async {
    _toggle(reelId, (r) => r.copyWith(
      isLikedByMe: false,
      likeCount: r.likeCount > 0 ? r.likeCount - 1 : 0,
    ));
    return right(_likeResult(reelId, liked: false));
  }

  ReelLikeResult _likeResult(String reelId, {required bool liked}) {
    final reel = _reels.where((r) => r.id == reelId).firstOrNull;
    return ReelLikeResult(liked: liked, likeCount: reel?.likeCount);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> addToWishlist(String reelId) async {
    _toggle(reelId, (r) => r.copyWith(isWishlistedByUser: true));
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> removeFromWishlist(
    String reelId,
  ) async {
    _toggle(reelId, (r) => r.copyWith(isWishlistedByUser: false));
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> followCreator(
    String creatorId,
  ) async {
    for (var i = 0; i < _reels.length; i++) {
      if (_reels[i].creatorId == creatorId) {
        _reels[i] = _reels[i].copyWith(isCreatorFollowed: true);
      }
    }
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> unfollowCreator(
    String creatorId,
  ) async {
    for (var i = 0; i < _reels.length; i++) {
      if (_reels[i].creatorId == creatorId) {
        _reels[i] = _reels[i].copyWith(isCreatorFollowed: false);
      }
    }
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> commentOnReel(
    String reelId,
    String commentText,
  ) async {
    _toggle(reelId, (r) => r.copyWith(commentCount: r.commentCount + 1));
    return right(unit);
  }

  @override
  Future<Either<NetworkExceptions, Unit>> shareReel(String reelId) async {
    _toggle(reelId, (r) => r.copyWith(shareCount: r.shareCount + 1));
    return right(unit);
  }

  void _toggle(String reelId, Reel Function(Reel) update) {
    final idx = _reels.indexWhere((r) => r.id == reelId);
    if (idx != -1) _reels[idx] = update(_reels[idx]);
  }
}
