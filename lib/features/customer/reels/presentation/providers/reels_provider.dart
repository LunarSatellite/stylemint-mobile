import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/usecases/get_reels_feed.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'reels_providers.dart';

part 'reels_provider.g.dart';

/// Provides the reels feed - fetches and manages list of reels
/// Calls GetReelsFeedUseCase to fetch data from backend
@riverpod
Future<List<Reel>> reelsFeed(ReelsFeedRef ref) async {
  final getReelsFeedUseCase = ref.watch(getReelsFeedUseCaseProvider);

  final result = await getReelsFeedUseCase.call(
    const GetReelsFeedParams(limit: 20),
  );

  return result.fold(
    (failure) => throw failure,
    (reels) => reels,
  );
}

/// Provider for individual reel detail
@riverpod
Future<Reel?> reelDetail(ReelDetailRef ref, String reelId) async {
  final reels = await ref.watch(reelsFeedProvider.future);
  try {
    return reels.firstWhere((reel) => reel.id == reelId);
  } catch (e) {
    return null;
  }
}

/// Provider for managing user interactions with reels
@riverpod
class ReelInteractions extends _$ReelInteractions {
  @override
  Future<Map<String, dynamic>> build() async {
    return {};
  }

  Future<void> likeReel(String reelId) async {
    // TODO: Call LikeReelUseCase
    state = AsyncData({
      ...?state.value,
      'liked_$reelId': true,
    });
  }

  Future<void> unlikeReel(String reelId) async {
    // TODO: Call UnlikeReelUseCase
    state = AsyncData({
      ...?state.value,
      'liked_$reelId': false,
    });
  }

  Future<void> addToWishlist(String reelId) async {
    // TODO: Call AddToWishlistUseCase
    state = AsyncData({
      ...?state.value,
      'wishlisted_$reelId': true,
    });
  }

  Future<void> followCreator(String creatorId) async {
    // TODO: Call FollowCreatorUseCase
    state = AsyncData({
      ...?state.value,
      'following_$creatorId': true,
    });
  }
}
