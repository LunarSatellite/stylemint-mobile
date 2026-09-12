import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/entities/live_session.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/repositories/live_commerce_repository.dart';

part 'live_sessions_notifier.freezed.dart';

@freezed
abstract class LiveSessionsState with _$LiveSessionsState {
  const LiveSessionsState._();

  const factory LiveSessionsState.initial() = _Initial;
  const factory LiveSessionsState.loadInProgress() = _LoadInProgress;
  const factory LiveSessionsState.loadSuccess({
    required List<LiveSession> live,
    required List<LiveSession> upcoming,
  }) = _LoadSuccess;
  const factory LiveSessionsState.loadFailure(NetworkExceptions failure) = _LoadFailure;
}

class LiveSessionsNotifier extends StateNotifier<LiveSessionsState> {
  LiveSessionsNotifier(this._repository) : super(const LiveSessionsState.initial()) {
    unawaited(load());
  }

  final LiveCommerceRepository _repository;

  Future<void> load() async {
    state = const LiveSessionsState.loadInProgress();
    final liveEither = await _repository.getLive();

    if (liveEither.isLeft()) {
      liveEither.fold((f) => state = LiveSessionsState.loadFailure(f), (_) {});
      return;
    }

    final live = liveEither.getOrElse((_) => const []);
    // Upcoming is a secondary rail — a failure there shouldn't hide an
    // otherwise-successful "live now" list, so it just falls back to empty.
    final upcomingEither = await _repository.getUpcoming();
    final upcoming = upcomingEither.getOrElse((_) => const []);

    state = LiveSessionsState.loadSuccess(live: live, upcoming: upcoming);
  }
}
