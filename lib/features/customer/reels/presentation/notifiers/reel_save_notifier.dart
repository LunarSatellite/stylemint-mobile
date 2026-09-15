import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reel_save_api.dart';

/// A reel's StyleMint save as the rail shows it.
@immutable
class ReelSaveState {
  const ReelSaveState({required this.saved, required this.count});

  final bool saved;

  /// Accounts that saved the reel.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is ReelSaveState && other.saved == saved && other.count == count;

  @override
  int get hashCode => Object.hash(saved, count);

  @override
  String toString() => 'ReelSaveState(saved: $saved, count: $count)';
}

/// StyleMint saves (bookmarks) on reels, keyed by reel id, for the reel rail.
///
/// A save lives on StyleMint (`POST`/`DELETE /v1/customer/reels/{id}/save`)
/// and lists the reel under the viewer's saved reels. Toggles are
/// optimistic: the bookmark and count change at once, then take the server's
/// answer, or roll back if the request fails.
class ReelSaveNotifier extends StateNotifier<Map<String, ReelSaveState>> {
  ReelSaveNotifier(this._api) : super(const <String, ReelSaveState>{});

  /// Read lazily, so building the rail never builds the HTTP client.
  final ReelSaveApi Function() _api;

  /// Reels saved or unsaved this session; a snapshot can't overwrite them.
  final Set<String> _touched = <String>{};
  final Set<String> _inFlight = <String>{};

  /// Seeds a reel from a server snapshot (`isSavedByMe`, `saveCount`).
  /// Ignored once the viewer has toggled that reel.
  void seed(String reelId, {required bool saved, required int count}) {
    if (reelId.isEmpty || _touched.contains(reelId)) return;
    final next = ReelSaveState(saved: saved, count: count < 0 ? 0 : count);
    if (state[reelId] == next) return;
    state = {...state, reelId: next};
  }

  /// Saves or unsaves [reelId]; [fallback] is the reel's snapshot when it was
  /// never seeded.
  ///
  /// Returns false after a rollback. A tap while the previous request for the
  /// same reel is still running is ignored and returns true.
  Future<bool> toggle(String reelId, {required ReelSaveState fallback}) async {
    if (reelId.isEmpty || _inFlight.contains(reelId)) return true;
    _touched.add(reelId);
    final before = state[reelId] ?? fallback;
    final optimistic = before.saved
        ? ReelSaveState(
            saved: false,
            count: before.count > 0 ? before.count - 1 : 0,
          )
        : ReelSaveState(saved: true, count: before.count + 1);

    _inFlight.add(reelId);
    state = {...state, reelId: optimistic};
    try {
      final api = _api();
      final result = before.saved
          ? await api.unsave(reelId)
          : await api.save(reelId);
      if (mounted) {
        state = {
          ...state,
          reelId: ReelSaveState(
            saved: result.saved,
            count: result.saveCount ?? optimistic.count,
          ),
        };
      }
      return true;
    } on Object catch (_) {
      if (mounted) state = {...state, reelId: before};
      return false;
    } finally {
      _inFlight.remove(reelId);
    }
  }
}
