import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/entities/demand_signals.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/domain/repositories/demand_signals_repository.dart';

part 'demand_signals_notifier.freezed.dart';

@freezed
abstract class DemandSignalsState with _$DemandSignalsState {
  const factory DemandSignalsState.initial() = _Initial;
  const factory DemandSignalsState.loadInProgress() = _LoadInProgress;
  const factory DemandSignalsState.loadSuccess(DemandSignals signals) =
      _LoadSuccess;
  const factory DemandSignalsState.loadFailure(NetworkExceptions failure) =
      _LoadFailure;
}

class DemandSignalsNotifier extends StateNotifier<DemandSignalsState> {
  DemandSignalsNotifier(this._repository)
    : super(const DemandSignalsState.initial()) {
    unawaited(load());
  }

  static const defaultDays = 7;
  static const pageLimit = 20;

  final DemandSignalsRepository _repository;
  int _days = defaultDays;
  int _requestSeq = 0;

  /// The look-back window currently shown (or being loaded), in days.
  int get days => _days;

  /// Loads signals for [days] (keeps the current window when omitted).
  /// A response for a window the vendor has since switched away from is
  /// discarded, so a slow 7-day reply can't overwrite the 30-day list.
  Future<void> load({int? days}) async {
    _days = days ?? _days;
    final requestedDays = _days;
    final seq = ++_requestSeq;
    state = const DemandSignalsState.loadInProgress();
    final either = await _repository.getDemandSignals(
      days: requestedDays,
      limit: pageLimit,
    );
    if (!mounted || seq != _requestSeq) return;
    state = either.fold(
      DemandSignalsState.loadFailure,
      DemandSignalsState.loadSuccess,
    );
  }
}
