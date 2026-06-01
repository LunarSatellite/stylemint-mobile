import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/handle_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

part 'handle_notifier.freezed.dart';

@freezed
abstract class HandleListState with _$HandleListState {
  const HandleListState._();

  const factory HandleListState.initial() = _HandleListInitial;
  const factory HandleListState.loadInProgress() = _HandleListInProgress;
  const factory HandleListState.loadSuccess(List<HandleDto> handles) =
      _HandleListSuccess;
  const factory HandleListState.loadFailure(NetworkExceptions failure) =
      _HandleListNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class HandleListNotifier extends StateNotifier<HandleListState> {
  HandleListNotifier({required this.authRepository})
      : super(const HandleListState.initial());

  final AuthRepository authRepository;

  Future<void> load(String accountId) async {
    state = const HandleListState.loadInProgress();
    final result = await authRepository.listHandles(accountId);
    state = result.fold(HandleListState.loadFailure, HandleListState.loadSuccess);
  }
}

@freezed
abstract class HandleActionState with _$HandleActionState {
  const HandleActionState._();

  const factory HandleActionState.initial() = _HandleActionInitial;
  const factory HandleActionState.loadInProgress() = _HandleActionInProgress;
  const factory HandleActionState.loadSuccess(HandleDto? handle) =
      _HandleActionSuccess;
  const factory HandleActionState.loadFailure(NetworkExceptions failure) =
      _HandleActionNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class HandleActionNotifier extends StateNotifier<HandleActionState> {
  HandleActionNotifier({required this.authRepository})
      : super(const HandleActionState.initial());

  final AuthRepository authRepository;

  Future<void> registerHandle({
    required String accountId,
    required String handle,
  }) async {
    state = const HandleActionState.loadInProgress();
    final result = await authRepository.registerHandle(
      accountId: accountId,
      handle: handle,
    );
    state = result.fold(
      HandleActionState.loadFailure,
      HandleActionState.loadSuccess,
    );
  }

  Future<void> activateHandle({
    required String accountId,
    required String handleId,
  }) async {
    state = const HandleActionState.loadInProgress();
    final result = await authRepository.activateHandle(
      accountId: accountId,
      handleId: handleId,
    );
    state = result.fold(
      HandleActionState.loadFailure,
      (_) => const HandleActionState.loadSuccess(null),
    );
  }

  Future<void> deactivateHandle({
    required String accountId,
    required String handleId,
  }) async {
    state = const HandleActionState.loadInProgress();
    final result = await authRepository.deactivateHandle(
      accountId: accountId,
      handleId: handleId,
    );
    state = result.fold(
      HandleActionState.loadFailure,
      (_) => const HandleActionState.loadSuccess(null),
    );
  }

  void reset() => state = const HandleActionState.initial();
}

final handleListProvider =
    StateNotifierProvider<HandleListNotifier, HandleListState>(
  (ref) => HandleListNotifier(authRepository: ref.watch(authRepositoryProvider)),
);

final handleActionProvider =
    StateNotifierProvider<HandleActionNotifier, HandleActionState>(
  (ref) =>
      HandleActionNotifier(authRepository: ref.watch(authRepositoryProvider)),
);
