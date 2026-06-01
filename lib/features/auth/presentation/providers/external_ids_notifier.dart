import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/external_id_dto.dart';
import 'package:stylemint_mobile_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';

part 'external_ids_notifier.freezed.dart';

@freezed
abstract class ExternalIdsState with _$ExternalIdsState {
  const ExternalIdsState._();

  const factory ExternalIdsState.initial() = _ExternalIdsInitial;
  const factory ExternalIdsState.loadInProgress() = _ExternalIdsInProgress;
  const factory ExternalIdsState.loadSuccess(
    List<ExternalIdDto> providers,
  ) = _ExternalIdsSuccess;
  const factory ExternalIdsState.loadFailure(NetworkExceptions failure) =
      _ExternalIdsNetworkExceptions;

  bool get isLoading =>
      maybeWhen(loadInProgress: () => true, orElse: () => false);
}

class ExternalIdsNotifier extends StateNotifier<ExternalIdsState> {
  ExternalIdsNotifier({required this.authRepository})
      : super(const ExternalIdsState.initial());

  final AuthRepository authRepository;

  Future<void> load(String accountId) async {
    state = const ExternalIdsState.loadInProgress();
    final result = await authRepository.listExternalIds(accountId);
    state = result.fold(
      ExternalIdsState.loadFailure,
      ExternalIdsState.loadSuccess,
    );
  }

  Future<void> unlinkExternalId({
    required String accountId,
    required String provider,
  }) async {
    await authRepository.unlinkExternalId(
      accountId: accountId,
      provider: provider,
    );
    await load(accountId);
  }

  void reset() => state = const ExternalIdsState.initial();
}

final externalIdsProvider =
    StateNotifierProvider<ExternalIdsNotifier, ExternalIdsState>(
  (ref) =>
      ExternalIdsNotifier(authRepository: ref.watch(authRepositoryProvider)),
);
