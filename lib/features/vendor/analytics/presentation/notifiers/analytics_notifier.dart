import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/entities/vendor_analytics_summary.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/repositories/analytics_repository.dart';

part 'analytics_notifier.freezed.dart';

@freezed
abstract class AnalyticsState with _$AnalyticsState {
  const factory AnalyticsState.initial() = _Initial;
  const factory AnalyticsState.loadInProgress() = _LoadInProgress;
  const factory AnalyticsState.loadSuccess(VendorAnalyticsSummary summary) =
      _LoadSuccess;
  const factory AnalyticsState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  AnalyticsNotifier(this._repository) : super(const AnalyticsState.initial()) {
    unawaited(load());
  }

  final AnalyticsRepository _repository;

  Future<void> load({String? window}) async {
    state = const AnalyticsState.loadInProgress();
    final either = await _repository.getSummary(window: window);
    state = either.fold(
      AnalyticsState.loadFailure,
      AnalyticsState.loadSuccess,
    );
  }
}
