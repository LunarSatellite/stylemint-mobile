import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/account_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';

part 'account_notifier.freezed.dart';

@freezed
abstract class AccountState with _$AccountState {
  const AccountState._();

  const factory AccountState.initial() = _AccountInitial;
  const factory AccountState.loadInProgress() = _AccountInProgress;
  const factory AccountState.loadSuccess(AccountDto account) = _AccountSuccess;
  const factory AccountState.loadFailure(NetworkExceptions failure) = _AccountNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class AccountNotifier extends StateNotifier<AccountState> {
  AccountNotifier({required this.authRepository})
      : super(const AccountState.initial());

  final AuthRepository authRepository;

  Future<void> loadAccount(String accountId) async {
    state = const AccountState.loadInProgress();
    final result = await authRepository.getAccount(accountId);
    state = result.fold(AccountState.loadFailure, AccountState.loadSuccess);
  }

  Future<void> updateProfile({
    required String accountId,
    String? displayName,
    String? locale,
    String? timezone,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
    String? countryCode,
    String? rowVersion,
  }) async {
    state = const AccountState.loadInProgress();
    final result = await authRepository.updateProfile(
      accountId: accountId,
      displayName: displayName,
      locale: locale,
      timezone: timezone,
      dateOfBirth: dateOfBirth,
      gender: gender,
      avatarUrl: avatarUrl,
      countryCode: countryCode,
      rowVersion: rowVersion,
    );
    state = result.fold(AccountState.loadFailure, AccountState.loadSuccess);
  }

  Future<void> pauseAccount({required int days}) async {
    final result = await authRepository.pause(days: days);
    result.fold((f) => state = AccountState.loadFailure(f), (_) {});
  }

  Future<void> resumeAccount() async {
    final result = await authRepository.resume();
    result.fold((f) => state = AccountState.loadFailure(f), (_) {});
  }

  Future<void> deleteAccount({
    required String accountId,
    required String idempotencyKey,
  }) async {
    state = const AccountState.loadInProgress();
    final result =
        await authRepository.deleteAccount(accountId, idempotencyKey);
    result.fold(
      (f) => state = AccountState.loadFailure(f),
      (_) => state = const AccountState.initial(),
    );
  }

  void reset() => state = const AccountState.initial();
}
