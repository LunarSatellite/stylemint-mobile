import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/role_profile_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';

part 'role_notifier.freezed.dart';

@freezed
abstract class RolesState with _$RolesState {
  const RolesState._();

  const factory RolesState.initial() = _RolesInitial;
  const factory RolesState.loadInProgress() = _RolesInProgress;
  const factory RolesState.loadSuccess(List<RoleProfileDto> roles) =
      _RolesSuccess;
  const factory RolesState.loadFailure(NetworkExceptions failure) = _RolesNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class RoleNotifier extends StateNotifier<RolesState> {
  RoleNotifier({required this.authRepository})
      : super(const RolesState.initial());

  final AuthRepository authRepository;

  Future<void> loadRoles(String accountId) async {
    state = const RolesState.loadInProgress();
    final result = await authRepository.getRoles(accountId);
    state = result.fold(RolesState.loadFailure, RolesState.loadSuccess);
  }

  Future<void> requestRole(String accountId, int role) async {
    state = const RolesState.loadInProgress();
    final result = await authRepository.requestRole(accountId, role);
    state = result.fold(
      RolesState.loadFailure,
      (_) {
        loadRoles(accountId);
        return const RolesState.initial();
      },
    );
  }

  Future<void> activateRole(String accountId, int role) async {
    final result = await authRepository.activateRole(accountId, role);
    result.fold(
      (_) {},
      (_) => loadRoles(accountId),
    );
  }

  void reset() => state = const RolesState.initial();
}
