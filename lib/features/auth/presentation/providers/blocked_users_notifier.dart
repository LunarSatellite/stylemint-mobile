import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/blocked_user_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

part 'blocked_users_notifier.freezed.dart';

@freezed
abstract class BlockedUsersState with _$BlockedUsersState {
  const BlockedUsersState._();

  const factory BlockedUsersState.initial() = _BlockedUsersInitial;
  const factory BlockedUsersState.loadInProgress() = _BlockedUsersInProgress;
  const factory BlockedUsersState.loadSuccess(
    List<BlockedUserDto> blockedUsers,
  ) = _BlockedUsersSuccess;
  const factory BlockedUsersState.loadFailure(NetworkExceptions failure) =
      _BlockedUsersNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class BlockedUsersNotifier extends StateNotifier<BlockedUsersState> {
  BlockedUsersNotifier({required this.authRepository})
      : super(const BlockedUsersState.initial());

  final AuthRepository authRepository;

  Future<void> load(String accountId) async {
    state = const BlockedUsersState.loadInProgress();
    final result = await authRepository.listBlockedUsers(accountId);
    state = result.fold(
      BlockedUsersState.loadFailure,
      BlockedUsersState.loadSuccess,
    );
  }

  Future<void> unblockUser({
    required String accountId,
    required String blockedAccountId,
  }) async {
    await authRepository.unblockUser(
      accountId: accountId,
      blockedAccountId: blockedAccountId,
    );
    await load(accountId);
  }

  void reset() => state = const BlockedUsersState.initial();
}

final blockedUsersProvider =
    StateNotifierProvider<BlockedUsersNotifier, BlockedUsersState>(
  (ref) =>
      BlockedUsersNotifier(authRepository: ref.watch(authRepositoryProvider)),
);
