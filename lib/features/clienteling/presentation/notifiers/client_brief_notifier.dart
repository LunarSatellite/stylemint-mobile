import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/entities/clienteling_entities.dart';
import 'package:stylemint_mobile_frontend/features/clienteling/domain/repositories/clienteling_repository.dart';
import 'package:uuid/uuid.dart';

part 'client_brief_notifier.freezed.dart';

@freezed
abstract class ClientBriefState with _$ClientBriefState {
  const factory ClientBriefState.initial() = ClientBriefInitial;
  const factory ClientBriefState.loadInProgress() = ClientBriefLoadInProgress;

  const factory ClientBriefState.loadSuccess({
    required ClientBrief brief,

    /// Null when the trail could not be read — which is not the same as an
    /// empty trail, and is rendered differently.
    List<ClientelingActivity>? activity,

    /// The session this workspace opened. The API has no "my open sessions"
    /// read route, so this is null until the associate starts serving —
    /// re-opening is safe, the backend returns the live session if one exists.
    AssistSession? session,

    /// The platform's answer to the last outreach request, sent or blocked.
    OutreachAttempt? lastOutreach,

    /// The last claim filed. Unverified until the customer answers.
    AssistedOutcome? lastClaim,
    @Default(false) bool actionInProgress,
    NetworkExceptions? actionFailure,
  }) = ClientBriefLoadSuccess;

  const factory ClientBriefState.loadFailure(NetworkExceptions failure) =
      ClientBriefLoadFailure;
}

/// Drives one permitted customer's workspace.
///
/// Loading the brief is itself a recorded act that the customer can see, so
/// this notifier is only ever constructed from a deliberate navigation.
class ClientBriefNotifier extends StateNotifier<ClientBriefState> {
  ClientBriefNotifier(this._repository, this.customerAccountId)
    : super(const ClientBriefState.initial()) {
    unawaited(load());
  }

  final AssociateClientelingRepository _repository;
  final String customerAccountId;
  static const _uuid = Uuid();

  Future<void> load() async {
    state = const ClientBriefState.loadInProgress();
    final briefEither = await _repository.getBrief(customerAccountId);
    if (!mounted) return;

    final brief = briefEither.fold<ClientBrief?>((_) => null, (b) => b);
    if (brief == null) {
      state = ClientBriefState.loadFailure(
        briefEither.fold(
          (f) => f,
          (_) => const NetworkExceptions.unexpectedError(),
        ),
      );
      return;
    }

    final activityEither = await _repository.listMyActivity(
      customerAccountId: customerAccountId,
      limit: 25,
    );
    if (!mounted) return;

    state = ClientBriefState.loadSuccess(
      brief: brief,
      // The trail is a secondary read: if it fails the brief still shows and
      // the section says the trail could not be loaded. Only a successful
      // empty response reads as "nothing recorded yet".
      activity: activityEither.fold(
        (_) => null,
        (rows) => rows,
      ),
    );
  }

  ClientBriefLoadSuccess? get _loaded {
    final current = state;
    return current is ClientBriefLoadSuccess ? current : null;
  }

  /// Runs one mutation against the loaded workspace, holding the busy flag and
  /// clearing the previous failure. No-ops while another action is in flight.
  Future<void> _runAction(
    Future<void> Function(ClientBriefLoadSuccess loaded) action,
  ) async {
    final loaded = _loaded;
    if (loaded == null || loaded.actionInProgress) return;
    state = loaded.copyWith(actionInProgress: true, actionFailure: null);
    await action(loaded);
  }

  /// Starts (or re-attaches to) a session for this customer. The API returns
  /// the already-open session when there is one, so this is safe to repeat.
  Future<void> startServing(String purpose) => _runAction((loaded) async {
    final either = await _repository.openSession(
      customerAccountId: customerAccountId,
      purpose: purpose,
      idempotencyKey: _uuid.v4(),
    );
    if (!mounted) return;
    state = either.fold(
      (f) => loaded.copyWith(actionInProgress: false, actionFailure: f),
      (session) => loaded.copyWith(session: session, actionInProgress: false),
    );
  });

  Future<void> stopServing() => _runAction((loaded) async {
    final session = loaded.session;
    if (session == null) {
      state = loaded.copyWith(actionInProgress: false);
      return;
    }
    final either = await _repository.closeSession(
      sessionId: session.sessionId,
      idempotencyKey: _uuid.v4(),
    );
    if (!mounted) return;
    state = either.fold(
      (f) => loaded.copyWith(actionInProgress: false, actionFailure: f),
      (closed) => loaded.copyWith(session: closed, actionInProgress: false),
    );
  });

  /// Asks the platform to carry a message. A blocked decision is a successful
  /// call: the returned attempt says what happened and is kept on screen.
  Future<void> sendOutreach({
    required ClientelingOutreachChannel channel,
    required String subject,
    required String body,
  }) => _runAction((loaded) async {
    final either = await _repository.sendOutreach(
      customerAccountId: customerAccountId,
      channel: channel,
      subject: subject,
      body: body,
      sessionId: loaded.session?.sessionId,
      idempotencyKey: _uuid.v4(),
    );
    if (!mounted) return;
    state = either.fold(
      (f) => loaded.copyWith(actionInProgress: false, actionFailure: f),
      (attempt) =>
          loaded.copyWith(lastOutreach: attempt, actionInProgress: false),
    );
  });

  Future<void> claimOutcome({required String orderId, String? note}) =>
      _runAction((loaded) async {
        final session = loaded.session;
        if (session == null) {
          state = loaded.copyWith(actionInProgress: false);
          return;
        }
        final either = await _repository.claimOutcome(
          sessionId: session.sessionId,
          orderId: orderId,
          note: note,
          idempotencyKey: _uuid.v4(),
        );
        if (!mounted) return;
        state = either.fold(
          (f) => loaded.copyWith(actionInProgress: false, actionFailure: f),
          (outcome) =>
              loaded.copyWith(lastClaim: outcome, actionInProgress: false),
        );
      });
}
