import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/repositories/earnings_repository.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

part 'earnings_notifier.freezed.dart';

@freezed
abstract class EarningsState with _$EarningsState {
  const EarningsState._();

  const factory EarningsState.initial() = _EarningsInitial;
  const factory EarningsState.loadInProgress() = _EarningsLoadInProgress;
  const factory EarningsState.loadSuccess({
    required EarningsSummary summary,
    required List<EarningsLedgerEntry> entries,
    required List<PayoutMethod> payoutMethods,
  }) = _EarningsLoadSuccess;
  const factory EarningsState.loadFailure(NetworkExceptions failure) =
      _EarningsLoadFailure;
}

@freezed
abstract class RequestPayoutState with _$RequestPayoutState {
  const RequestPayoutState._();

  const factory RequestPayoutState.editing({
    @Default(0) double amount,
    String? selectedMethodId,
  }) = _RequestPayoutEditing;
  const factory RequestPayoutState.submitting() = _RequestPayoutSubmitting;
  const factory RequestPayoutState.success() = _RequestPayoutSuccess;
  const factory RequestPayoutState.failure(NetworkExceptions failure) =
      _RequestPayoutFailure;
}

class EarningsNotifier extends StateNotifier<EarningsState> {
  EarningsNotifier(this._repository) : super(const EarningsState.initial()) {
    unawaited(load());
  }

  final EarningsRepository _repository;

  Future<void> load() async {
    state = const EarningsState.loadInProgress();
    final summary = await _repository.getSummary();
    final entries = await _repository.getLedger();
    final methods = await _repository.getPayoutMethods();

    state = summary.fold(
      (f) => EarningsState.loadFailure(f),
      (s) => entries.fold(
        (f) => EarningsState.loadFailure(f),
        (e) => methods.fold(
          (f) => EarningsState.loadFailure(f),
          (m) => EarningsState.loadSuccess(
            summary: s,
            entries: e,
            payoutMethods: m,
          ),
        ),
      ),
    );
  }
}

class RequestPayoutNotifier extends StateNotifier<RequestPayoutState> {
  RequestPayoutNotifier(this._repository)
    : super(const RequestPayoutState.editing());

  final EarningsRepository _repository;

  void setAmount(double amount) {
    state = state.maybeWhen(
      editing: (_, selectedMethodId) => RequestPayoutState.editing(
        amount: amount,
        selectedMethodId: selectedMethodId,
      ),
      orElse: () => state,
    );
  }

  void setSelectedMethod(String methodId) {
    state = state.maybeWhen(
      editing: (amount, _) => RequestPayoutState.editing(
        amount: amount,
        selectedMethodId: methodId,
      ),
      orElse: () => state,
    );
  }

  Future<void> submit() async {
    final editing = state;
    if (editing is! _RequestPayoutEditing) return;
    final selectedMethodId = editing.selectedMethodId;
    if (selectedMethodId == null || editing.amount <= 0) return;

    state = const RequestPayoutState.submitting();
    final either = await _repository.requestPayout(
      amount: Money(amount: editing.amount, currency: 'NPR'),
      payoutMethodId: selectedMethodId,
    );
    state = either.fold(
      RequestPayoutState.failure,
      (_) => const RequestPayoutState.success(),
    );
  }
}
