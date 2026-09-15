import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

/// A reel's StyleMint like as the rail shows it.
@immutable
class ReelLikeState {
  const ReelLikeState({required this.liked, required this.count});

  final bool liked;

  /// Platform likes plus StyleMint likes.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is ReelLikeState && other.liked == liked && other.count == count;

  @override
  int get hashCode => Object.hash(liked, count);

  @override
  String toString() => 'ReelLikeState(liked: $liked, count: $count)';
}

/// StyleMint likes on reels, keyed by reel id, for the reel rail.
///
/// A like lives on StyleMint (`POST`/`DELETE /v1/customer/reels/{id}/like`),
/// never on the reel's source platform. Toggles are optimistic: the heart and
/// count change at once, then take the server's answer, or roll back if the
/// request fails.
class ReelLikeNotifier extends StateNotifier<Map<String, ReelLikeState>> {
  ReelLikeNotifier(this._repository) : super(const <String, ReelLikeState>{});

  final ReelsRepository _repository;

  /// Reels the viewer liked or unliked this session. A server snapshot can
  /// no longer overwrite them.
  final Set<String> _touched = <String>{};

  final Set<String> _inFlight = <String>{};

  /// Seeds a reel from a server snapshot (the feed card's `isLikedByMe` and
  /// `likeCount`). Ignored once the viewer has toggled that reel.
  void seed(String reelId, {required bool liked, required int count}) {
    if (reelId.isEmpty || _touched.contains(reelId)) return;
    final next = ReelLikeState(liked: liked, count: count < 0 ? 0 : count);
    if (state[reelId] == next) return;
    state = {...state, reelId: next};
  }

  /// Likes or unlikes [reelId]. [fallback] is the reel's snapshot, used when
  /// it was never seeded.
  ///
  /// Returns null on success, or the failure after the state was rolled back.
  /// A tap while the previous request for the same reel is still running is
  /// ignored.
  Future<NetworkExceptions?> toggle(
    String reelId, {
    required ReelLikeState fallback,
  }) async {
    if (reelId.isEmpty || _inFlight.contains(reelId)) return null;
    _touched.add(reelId);
    final before = state[reelId] ?? fallback;
    final optimistic = before.liked
        ? ReelLikeState(
            liked: false,
            count: before.count > 0 ? before.count - 1 : 0,
          )
        : ReelLikeState(liked: true, count: before.count + 1);

    _inFlight.add(reelId);
    state = {...state, reelId: optimistic};
    final result = before.liked
        ? await _repository.unlikeReel(reelId)
        : await _repository.likeReel(reelId);
    _inFlight.remove(reelId);
    if (!mounted) return null;

    return result.fold(
      (failure) {
        state = {...state, reelId: before};
        return failure;
      },
      (server) {
        state = {
          ...state,
          reelId: ReelLikeState(
            liked: server.liked,
            count: server.likeCount ?? optimistic.count,
          ),
        };
        return null;
      },
    );
  }
}
