import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';

part 'reels_feed_notifier.freezed.dart';

@freezed
abstract class ReelsFeedState with _$ReelsFeedState {
  const ReelsFeedState._();

  const factory ReelsFeedState.initial() = _Initial;
  const factory ReelsFeedState.loadInProgress() = _LoadInProgress;
  const factory ReelsFeedState.loadSuccess(List<Reel> reels) = _LoadSuccess;
  const factory ReelsFeedState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class ReelsFeedNotifier extends StateNotifier<ReelsFeedState> {
  ReelsFeedNotifier(this._repository) : super(const ReelsFeedState.initial()) {
    unawaited(fetchFeed());
  }

  final ReelsRepository _repository;

  static const int _pageSize = 20;

  String? _nextCursor;
  bool _loadingMore = false;

  void reset() => state = const ReelsFeedState.initial();

  Future<void> fetchFeed({int limit = _pageSize}) async {
    state = const ReelsFeedState.loadInProgress();
    _nextCursor = null;
    final either = await _repository.getReelsFeed(limit: limit);
    state = either.fold(ReelsFeedState.loadFailure, (page) {
      _nextCursor = page.nextCursor;
      return ReelsFeedState.loadSuccess(page.reels);
    });
  }

  /// Re-reads the first page and swaps the whole list, WITHOUT passing through
  /// [ReelsFeedState.loadInProgress].
  ///
  /// That distinction is the point. [fetchFeed] emits loadInProgress, which
  /// replaces the pager with a full-screen loader — fine for a cold start,
  /// wrong for a pull-to-refresh: it tears the PageView down in the middle of
  /// the gesture that asked for it, so the spinner the pager was drawing goes
  /// with it and the screen flashes. Here the existing reels stay on screen
  /// until new ones arrive.
  ///
  /// The cursor is reset, so paging continues from the new first page rather
  /// than appending onto a list that no longer exists.
  ///
  /// A failed refresh keeps the current feed. Someone who pulled to refresh
  /// still has reels to watch, and replacing them with an error over a working
  /// screen is a worse answer than leaving them be.
  Future<void> refreshFeedInPlace({int limit = _pageSize}) async {
    final either = await _repository.getReelsFeed(limit: limit);
    either.fold((_) {}, (page) {
      _nextCursor = page.nextCursor;
      state = ReelsFeedState.loadSuccess(page.reels);
    });
  }

  /// Re-reads one reel and swaps it into the loaded feed in place.
  ///
  /// This provider is NOT autoDispose — it is an app-lifetime singleton, so
  /// once the feed is loaded its `List<Reel>` stays in memory for the whole
  /// session. A creator who tagged a product therefore kept seeing the
  /// pre-tag copy until the app was killed and relaunched, which rebuilt the
  /// notifier and re-fetched. Nothing in the tagging flow told the feed that
  /// one of its reels had changed.
  ///
  /// One reel, not the whole feed, and deliberately: the feed is a vertical
  /// pager, so calling [fetchFeed] would drop the viewer back to the top and
  /// lose their place to update a single card. Here the list keeps its length
  /// and order and only the changed element is replaced.
  ///
  /// Only the tagged products are taken from the re-read, NOT the whole reel.
  /// `/v1/public/reels/{id}` is `[AllowAnonymous]` and resolves no viewer, so
  /// its `isLikedByMe`, `isCreatorFollowed` and `isSavedByMe` come back false
  /// for everyone. Swapping the fresh copy in wholesale would therefore
  /// un-like the reel and un-follow its creator on screen the moment a product
  /// was tagged — a worse bug than the staleness being fixed. Everything the
  /// feed already knows is kept.
  ///
  /// Best-effort. A failed re-read leaves the existing copy alone: a slightly
  /// stale tag beats an error over a card the user is looking at, and the next
  /// full fetch picks it up anyway.
  Future<void> refreshReel(String reelId) async {
    if (reelId.isEmpty) return;
    final current = state;
    if (current is! _LoadSuccess) return;
    if (!current.reels.any((reel) => reel.id == reelId)) {
      return; // Not loaded here; nothing to correct.
    }

    final either = await _repository.getReelDetail(reelId);
    either.fold((_) {}, (fresh) {
      // Re-resolve against the CURRENT state rather than an index captured
      // before the await: a page may have been appended while the request was
      // in flight, and writing back a list built from the older state would
      // discard it. The id stays a safe key because appends only grow the list.
      final latest = state;
      if (latest is! _LoadSuccess) return;
      final at = latest.reels.indexWhere((reel) => reel.id == reelId);
      if (at < 0) return;

      final updated = [...latest.reels];
      updated[at] = updated[at].copyWith(
        taggedProducts: fresh.taggedProducts,
      );
      state = ReelsFeedState.loadSuccess(updated);
    });
  }

  /// Fetches the next page and appends it to the current feed. Called when
  /// the user swipes near the end of the loaded reels — without this the
  /// feed dead-ends at [_pageSize] reels and further swipes have nothing to
  /// show (looks identical to a stuck/laggy feed).
  Future<void> fetchNextPage() async {
    final current = state;
    if (current is! _LoadSuccess || _loadingMore || _nextCursor == null) return;

    _loadingMore = true;
    try {
      final either = await _repository.getReelsFeed(
        limit: _pageSize,
        cursor: _nextCursor,
      );
      either.fold(
        (_) {}, // best-effort — keep showing what's already loaded
        (page) {
          _nextCursor = page.nextCursor;
          state = ReelsFeedState.loadSuccess([...current.reels, ...page.reels]);
        },
      );
    } finally {
      _loadingMore = false;
    }
  }
}
