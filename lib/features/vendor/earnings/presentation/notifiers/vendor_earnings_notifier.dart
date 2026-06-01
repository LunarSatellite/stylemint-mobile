import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/entities/vendor_earnings.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/domain/repositories/vendor_earnings_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'vendor_earnings_notifier.freezed.dart';

@freezed
abstract class EarningsSummaryState with _$EarningsSummaryState {
  const EarningsSummaryState._();

  const factory EarningsSummaryState.initial() = _EarningsSummaryInitial;
  const factory EarningsSummaryState.loadInProgress() = _EarningsSummaryLoadInProgress;
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
  const factory LedgerState.loadFailure(NetworkExceptions failure) = _LedgerLoadFailure;
}

@freezed
abstract class PayoutState with _$PayoutState {
  const PayoutState._();

  const factory PayoutState.editing({
    @Default(0) double amount,
    String? selectedMethodId,
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

  Future<void> loadLedger({String? cursor}) async {
    final result = await _repository.getLedger(cursor: cursor);
    result.fold(
      (_) {},
      (paged) {
        // Handled in LedgerNotifier for pagination
      },
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
      (paged) => LedgerState.loadSuccess(
        entries: paged.items,
        hasMore: paged.hasMore,
      ),
    );
  }
}

@freezed
abstract class PayoutMethodsState with _$PayoutMethodsState {
  const PayoutMethodsState._();

  const factory PayoutMethodsState.initial() = _PayoutMethodsInitial;
  const factory PayoutMethodsState.loadInProgress() = _PayoutMethodsLoadInProgress;
  const factory PayoutMethodsState.loadSuccess({
    required List<VendorPayoutMethod> methods,
  }) = _PayoutMethodsLoadSuccess;
  const factory PayoutMethodsState.loadFailure(NetworkExceptions failure) =
      _PayoutMethodsLoadFailure;
}

class PayoutMethodsNotifier extends StateNotifier<PayoutMethodsState> {
  PayoutMethodsNotifier(this._repository)
      : super(const PayoutMethodsState.initial()) {
    load();
  }

  final VendorEarningsRepository _repository;

  Future<void> load() async {
    state = const PayoutMethodsState.loadInProgress();
    final result = await _repository.getPayoutMethods();
    state = result.fold(
      PayoutMethodsState.loadFailure,
      (methods) => PayoutMethodsState.loadSuccess(methods: methods),
    );
  }
}

class PayoutNotifier extends StateNotifier<PayoutState> {
  PayoutNotifier(this._repository) : super(const PayoutState.editing());

  final VendorEarningsRepository _repository;

  void setAmount(double amount) {
    state = state.maybeWhen(
      editing: (_, selectedMethodId) => PayoutState.editing(
        amount: amount,
        selectedMethodId: selectedMethodId,
      ),
      orElse: () => state,
    );
  }

  void setSelectedMethod(String methodId) {
    state = state.maybeWhen(
      editing: (amount, _) => PayoutState.editing(
        amount: amount,
        selectedMethodId: methodId,
      ),
      orElse: () => state,
    );
  }

  Future<void> submit() async {
    final editing = state;
    if (editing is! _PayoutEditing) return;
    final selectedMethodId = editing.selectedMethodId;
    if (selectedMethodId == null || editing.amount <= 0) return;

    state = const PayoutState.submitting();
    final either = await _repository.requestPayout(
      amount: Money(amount: editing.amount, currency: 'NPR'),
      methodId: selectedMethodId,
    );
    state = either.fold(PayoutState.failure, (_) => const PayoutState.success());
  }
}
