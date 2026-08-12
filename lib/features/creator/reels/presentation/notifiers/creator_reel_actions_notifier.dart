import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/domain/repositories/creator_reels_repository.dart';

/// One-shot outcome of a reel mutation. The screen shows a spinner while
/// [CreatorReelActionInProgress] and a snackbar on success/failure, then
/// resets to [CreatorReelActionIdle] so a later rebuild does not replay it.
sealed class CreatorReelActionState {
  const CreatorReelActionState();
}

class CreatorReelActionIdle extends CreatorReelActionState {
  const CreatorReelActionIdle();
}

class CreatorReelActionInProgress extends CreatorReelActionState {
  const CreatorReelActionInProgress();
}

class CreatorReelActionSucceeded extends CreatorReelActionState {
  const CreatorReelActionSucceeded(this.message);
  final String message;
}

class CreatorReelActionFailed extends CreatorReelActionState {
  const CreatorReelActionFailed(this.message);
  final String message;
}

/// Write-side companion to the read-only reel providers: publish, unpublish
/// and product tagging for a single reel.
class CreatorReelActionsNotifier extends StateNotifier<CreatorReelActionState> {
  CreatorReelActionsNotifier(this._repository)
      : super(const CreatorReelActionIdle());

  final CreatorReelsRepository _repository;

  Future<bool> publish(String reelId) => _run(
        () => _repository.publishReel(reelId),
        'Reel published.',
      );

  Future<bool> unpublish(String reelId) => _run(
        () => _repository.unpublishReel(reelId),
        'Reel unpublished.',
      );

  Future<bool> tagProduct(
    String reelId, {
    required String productId,
    double overlayPositionX = 0.5,
    double overlayPositionY = 0.5,
  }) =>
      _run(
        () => _repository.tagProduct(
          reelId,
          productId: productId,
          overlayPositionX: overlayPositionX,
          overlayPositionY: overlayPositionY,
        ),
        'Product tagged.',
      );

  Future<bool> untagProduct(String reelId, String taggedProductId) => _run(
        () => _repository.untagProduct(reelId, taggedProductId),
        'Product removed.',
      );

  /// Returns whether the call succeeded so the caller can refresh the
  /// dependent read providers only on success.
  Future<bool> _run<T>(
    Future<NetworkEither<T>> Function() call,
    String successMessage,
  ) async {
    if (state is CreatorReelActionInProgress) return false;
    state = const CreatorReelActionInProgress();
    final result = await call();
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = CreatorReelActionFailed(NetworkExceptions.getMessage(failure));
        return false;
      },
      (_) {
        state = CreatorReelActionSucceeded(successMessage);
        return true;
      },
    );
  }

  /// Call after the screen has consumed a terminal state.
  void reset() {
    if (mounted) state = const CreatorReelActionIdle();
  }
}
