import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/data/repositories/missions_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/repositories/missions_repository.dart';

class MissionDetailState {
  const MissionDetailState({
    this.mission,
    this.loading = false,
    this.busyItemId,
    this.busyAction = false,
    this.error,
  });

  final ShoppingMission? mission;
  final bool loading;

  /// The item whose state change is in flight, if any.
  final String? busyItemId;

  /// A mission-level action (replan / complete / abandon) is in flight.
  final bool busyAction;

  final String? error;

  MissionDetailState copyWith({
    ShoppingMission? mission,
    bool? loading,
    String? busyItemId,
    bool? busyAction,
    String? error,
  }) => MissionDetailState(
    mission: mission ?? this.mission,
    loading: loading ?? this.loading,
    busyItemId: busyItemId,
    busyAction: busyAction ?? this.busyAction,
    error: error,
  );
}

/// Drives one mission. Every mutation replaces the whole mission with what
/// the server returned — coverage, cost and the budget verdict are never
/// recomputed here, so what the shopper reads is always the server's answer.
class MissionDetailNotifier extends StateNotifier<MissionDetailState> {
  MissionDetailNotifier(this._repository, this.missionId)
    : super(const MissionDetailState());

  final MissionsRepository _repository;
  final String missionId;

  Future<void> load() async {
    state = state.copyWith(loading: true);
    final result = await _repository.get(missionId);
    if (!mounted) return;
    state = result.fold(
      (failure) => state.copyWith(loading: false, error: describe(failure)),
      (mission) => MissionDetailState(mission: mission),
    );
  }

  Future<bool> setItemState(MissionItem item, MissionItemState next) => _mutate(
    () => _repository.setItemState(
      missionId: missionId,
      itemId: item.id,
      state: next,
    ),
    itemId: item.id,
  );

  Future<bool> replan() => _mutate(() => _repository.replan(missionId));

  Future<bool> complete() => _mutate(() => _repository.complete(missionId));

  Future<bool> abandon() => _mutate(() => _repository.abandon(missionId));

  void clearError() => state = state.copyWith();

  Future<bool> _mutate(
    Future<Either<NetworkExceptions, ShoppingMission>> Function() call, {
    String? itemId,
  }) async {
    if (state.busyAction || state.busyItemId != null) return false;
    // A terminal mission refuses every change; don't even ask.
    final current = state.mission;
    if (current != null && current.isTerminal) {
      state = state.copyWith(error: current.terminalReason);
      return false;
    }
    state = state.copyWith(busyItemId: itemId, busyAction: itemId == null);
    final result = await call();
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(busyAction: false, error: describe(failure));
        return false;
      },
      (mission) {
        state = MissionDetailState(mission: mission);
        return true;
      },
    );
  }

  /// Turns a failure into the shopper's words. A terminal mission is the one
  /// case that must explain itself rather than saying "something went wrong".
  static String describe(NetworkExceptions failure) => failure.when(
    server: (message) => message,
    serverUnavailable: () => 'Missions are unreachable right now. Try again.',
    noInternetConnection: () => 'You appear to be offline.',
    unexpectedError: () => 'Something went wrong. Try again.',
    formatException: () => 'That mission could not be read.',
    emptyData: () => 'Nothing came back.',
    validation: (code, message, _, _) =>
        code == MissionsRepositoryImpl.invalidTransitionCode
        ? 'This mission is finished, so it cannot be changed any more.'
        : message ?? 'That could not be done.',
    auth: () => 'Please sign in again.',
    notFound: () => 'This mission is no longer available.',
    conflict: () =>
        'This mission is finished, so it cannot be changed '
        'any more.',
  );
}
