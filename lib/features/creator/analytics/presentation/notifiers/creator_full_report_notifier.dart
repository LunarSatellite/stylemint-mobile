import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/full_analytics_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/repositories/analytics_repository.dart';

part 'creator_full_report_notifier.freezed.dart';

@freezed
abstract class CreatorFullReportState with _$CreatorFullReportState {
  const CreatorFullReportState._();

  const factory CreatorFullReportState.initial() = _Initial;
  const factory CreatorFullReportState.loadInProgress() = _LoadInProgress;
  const factory CreatorFullReportState.loadSuccess(FullAnalyticsReport report) =
      _LoadSuccess;
  const factory CreatorFullReportState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class CreatorFullReportNotifier
    extends StateNotifier<CreatorFullReportState> {
  CreatorFullReportNotifier(this._repository)
      : super(const CreatorFullReportState.initial()) {
    unawaited(fetch());
  }

  final AnalyticsRepository _repository;

  Future<void> fetch({
    DateTime? fromUtc,
    DateTime? toUtc,
    int contentPerformanceLimit = 12,
    int topProductsLimit = 5,
    int topLocationsLimit = 5,
  }) async {
    state = const CreatorFullReportState.loadInProgress();
    final result = await _repository.getReport(
      fromUtc: fromUtc,
      toUtc: toUtc,
      contentPerformanceLimit: contentPerformanceLimit,
      topProductsLimit: topProductsLimit,
      topLocationsLimit: topLocationsLimit,
    );
    state = result.fold(
      CreatorFullReportState.loadFailure,
      CreatorFullReportState.loadSuccess,
    );
  }
}
