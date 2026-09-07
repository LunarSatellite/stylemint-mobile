import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class AddPayoutMethodNotifier extends StateNotifier<AsyncValue<void>> {
  AddPayoutMethodNotifier(this._repository) : super(const AsyncValue.data(null));
  final EarningsRepository _repository;

  Future<void> addBank({
    required int kind,
    required String label,
    String? maskedAccountNumber,
    String? beneficiaryName,
    String? processorReference,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.addBankPayoutMethod(
      kind: kind,
      label: label,
      maskedAccountNumber: maskedAccountNumber,
      beneficiaryName: beneficiaryName,
      processorReference: processorReference,
    );
    state = result.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> addExternalWallet({
    required int kind,
    required String label,
    String? externalIdentifier,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.addExternalWalletPayoutMethod(
      kind: kind,
      label: label,
      externalIdentifier: externalIdentifier,
    );
    state = result.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      (_) => const AsyncValue.data(null),
    );
  }

  Future<void> remove(String methodId) async {
    state = const AsyncValue.loading();
    final result = await _repository.removePayoutMethod(methodId);
    state = result.fold(
      (f) => AsyncValue.error(f, StackTrace.current),
      (_) => const AsyncValue.data(null),
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

// ── Payout Invoice ─────────────────────────────────────────────────────────────

@freezed
abstract class PayoutInvoiceState with _$PayoutInvoiceState {
  const PayoutInvoiceState._();

  const factory PayoutInvoiceState.initial() = _PayoutInvoiceInitial;
  const factory PayoutInvoiceState.loadInProgress() = _PayoutInvoiceLoadInProgress;
  const factory PayoutInvoiceState.loadSuccess(PayoutInvoice invoice) =
      _PayoutInvoiceLoadSuccess;
  const factory PayoutInvoiceState.loadFailure(NetworkExceptions failure) =
      _PayoutInvoiceLoadFailure;
}

class PayoutInvoiceNotifier extends StateNotifier<PayoutInvoiceState> {
  PayoutInvoiceNotifier(this._repository, this._payoutId)
      : super(const PayoutInvoiceState.initial()) {
    unawaited(load());
  }

  final EarningsRepository _repository;
  final String _payoutId;

  Future<void> load() async {
    state = const PayoutInvoiceState.loadInProgress();
    final result = await _repository.getPayoutInvoice(_payoutId);
    state = result.fold(
      PayoutInvoiceState.loadFailure,
      PayoutInvoiceState.loadSuccess,
    );
  }
}

// ── Cancel Payout ──────────────────────────────────────────────────────────────

@freezed
abstract class CancelPayoutState with _$CancelPayoutState {
  const CancelPayoutState._();

  const factory CancelPayoutState.idle() = _CancelPayoutIdle;
  const factory CancelPayoutState.inProgress() = _CancelPayoutInProgress;
  const factory CancelPayoutState.success() = _CancelPayoutSuccess;
  const factory CancelPayoutState.failure(NetworkExceptions failure) =
      _CancelPayoutFailure;
}

class CancelPayoutNotifier extends StateNotifier<CancelPayoutState> {
  CancelPayoutNotifier(this._repository) : super(const CancelPayoutState.idle());

  final EarningsRepository _repository;

  Future<void> cancel(String payoutId) async {
    state = const CancelPayoutState.inProgress();
    final result = await _repository.cancelPayout(payoutId);
    state = result.fold(
      CancelPayoutState.failure,
      (_) => const CancelPayoutState.success(),
    );
  }
}
