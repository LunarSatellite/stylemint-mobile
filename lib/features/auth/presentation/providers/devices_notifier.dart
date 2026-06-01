import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/device_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

part 'devices_notifier.freezed.dart';

@freezed
abstract class DevicesListState with _$DevicesListState {
  const DevicesListState._();

  const factory DevicesListState.initial() = _DevicesListInitial;
  const factory DevicesListState.loadInProgress() = _DevicesListInProgress;
  const factory DevicesListState.loadSuccess(List<DeviceDto> devices) =
      _DevicesListSuccess;
  const factory DevicesListState.loadFailure(NetworkExceptions failure) =
      _DevicesListNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class DevicesListNotifier extends StateNotifier<DevicesListState> {
  DevicesListNotifier({required this.authRepository})
      : super(const DevicesListState.initial());

  final AuthRepository authRepository;

  Future<void> load(String accountId) async {
    state = const DevicesListState.loadInProgress();
    final result = await authRepository.listDevices(accountId);
    state = result.fold(DevicesListState.loadFailure, DevicesListState.loadSuccess);
  }
}

@freezed
abstract class DeviceActionState with _$DeviceActionState {
  const DeviceActionState._();

  const factory DeviceActionState.initial() = _DeviceActionInitial;
  const factory DeviceActionState.loadInProgress() = _DeviceActionInProgress;
  const factory DeviceActionState.loadSuccess() = _DeviceActionSuccess;
  const factory DeviceActionState.loadFailure(NetworkExceptions failure) =
      _DeviceActionNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class DeviceActionNotifier extends StateNotifier<DeviceActionState> {
  DeviceActionNotifier({required this.authRepository})
      : super(const DeviceActionState.initial());

  final AuthRepository authRepository;

  Future<void> trustDevice({
    required String accountId,
    required String deviceId,
  }) async {
    state = const DeviceActionState.loadInProgress();
    final result = await authRepository.trustDevice(
      accountId: accountId,
      deviceId: deviceId,
    );
    state = result.fold(
      DeviceActionState.loadFailure,
      (_) => const DeviceActionState.loadSuccess(),
    );
  }

  Future<void> untrustDevice({
    required String accountId,
    required String deviceId,
  }) async {
    state = const DeviceActionState.loadInProgress();
    final result = await authRepository.untrustDevice(
      accountId: accountId,
      deviceId: deviceId,
    );
    state = result.fold(
      DeviceActionState.loadFailure,
      (_) => const DeviceActionState.loadSuccess(),
    );
  }

  Future<void> revokeDevice({
    required String accountId,
    required String deviceId,
  }) async {
    state = const DeviceActionState.loadInProgress();
    final result = await authRepository.revokeDevice(
      accountId: accountId,
      deviceId: deviceId,
    );
    state = result.fold(
      DeviceActionState.loadFailure,
      (_) => const DeviceActionState.loadSuccess(),
    );
  }

  Future<void> renameDevice({
    required String accountId,
    required String deviceId,
    required String nickname,
  }) async {
    state = const DeviceActionState.loadInProgress();
    final result = await authRepository.renameDevice(
      accountId: accountId,
      deviceId: deviceId,
      nickname: nickname,
    );
    state = result.fold(
      DeviceActionState.loadFailure,
      (_) => const DeviceActionState.loadSuccess(),
    );
  }

  void reset() => state = const DeviceActionState.initial();
}

final devicesListProvider =
    StateNotifierProvider<DevicesListNotifier, DevicesListState>(
  (ref) =>
      DevicesListNotifier(authRepository: ref.watch(authRepositoryProvider)),
);

final deviceActionProvider =
    StateNotifierProvider<DeviceActionNotifier, DeviceActionState>(
  (ref) =>
      DeviceActionNotifier(authRepository: ref.watch(authRepositoryProvider)),
);
