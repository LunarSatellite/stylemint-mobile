import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/repositories/creator_dashboard_repository.dart';

part 'creator_dashboard_notifier.freezed.dart';

@freezed
abstract class DashboardState with _$DashboardState {
  const DashboardState._();

  const factory DashboardState.initial() = _DashboardInitial;
  const factory DashboardState.loadInProgress() = _DashboardLoadInProgress;
  const factory DashboardState.loadSuccess(CreatorDashboard dashboard) = _DashboardLoadSuccess;
  const factory DashboardState.loadFailure(NetworkExceptions failure) = _DashboardLoadFailure;
}

class CreatorDashboardNotifier extends StateNotifier<DashboardState> {
  CreatorDashboardNotifier(this._repository)
    : super(const DashboardState.initial()) {
    unawaited(load());
  }

  final CreatorDashboardRepository _repository;

  Future<void> load() async {
    state = const DashboardState.loadInProgress();
    final either = await _repository.getDashboard();
    state = either.fold(
      DashboardState.loadFailure,
      DashboardState.loadSuccess,
    );
  }
}
