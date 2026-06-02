import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';

/// Tracks which account ids the current user follows, for follow-button UI.
/// Toggles are optimistic — the set updates immediately and rolls back if the
/// API call fails. Both follow and unfollow are idempotent server-side.
class FollowNotifier extends StateNotifier<Set<String>> {
  FollowNotifier(this._api) : super(const <String>{});

  final FollowApi _api;

  bool isFollowing(String accountId) => state.contains(accountId);

  /// Seed initial follow state (e.g. from a profile's `isFollowedByViewer`).
  void seed(String accountId, {required bool following}) {
    state = following ? {...state, accountId} : {...state}..remove(accountId);
  }

  /// Optimistically toggles follow state; rolls back on failure.
  /// Returns true if the resulting state is "following".
  Future<bool> toggle(String accountId) async {
    final wasFollowing = state.contains(accountId);
    // Optimistic update.
    state = wasFollowing
        ? ({...state}..remove(accountId))
        : {...state, accountId};
    try {
      if (wasFollowing) {
        await _api.unfollow(accountId);
      } else {
        await _api.follow(accountId);
      }
      return !wasFollowing;
    } catch (_) {
      // Roll back.
      state = wasFollowing
          ? {...state, accountId}
          : ({...state}..remove(accountId));
      rethrow;
    }
  }
}

final followNotifierProvider =
    StateNotifierProvider<FollowNotifier, Set<String>>((ref) {
  return FollowNotifier(ref.watch(followApiProvider));
});
