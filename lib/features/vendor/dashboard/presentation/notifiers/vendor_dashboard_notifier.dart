import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/vendor_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/repositories/vendor_dashboard_repository.dart';

part 'vendor_dashboard_notifier.freezed.dart';

@freezed
abstract class VendorDashboardState with _$VendorDashboardState {
  const VendorDashboardState._();

  const factory VendorDashboardState.initial() = _DashboardInitial;
  const factory VendorDashboardState.loadInProgress() = _DashboardLoadInProgress;
  const factory VendorDashboardState.loadSuccess(VendorDashboard dashboard) = _DashboardLoadSuccess;
  const factory VendorDashboardState.loadFailure(NetworkExceptions failure) = _DashboardLoadFailure;
}

class VendorDashboardNotifier extends StateNotifier<VendorDashboardState> {
  VendorDashboardNotifier(this._repository)
    : super(const VendorDashboardState.initial()) {
    unawaited(load());
  }

  final VendorDashboardRepository _repository;

  Future<void> load() async {
    state = const VendorDashboardState.loadInProgress();
    final either = await _repository.getDashboard();
    state = either.fold(
      VendorDashboardState.loadFailure,
      VendorDashboardState.loadSuccess,
    );
  }
}
