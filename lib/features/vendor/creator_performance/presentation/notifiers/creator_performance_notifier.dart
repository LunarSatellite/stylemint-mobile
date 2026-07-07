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

class CreatorPerformanceNotifier
    extends StateNotifier<CreatorPerformanceState> {
  CreatorPerformanceNotifier(this._repository)
    : super(const CreatorPerformanceState.initial()) {
    unawaited(load());
  }

  final CreatorPerformanceRepository _repository;

  Future<void> load({String? sortBy, String? window}) async {
    state = const CreatorPerformanceState.loadInProgress();
    final either = await _repository.getCreatorPerformance(
      sortBy: sortBy,
      window: window,
    );
    state = either.fold(
      CreatorPerformanceState.loadFailure,
      CreatorPerformanceState.loadSuccess,
    );
  }
}
