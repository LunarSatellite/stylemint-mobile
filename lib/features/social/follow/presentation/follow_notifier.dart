import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/social/follow/data/follow_api.dart';

/// Tracks which account ids the current user follows, for follow-button UI.
/// Toggles are optimistic — the set updates immediately and rolls back if the
/// API call fails. Both follow and unfollow are idempotent server-side.
class FollowNotifier extends StateNotifier<Set<String>> {
  FollowNotifier(this._api) : super(const <String>{});

  final FollowApi _api;

  // Creator ids whose initial state has already been seeded this session — so
  // re-seeding (e.g. a recycled reel re-running initState) can't clobber a live
  // user toggle.
  final Set<String> _seeded = <String>{};

  bool isFollowing(String accountId) => state.contains(accountId);

  /// Seed initial follow state from a server flag (e.g. a reel's
  /// `isCreatorFollowed` or a profile's `isFollowedByViewer`). No-ops if this
  /// account was already seeded or the user has already toggled it this session
  /// — the server flag only establishes the FIRST-seen truth; live toggles win.
  void seed(String accountId, {required bool following}) {
    if (accountId.isEmpty || _seeded.contains(accountId)) return;
    _seeded.add(accountId);
    if (following) state = {...state, accountId};
  }

  /// Optimistically toggles follow state; rolls back on failure.
  /// Returns true if the resulting state is "following".
  Future<bool> toggle(String accountId) async {
    _seeded.add(accountId); // a user action is authoritative — block later seeds
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
