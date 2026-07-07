import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/repositories/vendor_earnings_repository.dart';

part 'vendor_earnings_notifier.freezed.dart';

@freezed
abstract class EarningsSummaryState with _$EarningsSummaryState {
  const EarningsSummaryState._();

  const factory EarningsSummaryState.initial() = _EarningsSummaryInitial;
  const factory EarningsSummaryState.loadInProgress() =
      _EarningsSummaryLoadInProgress;
  const factory EarningsSummaryState.loadSuccess({
    required VendorEarningsSummary summary,
  }) = _EarningsSummaryLoadSuccess;
  const factory EarningsSummaryState.loadFailure(NetworkExceptions failure) =
      _EarningsSummaryLoadFailure;
}

@freezed
abstract class LedgerState with _$LedgerState {
  const LedgerState._();

  const factory LedgerState.initial() = _LedgerInitial;
  const factory LedgerState.loadInProgress() = _LedgerLoadInProgress;
  const factory LedgerState.loadSuccess({
    required List<VendorEarningsLedger> entries,
    required bool hasMore,
  }) = _LedgerLoadSuccess;
  const factory LedgerState.loadFailure(NetworkExceptions failure) =
      _LedgerLoadFailure;
}

@freezed
abstract class BalanceState with _$BalanceState {
  const BalanceState._();

  const factory BalanceState.initial() = _BalanceInitial;
  const factory BalanceState.loadInProgress() = _BalanceLoadInProgress;
  const factory BalanceState.loadSuccess(VendorEarningsBalance balance) =
      _BalanceLoadSuccess;
  const factory BalanceState.loadFailure(NetworkExceptions failure) =
      _BalanceLoadFailure;
}

@freezed
abstract class PayoutState with _$PayoutState {
  const PayoutState._();

  const factory PayoutState.editing({
    @Default(0) double amount,
    String? selectedDestinationId,
    int? selectedDestinationKind,
  }) = _PayoutEditing;
  const factory PayoutState.submitting() = _PayoutSubmitting;
  const factory PayoutState.success() = _PayoutSuccess;
  const factory PayoutState.failure(NetworkExceptions failure) = _PayoutFailure;
}

class VendorEarningsNotifier extends StateNotifier<EarningsSummaryState> {
  VendorEarningsNotifier(this._repository)
    : super(const EarningsSummaryState.initial()) {
    unawaited(loadSummary());
  }

  final VendorEarningsRepository _repository;

  Future<void> loadSummary() async {
    state = const EarningsSummaryState.loadInProgress();
    final result = await _repository.getEarningsSummary();
    state = result.fold(
      EarningsSummaryState.loadFailure,
      (summary) => EarningsSummaryState.loadSuccess(summary: summary),
    );
  }
}

class LedgerNotifier extends StateNotifier<LedgerState> {
  LedgerNotifier(this._repository) : super(const LedgerState.initial()) {
    unawaited(loadLedger());
  }

  final VendorEarningsRepository _repository;

  Future<void> loadLedger({String? cursor}) async {
    state = const LedgerState.loadInProgress();
    final result = await _repository.getLedger(cursor: cursor);
    state = result.fold(
      LedgerState.loadFailure,
      (paged) =>
          LedgerState.loadSuccess(entries: paged.items, hasMore: paged.hasMore),
    );
  }
}

class BalanceNotifier extends StateNotifier<BalanceState> {
  BalanceNotifier(this._repository) : super(const BalanceState.initial()) {
    unawaited(load());
  }

  final VendorEarningsRepository _repository;

  Future<void> load() async {
    state = const BalanceState.loadInProgress();
    final result = await _repository.getBalance();
    state = result.fold(BalanceState.loadFailure, BalanceState.loadSuccess);
  }
}

class PayoutNotifier extends StateNotifier<PayoutState> {
  PayoutNotifier(this._repository) : super(const PayoutState.editing());

  final VendorEarningsRepository _repository;

  void setAmount(double amount) {
    state = state.maybeWhen(
      editing: (_, destinationId, destinationKind) => PayoutState.editing(
        amount: amount,
        selectedDestinationId: destinationId,
        selectedDestinationKind: destinationKind,
      ),
      orElse: () => state,
    );
  }

  void setSelectedDestination(String destinationId, int destinationKind) {
    state = state.maybeWhen(
      editing: (amount, _, __) => PayoutState.editing(
        amount: amount,
        selectedDestinationId: destinationId,
        selectedDestinationKind: destinationKind,
      ),
      orElse: () => state,
    );
  }

  Future<void> submit() async {
    final editing = state;
    if (editing is! _PayoutEditing) return;
    final destinationId = editing.selectedDestinationId;
    final destinationKind = editing.selectedDestinationKind;
    if (destinationId == null ||
        destinationKind == null ||
        editing.amount <= 0) {
      return;
    }

    state = const PayoutState.submitting();
    final either = await _repository.requestPayout(
      amount: editing.amount,
      destinationKind: destinationKind,
      destinationId: destinationId,
    );
    state = either.fold(
      PayoutState.failure,
      (_) => const PayoutState.success(),
    );
  }
}
