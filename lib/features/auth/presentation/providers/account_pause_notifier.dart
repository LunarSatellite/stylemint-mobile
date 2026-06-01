import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/account_pause_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

part 'account_pause_notifier.freezed.dart';

@freezed
abstract class AccountPauseState with _$AccountPauseState {
  const AccountPauseState._();

  const factory AccountPauseState.initial() = _AccountPauseInitial;
  const factory AccountPauseState.loadInProgress() = _AccountPauseInProgress;
  const factory AccountPauseState.loadSuccess(AccountPauseDto pause) =
      _AccountPauseSuccess;
  const factory AccountPauseState.loadFailure(NetworkExceptions failure) =
      _AccountPauseNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

@freezed
abstract class AccountPauseActionState with _$AccountPauseActionState {
  const AccountPauseActionState._();

  const factory AccountPauseActionState.initial() = _PauseActionInitial;
  const factory AccountPauseActionState.loadInProgress() = _PauseActionInProgress;
  const factory AccountPauseActionState.loadSuccess() = _PauseActionSuccess;
  const factory AccountPauseActionState.loadFailure(NetworkExceptions failure) =
      _PauseActionNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class AccountPauseNotifier extends StateNotifier<AccountPauseState> {
  AccountPauseNotifier({required this.authRepository})
      : super(const AccountPauseState.initial());

  final AuthRepository authRepository;

  Future<void> load() async {
    state = const AccountPauseState.loadInProgress();
    final result = await authRepository.getPause();
    state = result.fold(AccountPauseState.loadFailure, AccountPauseState.loadSuccess);
  }

  void reset() => state = const AccountPauseState.initial();
}

class AccountPauseActionNotifier extends StateNotifier<AccountPauseActionState> {
  AccountPauseActionNotifier({required this.authRepository})
      : super(const AccountPauseActionState.initial());

  final AuthRepository authRepository;

  Future<void> pause({required int days}) async {
    state = const AccountPauseActionState.loadInProgress();
    final result = await authRepository.pause(days: days);
    state = result.fold(
      AccountPauseActionState.loadFailure,
      (_) => const AccountPauseActionState.loadSuccess(),
    );
  }

  Future<void> resume() async {
    state = const AccountPauseActionState.loadInProgress();
    final result = await authRepository.resume();
    state = result.fold(
      AccountPauseActionState.loadFailure,
      (_) => const AccountPauseActionState.loadSuccess(),
    );
  }

  void reset() => state = const AccountPauseActionState.initial();
}

final accountPauseProvider =
    StateNotifierProvider<AccountPauseNotifier, AccountPauseState>(
  (ref) =>
      AccountPauseNotifier(authRepository: ref.watch(authRepositoryProvider)),
);

final accountPauseActionProvider =
    StateNotifierProvider<AccountPauseActionNotifier, AccountPauseActionState>(
  (ref) => AccountPauseActionNotifier(
    authRepository: ref.watch(authRepositoryProvider),
  ),
);
