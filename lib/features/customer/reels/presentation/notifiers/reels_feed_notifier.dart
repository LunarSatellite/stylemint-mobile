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
  const factory ReelsFeedState.loadFailure(NetworkExceptions failure) = _LoadFailure;
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
