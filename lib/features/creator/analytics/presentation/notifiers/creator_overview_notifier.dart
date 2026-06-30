import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_analytics_overview.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/repositories/analytics_repository.dart';

part 'creator_overview_notifier.freezed.dart';

@freezed
abstract class CreatorOverviewState with _$CreatorOverviewState {
  const CreatorOverviewState._();

  const factory CreatorOverviewState.initial() = _Initial;
  const factory CreatorOverviewState.loadInProgress() = _LoadInProgress;
  const factory CreatorOverviewState.loadSuccess(
    CreatorAnalyticsOverview overview,
  ) = _LoadSuccess;
  const factory CreatorOverviewState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class CreatorOverviewNotifier extends StateNotifier<CreatorOverviewState> {
  CreatorOverviewNotifier(this._repository)
      : super(const CreatorOverviewState.initial()) {
    unawaited(fetch());
  }

  final AnalyticsRepository _repository;

  Future<void> fetch({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit = 5,
    int topProductsLimit = 5,
  }) async {
    state = const CreatorOverviewState.loadInProgress();
    final result = await _repository.getOverview(
      fromUtc: fromUtc,
      toUtc: toUtc,
      topReelsLimit: topReelsLimit,
      topProductsLimit: topProductsLimit,
    );
    state = result.fold(
      CreatorOverviewState.loadFailure,
      CreatorOverviewState.loadSuccess,
    );
  }
}
