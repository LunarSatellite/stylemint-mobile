import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/mfa_method_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/totp_enrollment_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

part 'mfa_notifier.freezed.dart';

@freezed
abstract class MfaListState with _$MfaListState {
  const MfaListState._();

  const factory MfaListState.initial() = _MfaListInitial;
  const factory MfaListState.loadInProgress() = _MfaListInProgress;
  const factory MfaListState.loadSuccess(List<MfaMethodDto> methods) =
      _MfaListSuccess;
  const factory MfaListState.loadFailure(NetworkExceptions failure) = _MfaListNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class MfaListNotifier extends StateNotifier<MfaListState> {
  MfaListNotifier({required this.authRepository})
      : super(const MfaListState.initial());

  final AuthRepository authRepository;

  Future<void> load(String accountId) async {
    state = const MfaListState.loadInProgress();
    final result = await authRepository.listMfaMethods(accountId);
    state = result.fold(MfaListState.loadFailure, MfaListState.loadSuccess);
  }
}

@freezed
abstract class MfaActionState with _$MfaActionState {
  const MfaActionState._();

  const factory MfaActionState.initial() = _MfaActionInitial;
  const factory MfaActionState.loadInProgress() = _MfaActionInProgress;
  const factory MfaActionState.loadSuccess() = _MfaActionSuccess;
  const factory MfaActionState.loadFailure(NetworkExceptions failure) = _MfaActionNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class MfaActionNotifier extends StateNotifier<MfaActionState> {
  MfaActionNotifier({required this.authRepository})
      : super(const MfaActionState.initial());

  final AuthRepository authRepository;

  Future<void> disableMfa({
    required String accountId,
    required String methodId,
  }) async {
    state = const MfaActionState.loadInProgress();
    final result = await authRepository.disableMfa(
      accountId: accountId,
      methodId: methodId,
    );
    state = result.fold(MfaActionState.loadFailure, (_) => const MfaActionState.loadSuccess());
  }

  Future<void> setPrimary({
    required String accountId,
    required String methodId,
  }) async {
    state = const MfaActionState.loadInProgress();
    final result = await authRepository.setPrimaryMfa(
      accountId: accountId,
      methodId: methodId,
    );
    state = result.fold(MfaActionState.loadFailure, (_) => const MfaActionState.loadSuccess());
  }

  Future<void> renameLabel({
    required String accountId,
    required String methodId,
    required String label,
  }) async {
    state = const MfaActionState.loadInProgress();
    final result = await authRepository.renameMfa(
      accountId: accountId,
      methodId: methodId,
      label: label,
    );
    state = result.fold(MfaActionState.loadFailure, (_) => const MfaActionState.loadSuccess());
  }

  void reset() => state = const MfaActionState.initial();
}

@freezed
abstract class TotpEnrollmentState with _$TotpEnrollmentState {
  const TotpEnrollmentState._();

  const factory TotpEnrollmentState.initial() = _TotpEnrollInitial;
  const factory TotpEnrollmentState.loadInProgress() = _TotpEnrollInProgress;
  const factory TotpEnrollmentState.loadSuccess(TotpEnrollmentDto enrollment) =
      _TotpEnrollSuccess;
  const factory TotpEnrollmentState.loadFailure(NetworkExceptions failure) =
      _TotpEnrollNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class TotpEnrollmentNotifier extends StateNotifier<TotpEnrollmentState> {
  TotpEnrollmentNotifier({required this.authRepository})
      : super(const TotpEnrollmentState.initial());

  final AuthRepository authRepository;

  Future<void> beginEnrollment(String accountId) async {
    state = const TotpEnrollmentState.loadInProgress();
    final result = await authRepository.beginTotpEnrollment(accountId);
    state = result.fold(
      TotpEnrollmentState.loadFailure,
      TotpEnrollmentState.loadSuccess,
    );
  }

  Future<void> confirm({
    required String accountId,
    required String methodId,
    required String code,
  }) async {
    state = const TotpEnrollmentState.loadInProgress();
    final result = await authRepository.confirmTotp(
      accountId: accountId,
      methodId: methodId,
      code: code,
    );
    state = result.fold(
      TotpEnrollmentState.loadFailure,
      (_) => const TotpEnrollmentState.initial(),
    );
  }

  void reset() => state = const TotpEnrollmentState.initial();
}

final mfaListProvider = StateNotifierProvider<MfaListNotifier, MfaListState>(
  (ref) => MfaListNotifier(authRepository: ref.watch(authRepositoryProvider)),
);

final mfaActionProvider =
    StateNotifierProvider<MfaActionNotifier, MfaActionState>(
  (ref) => MfaActionNotifier(authRepository: ref.watch(authRepositoryProvider)),
);

final totpEnrollmentProvider =
    StateNotifierProvider<TotpEnrollmentNotifier, TotpEnrollmentState>(
  (ref) =>
      TotpEnrollmentNotifier(authRepository: ref.watch(authRepositoryProvider)),
);
