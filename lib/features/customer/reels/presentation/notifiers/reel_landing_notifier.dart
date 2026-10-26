import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/ai_rails/domain/repositories/ai_rails_repository.dart';
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

enum _Source { alsoWatched, similar, related, feed, done }

/// A shared reel and the reels to keep scrolling into after it.
///
/// Shows the landed reel as soon as it is fetched, then the reel page's two
/// AI rails — "People also watched" (AI features contract v1.0 §3) and
/// "Similar reels" by meaning (§4.3), each reel labelled with its rail — then
/// its related reels (the creator's other reels, then reels sharing a tagged
/// product, then the latest reels) and, once those run out, the general feed.
/// A reel already shown is skipped.
///
/// The AI rails are one page each and optional: an empty answer, a 404 (not
/// deployed) or no [rails] at all moves straight on, so a server without
/// them pages exactly as before. A failed related or feed page stops the
/// paging quietly: what is loaded, the landed reel included, stays and keeps
/// playing.
class ReelLandingNotifier extends StateNotifier<ReelLandingState> {
  ReelLandingNotifier(this._repository, {required this.reelId, this.rails})
    : super(const ReelLandingLoading()) {
    unawaited(load());
  }

  final ReelsRepository _repository;
  final String reelId;
  final AiRailsRepository? rails;

  static const int aiRailSize = 10;
  static const String alsoWatchedLabel = 'People also watched';
  static const String similarLabel = 'Similar reels';

  static const int relatedPageSize = 10;
  static const int feedPageSize = 20;

  /// Pages fetched back to back while each brings only reels already shown,
  /// before waiting for the viewer to near the end again.
  static const int maxPagesPerFetch = 3;

  final Set<String> _shown = {};
  late _Source _source = _firstSource;

  _Source get _firstSource =>
      rails == null ? _Source.related : _Source.alsoWatched;
  String? _cursor;
  bool _loadingMore = false;

  /// Bumped by [load], so pages still in flight from before are dropped.
  int _generation = 0;

  Future<void> load() async {
    final generation = ++_generation;
    state = const ReelLandingLoading();
    _shown.clear();
    _source = _firstSource;
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
        if (_source == _Source.alsoWatched || _source == _Source.similar) {
          final added = await _appendAiRail(generation);
          if (added == null || added > 0) return;
          // An empty AI rail is not a page: the related reels still get
          // their full number of tries.
          page--;
          continue;
        }
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

  /// Appends one AI rail and moves on to the next source. Returns how many
  /// reels it added, or null when this load was superseded or disposed.
  Future<int?> _appendAiRail(int generation) async {
    final repository = rails;
    final source = _source;
    _source = source == _Source.alsoWatched ? _Source.similar : _Source.related;
    if (repository == null) return 0;
    final List<Reel> reels;
    final String label;
    if (source == _Source.alsoWatched) {
      final rail = await repository.alsoWatched(reelId, limit: aiRailSize);
      reels = rail.items;
      label = alsoWatchedLabel;
    } else {
      final matches = await repository.similarReels(
        reelId,
        limit: aiRailSize,
      );
      reels = [for (final match in matches.byMeaning) match.reel];
      label = similarLabel;
    }
    if (!mounted || generation != _generation) return null;
    final current = state;
    if (current is! ReelLandingReady) return null;
    final fresh = <Reel>[
      for (final reel in reels)
        if (reel.id.isNotEmpty && _shown.add(reel.id))
          reel.copyWith(railLabel: label),
    ];
    if (fresh.isNotEmpty) {
      state = ReelLandingReady([...current.reels, ...fresh]);
    }
    return fresh.length;
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
