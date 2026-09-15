import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

/// What `/reels/:reelId` shows.
sealed class ReelLandingState {
  const ReelLandingState();
}

/// The reel the link points at is being fetched.
final class ReelLandingLoading extends ReelLandingState {
  const ReelLandingLoading();
}

/// The reel the link points at could not be fetched.
final class ReelLandingFailure extends ReelLandingState {
  const ReelLandingFailure(this.failure);

  final NetworkExceptions failure;
}

/// The landed reel first, then the reels paged in after it. No reel twice.
final class ReelLandingReady extends ReelLandingState {
  const ReelLandingReady(this.reels);

  final List<Reel> reels;
}

enum _Source { related, feed, done }

/// A shared reel and the reels to keep scrolling into after it.
///
/// Shows the landed reel as soon as it is fetched, then pages in its related
/// reels (the creator's other reels, then reels sharing a tagged product, then
/// the latest reels) and, once those run out, the general feed. A reel already
/// shown is skipped. A failed page stops the paging quietly: what is loaded,
/// the landed reel included, stays and keeps playing.
class ReelLandingNotifier extends StateNotifier<ReelLandingState> {
  ReelLandingNotifier(this._repository, {required this.reelId})
    : super(const ReelLandingLoading()) {
    unawaited(load());
  }

  final ReelsRepository _repository;
  final String reelId;

  static const int relatedPageSize = 10;
  static const int feedPageSize = 20;

  /// Pages fetched back to back while each brings only reels already shown,
  /// before waiting for the viewer to near the end again.
  static const int maxPagesPerFetch = 3;

  final Set<String> _shown = {};
  _Source _source = _Source.related;
  String? _cursor;
  bool _loadingMore = false;

  /// Bumped by [load], so pages still in flight from before are dropped.
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    state = const ReelLandingLoading();
    _shown.clear();
    _source = _Source.related;
    _cursor = null;
    _loadingMore = false;

    final either = await _repository.getReelDetail(reelId);
    if (!mounted || generation != _generation) return;
    either.fold((failure) => state = ReelLandingFailure(failure), (reel) {
      _shown.add(reel.id);
      state = ReelLandingReady([reel]);
      unawaited(fetchNextPage());
    });
  }

  /// Appends the next reels. Called once the landed reel is shown and again
  /// whenever the viewer nears the end of what is loaded.
  Future<void> fetchNextPage() async {
    if (_loadingMore || _source == _Source.done || state is! ReelLandingReady) {
      return;
    }
    final generation = _generation;
    _loadingMore = true;
    try {
      for (var page = 0; page < maxPagesPerFetch; page++) {
        if (_source == _Source.done) return;
        final either = _source == _Source.related
            ? await _repository.getRelatedReels(
                reelId,
                limit: relatedPageSize,
                cursor: _cursor,
              )
            : await _repository.getReelsFeed(
                limit: feedPageSize,
                cursor: _cursor,
              );
        if (!mounted || generation != _generation) return;
        final current = state;
        if (current is! ReelLandingReady) return;

        final added = either.fold(
          (_) {
            _source = _Source.done;
            return 0;
          },
          (result) {
            _advance(result.nextCursor);
            final fresh = <Reel>[];
            for (final reel in result.reels) {
              if (reel.id.isNotEmpty && _shown.add(reel.id)) fresh.add(reel);
            }
            if (fresh.isNotEmpty) {
              state = ReelLandingReady([...current.reels, ...fresh]);
            }
            return fresh.length;
          },
        );
        if (added > 0) return;
      }
    } finally {
      if (generation == _generation) _loadingMore = false;
    }
  }

  /// Follows [nextCursor]; at the end of the related reels moves on to the
  /// general feed, and at the end of the feed stops.
  void _advance(String? nextCursor) {
    if (nextCursor != null) {
      _cursor = nextCursor;
    } else if (_source == _Source.related) {
      _source = _Source.feed;
      _cursor = null;
    } else {
      _source = _Source.done;
    }
  }
}
