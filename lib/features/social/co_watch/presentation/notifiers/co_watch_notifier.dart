import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/entities/co_watch.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/repositories/co_watch_repository.dart';

part 'co_watch_notifier.freezed.dart';

@freezed
abstract class CoWatchSessionsState with _$CoWatchSessionsState {
  const CoWatchSessionsState._();

  const factory CoWatchSessionsState.initial() = _SessionsInitial;
  const factory CoWatchSessionsState.loadInProgress() = _SessionsLoadInProgress;
  const factory CoWatchSessionsState.loadSuccess(
      List<CoWatchSession> sessions) = _SessionsLoadSuccess;
  const factory CoWatchSessionsState.loadFailure(NetworkExceptions failure) =
      _SessionsLoadFailure;
}

@freezed
abstract class CoWatchSessionDetailState with _$CoWatchSessionDetailState {
  const CoWatchSessionDetailState._();

  const factory CoWatchSessionDetailState.initial() = _SessionDetailInitial;
  const factory CoWatchSessionDetailState.loadInProgress() =
      _SessionDetailLoadInProgress;
  const factory CoWatchSessionDetailState.loadSuccess(
      CoWatchSession session) = _SessionDetailLoadSuccess;
  const factory CoWatchSessionDetailState.loadFailure(NetworkExceptions failure) =
      _SessionDetailLoadFailure;
}

@freezed
abstract class CoWatchReactionsState with _$CoWatchReactionsState {
  const CoWatchReactionsState._();

  const factory CoWatchReactionsState.initial() = _ReactionsInitial;
  const factory CoWatchReactionsState.loadInProgress() =
      _ReactionsLoadInProgress;
  const factory CoWatchReactionsState.loadSuccess(
      List<CoWatchReaction> reactions) = _ReactionsLoadSuccess;
  const factory CoWatchReactionsState.loadFailure(NetworkExceptions failure) =
      _ReactionsLoadFailure;
}

class CoWatchNotifier extends StateNotifier<CoWatchSessionsState> {
  CoWatchNotifier(this._repository)
      : super(const CoWatchSessionsState.initial()) {
    unawaited(loadSessions());
  }

  final CoWatchRepository _repository;

  Future<void> loadSessions() async {
    state = const CoWatchSessionsState.loadInProgress();
    final either = await _repository.getActiveSessions();
    state = either.fold(
      CoWatchSessionsState.loadFailure,
      CoWatchSessionsState.loadSuccess,
    );
  }

  Future<Either<NetworkExceptions, CoWatchSession>> createSession(
    CoWatchContentType contentType,
    String contentId,
  ) async {
    final either = await _repository.createSession(contentType, contentId);
    either.fold(
      (_) {},
      (_) => unawaited(loadSessions()),
    );
    return either;
  }

  Future<Either<NetworkExceptions, CoWatchSession>> join(String sessionId) async {
    final either = await _repository.joinSession(sessionId);
    either.fold(
      (_) {},
      (_) => unawaited(loadSessions()),
    );
    return either;
  }

  Future<Either<NetworkExceptions, Unit>> leave(String sessionId) async {
    final either = await _repository.leaveSession(sessionId);
    either.fold(
      (_) {},
      (_) => unawaited(loadSessions()),
    );
    return either;
  }

  Future<Either<NetworkExceptions, CoWatchReaction>> sendReaction(
    String sessionId,
    String reaction,
  ) async {
    return _repository.sendReaction(sessionId, reaction);
  }

  Future<Either<NetworkExceptions, List<CoWatchReaction>>> loadReactions(
    String sessionId,
  ) async {
    return _repository.getReactions(sessionId);
  }
}

class CoWatchSessionDetailNotifier
    extends StateNotifier<CoWatchSessionDetailState> {
  CoWatchSessionDetailNotifier(this._repository, String sessionId)
      : super(const CoWatchSessionDetailState.initial()) {
    unawaited(loadSession(sessionId));
  }

  final CoWatchRepository _repository;

  Future<void> loadSession(String sessionId) async {
    state = const CoWatchSessionDetailState.loadInProgress();
    final either = await _repository.getActiveSessions();
    state = either.fold(
      CoWatchSessionDetailState.loadFailure,
      (sessions) {
        final session = sessions.cast<CoWatchSession?>().firstWhere(
              (s) => s?.id == sessionId,
              orElse: () => null,
            );
        if (session != null) {
          return CoWatchSessionDetailState.loadSuccess(session);
        }
        return CoWatchSessionDetailState.loadFailure(
            const NetworkExceptions.notFound());
      },
    );
  }
}
