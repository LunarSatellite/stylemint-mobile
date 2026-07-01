import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_reel_analytics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/repositories/analytics_repository.dart';

part 'creator_reel_analytics_notifier.freezed.dart';

@freezed
abstract class CreatorReelAnalyticsState with _$CreatorReelAnalyticsState {
  const CreatorReelAnalyticsState._();

  const factory CreatorReelAnalyticsState.initial() = _Initial;
  const factory CreatorReelAnalyticsState.loadInProgress() = _LoadInProgress;
  const factory CreatorReelAnalyticsState.loadSuccess(
    CreatorReelAnalytics analytics,
  ) = _LoadSuccess;
  const factory CreatorReelAnalyticsState.loadFailure(
    NetworkExceptions failure,
  ) = _LoadFailure;
}

class CreatorReelAnalyticsNotifier
    extends StateNotifier<CreatorReelAnalyticsState> {
  CreatorReelAnalyticsNotifier(this._repository, this._reelId)
      : super(const CreatorReelAnalyticsState.initial()) {
    unawaited(fetch());
  }

  final AnalyticsRepository _repository;
  final String _reelId;

  Future<void> fetch({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topLocationsLimit = 5,
  }) async {
    state = const CreatorReelAnalyticsState.loadInProgress();
    final result = await _repository.getReelAnalytics(
      reelId: _reelId,
      fromUtc: fromUtc,
      toUtc: toUtc,
      topLocationsLimit: topLocationsLimit,
    );
    state = result.fold(
      CreatorReelAnalyticsState.loadFailure,
      CreatorReelAnalyticsState.loadSuccess,
    );
  }
}
