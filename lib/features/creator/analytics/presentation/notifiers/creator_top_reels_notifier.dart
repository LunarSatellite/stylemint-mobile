import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reels_sort.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/repositories/analytics_repository.dart';

part 'creator_top_reels_notifier.freezed.dart';

@freezed
abstract class CreatorTopReelsState with _$CreatorTopReelsState {
  const CreatorTopReelsState._();

  const factory CreatorTopReelsState.initial() = _Initial;
  const factory CreatorTopReelsState.loadInProgress() = _LoadInProgress;
  const factory CreatorTopReelsState.loadSuccess(List<TopReelSummary> reels) =
      _LoadSuccess;
  const factory CreatorTopReelsState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class CreatorTopReelsNotifier
    extends StateNotifier<CreatorTopReelsState> {
  CreatorTopReelsNotifier(this._repository)
      : super(const CreatorTopReelsState.initial()) {
    unawaited(fetch());
  }

  final AnalyticsRepository _repository;

  Future<void> fetch({
    TopReelsSort sortBy = TopReelsSort.highestEarnings,
    DateTime? fromUtc,
    DateTime? toUtc,
    int limit = 25,
  }) async {
    state = const CreatorTopReelsState.loadInProgress();
    final result = await _repository.getTopReels(
      sortBy: sortBy,
      fromUtc: fromUtc,
      toUtc: toUtc,
      limit: limit,
    );
    state = result.fold(
      CreatorTopReelsState.loadFailure,
      CreatorTopReelsState.loadSuccess,
    );
  }
}
