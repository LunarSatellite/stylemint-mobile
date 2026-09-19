import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/repositories/clienteling_repository.dart';
import 'package:uuid/uuid.dart';

part 'my_clienteling_notifier.freezed.dart';

@freezed
abstract class MyClientelingState with _$MyClientelingState {
  const factory MyClientelingState.initial() = MyClientelingInitial;
  const factory MyClientelingState.loadInProgress() =
      MyClientelingLoadInProgress;

  const factory MyClientelingState.loadSuccess({
    required List<AssistedOutcome> claims,

    /// Null when the history call failed while the claims call succeeded —
    /// an unreadable trail is not an empty one.
    List<ClientelingActivity>? history,

    /// The outcome whose confirm/reject is in flight, if any.
    String? busyOutcomeId,
    NetworkExceptions? actionFailure,
  }) = MyClientelingLoadSuccess;

  const factory MyClientelingState.loadFailure(NetworkExceptions failure) =
      MyClientelingLoadFailure;
}

/// Drives `v1/clienteling/me/*` — the shopper's own view of who acted on their
/// account, and the only place a claim can become credit.
class MyClientelingNotifier extends StateNotifier<MyClientelingState> {
  MyClientelingNotifier(this._repository)
    : super(const MyClientelingState.initial()) {
    unawaited(load());
  }

  final CustomerClientelingRepository _repository;
  static const _uuid = Uuid();

  Future<void> load() async {
    state = const MyClientelingState.loadInProgress();
    final claimsEither = await _repository.listClaims();
    if (!mounted) return;

    final claims = claimsEither.fold<List<AssistedOutcome>?>(
      (_) => null,
      (rows) => rows,
    );
    if (claims == null) {
      state = MyClientelingState.loadFailure(
        claimsEither.fold(
          (f) => f,
          (_) => const NetworkExceptions.unexpectedError(),
        ),
      );
      return;
    }

    final historyEither = await _repository.listHistory();
    if (!mounted) return;

    state = MyClientelingState.loadSuccess(
      claims: claims,
      history: historyEither.fold((_) => null, (rows) => rows),
    );
  }

  Future<void> confirm(String outcomeId) => _decide(
    outcomeId,
    (key) => _repository.confirmOutcome(
      outcomeId: outcomeId,
      idempotencyKey: key,
    ),
  );

  Future<void> reject(String outcomeId) => _decide(
    outcomeId,
    (key) => _repository.rejectOutcome(
      outcomeId: outcomeId,
      idempotencyKey: key,
    ),
  );

  Future<void> _decide(
    String outcomeId,
    Future<Either<NetworkExceptions, AssistedOutcome>> Function(String key)
    call,
  ) async {
    final current = state;
    if (current is! MyClientelingLoadSuccess) return;
    if (current.busyOutcomeId != null) return;

    state = current.copyWith(busyOutcomeId: outcomeId, actionFailure: null);
    final either = await call(_uuid.v4());
    if (!mounted) return;

    state = either.fold(
      (f) => current.copyWith(busyOutcomeId: null, actionFailure: f),
      (decided) => current.copyWith(
        busyOutcomeId: null,
        claims: [
          for (final c in current.claims)
            if (c.outcomeId == decided.outcomeId) decided else c,
        ],
      ),
    );
  }
}
