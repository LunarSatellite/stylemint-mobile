import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/entities/creator_performance.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/repositories/creator_performance_repository.dart';

part 'creator_performance_notifier.freezed.dart';

@freezed
abstract class CreatorPerformanceState with _$CreatorPerformanceState {
  const CreatorPerformanceState._();

  const factory CreatorPerformanceState.initial() = _Initial;
  const factory CreatorPerformanceState.loadInProgress() = _LoadInProgress;
  const factory CreatorPerformanceState.loadSuccess(
    List<CreatorPerformance> creators,
  ) = _LoadSuccess;
  const factory CreatorPerformanceState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

/// The backend has no server-side sort parameter for
/// `GET /v1/vendor/analytics/creators` (it returns items ordered by revenue
/// desc) — these are applied client-side after fetch.
enum CreatorPerformanceSortBy { revenue, sales, commission }

class CreatorPerformanceNotifier
    extends StateNotifier<CreatorPerformanceState> {
  CreatorPerformanceNotifier(this._repository)
    : super(const CreatorPerformanceState.initial()) {
    unawaited(load());
  }

  final CreatorPerformanceRepository _repository;

  Future<void> load({
    int? windowDays,
    CreatorPerformanceSortBy sortBy = CreatorPerformanceSortBy.revenue,
  }) async {
    state = const CreatorPerformanceState.loadInProgress();
    final either = await _repository.getCreatorPerformance(
      windowDays: windowDays,
    );
    state = either.fold(
      CreatorPerformanceState.loadFailure,
      (creators) => CreatorPerformanceState.loadSuccess(
        _sorted(creators, sortBy),
      ),
    );
  }

  List<CreatorPerformance> _sorted(
    List<CreatorPerformance> creators,
    CreatorPerformanceSortBy sortBy,
  ) {
    final sorted = [...creators];
    switch (sortBy) {
      case CreatorPerformanceSortBy.revenue:
        sorted.sort(
          (a, b) => b.attributedRevenue.amount.compareTo(
            a.attributedRevenue.amount,
          ),
        );
      case CreatorPerformanceSortBy.sales:
        sorted.sort((a, b) => b.unitsSold.compareTo(a.unitsSold));
      case CreatorPerformanceSortBy.commission:
        sorted.sort(
          (a, b) =>
              b.commissionPaid.amount.compareTo(a.commissionPaid.amount),
        );
    }
    return sorted;
  }
}
