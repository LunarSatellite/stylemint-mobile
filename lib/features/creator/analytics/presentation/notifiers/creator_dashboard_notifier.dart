import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/repositories/analytics_repository.dart';

part 'creator_dashboard_notifier.freezed.dart';

@freezed
abstract class CreatorDashboardState with _$CreatorDashboardState {
  const CreatorDashboardState._();

  const factory CreatorDashboardState.initial() = _Initial;
  const factory CreatorDashboardState.loadInProgress() = _LoadInProgress;
  const factory CreatorDashboardState.loadSuccess(CreatorDashboard dashboard) =
      _LoadSuccess;
  const factory CreatorDashboardState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class CreatorDashboardNotifier
    extends StateNotifier<CreatorDashboardState> {
  CreatorDashboardNotifier(this._repository)
      : super(const CreatorDashboardState.initial()) {
    unawaited(fetch());
  }

  final AnalyticsRepository _repository;

  Future<void> fetch({
    DateTime? fromUtc,
    DateTime? toUtc,
    int topReelsLimit = 5,
    int topProductsLimit = 5,
  }) async {
    state = const CreatorDashboardState.loadInProgress();
    final result = await _repository.getDashboard(
      fromUtc: fromUtc,
      toUtc: toUtc,
      topReelsLimit: topReelsLimit,
      topProductsLimit: topProductsLimit,
    );
    state = result.fold(
      CreatorDashboardState.loadFailure,
      CreatorDashboardState.loadSuccess,
    );
  }
}
