import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/handover_delegation_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';
import 'package:uuid/uuid.dart';

/// State of the delegated-handover list for **one** parcel.
///
/// ## What this class must never hold
///
/// A `verificationCode`. This is a provider — it outlives the screen, it can
/// be inspected by any `ref.read`, and a Riverpod observer or a crash reporter
/// could serialize it. The code therefore never passes through here: creation
/// is driven by the sheet's own `State`, which hands this notifier only a
/// [HandoverDelegationNotifier.refresh] call once the delegation exists.
/// `HandoverDelegation` itself has
/// no code field, so there is no way to leak one through this state object.
class HandoverDelegationState {
  const HandoverDelegationState({
    this.delegations = const <HandoverDelegation>[],
    this.loading = false,
    this.loaded = false,
    this.revokingId,
    this.failure,
    this.lastRevoked,
    this.loadFailed = false,
  });

  final List<HandoverDelegation> delegations;
  final bool loading;

  /// A first read has completed (successfully or not). Distinguishes
  /// "nothing yet" from "nothing at all", so the card does not flash empty.
  final bool loaded;

  /// The delegation whose revoke call is in flight, if any.
  final String? revokingId;

  /// Backend `errorCode` of the last refused **revoke**, or a sentinel for
  /// transport failure. Null once the customer has seen and dismissed it.
  ///
  /// Only ever set by an action the customer took. A failed background read
  /// sets [loadFailed] instead: the card appears unprompted, and shouting
  /// about a network error nobody asked about is worse than staying quiet.
  final String? failure;

  /// Set for one frame after a successful revoke, so the UI can confirm the
  /// escape hatch actually worked.
  final HandoverDelegation? lastRevoked;

  /// The last read did not come back. The card draws nothing rather than a
  /// red box, matching how the other unprompted delivery cards behave.
  final bool loadFailed;

  bool get isRevoking => revokingId != null;

  /// The one delegation that can still authorise a handover, if any. The
  /// backend enforces at most one active row per parcel.
  HandoverDelegation? activeAt(DateTime nowUtc) {
    for (final d in delegations) {
      if (d.effectiveStatusAt(nowUtc) == HandoverDelegationStatus.active) {
        return d;
      }
    }
    return null;
  }

  /// Everything that is no longer live, newest first — the customer's record
  /// of who they let take a parcel and what became of it.
  List<HandoverDelegation> historyAt(DateTime nowUtc) {
    final rows =
        delegations
            .where(
              (d) =>
                  d.effectiveStatusAt(nowUtc) !=
                  HandoverDelegationStatus.active,
            )
            .toList()
          ..sort(
            (a, b) => (b.createdUtc ?? b.windowStartUtc).compareTo(
              a.createdUtc ?? a.windowStartUtc,
            ),
          );
    return rows;
  }

  HandoverDelegationState copyWith({
    List<HandoverDelegation>? delegations,
    bool? loading,
    bool? loaded,
    String? revokingId,
    bool clearRevoking = false,
    String? failure,
    bool clearFailure = false,
    HandoverDelegation? lastRevoked,
    bool clearLastRevoked = false,
    bool? loadFailed,
  }) => HandoverDelegationState(
    delegations: delegations ?? this.delegations,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    revokingId: clearRevoking ? null : (revokingId ?? this.revokingId),
    failure: clearFailure ? null : (failure ?? this.failure),
    lastRevoked: clearLastRevoked ? null : (lastRevoked ?? this.lastRevoked),
    loadFailed: loadFailed ?? this.loadFailed,
  );
}

/// Sentinel `failure` value for a network/5xx failure with no backend code.
const String kHandoverTransportFailure = 'handover.transport_failure';

class HandoverDelegationNotifier
    extends StateNotifier<HandoverDelegationState> {
  HandoverDelegationNotifier({
    required HandoverDelegationDataSource dataSource,
    required this.trackingNumber,
    DateTime Function()? clock,
    Uuid uuid = const Uuid(),
  }) : _dataSource = dataSource,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _uuid = uuid,
       super(const HandoverDelegationState());

  final HandoverDelegationDataSource _dataSource;
  final String trackingNumber;
  final DateTime Function() _clock;
  final Uuid _uuid;

  /// The key for the revoke attempt currently being retried. Held per
  /// delegation id so a retried tap is the same call, not a second one.
  final Map<String, String> _revokeKeys = <String, String>{};

  /// Reads the list. [keepFailure] is set by the re-read that follows a
  /// refused revoke: the customer still needs to see *why* it was refused,
  /// and a reload that silently cleared the message would leave them with a
  /// row that changed under them and no explanation.
  Future<void> load({bool keepFailure = false}) async {
    if (state.loading) return;
    state = state.copyWith(loading: true, clearFailure: !keepFailure);
    try {
      final rows = await _dataSource.list(trackingNumber);
      if (!mounted) return;
      state = state.copyWith(
        delegations: rows,
        loading: false,
        loaded: true,
        loadFailed: false,
      );
    } on Object catch (_) {
      if (!mounted) return;
      // Not surfaced as a refusal: the customer did not ask for this read.
      state = state.copyWith(loading: false, loaded: true, loadFailed: true);
    }
  }

  /// Re-reads after the sheet created a delegation. Takes no argument on
  /// purpose: the sheet has an [IssuedHandoverDelegation] with a code in it,
  /// and handing that to a provider is exactly what must not happen.
  Future<void> refresh() => load();

  /// The customer's escape hatch. One call, no confirmation step — if they
  /// tapped revoke they meant it, and someone being pressured into creating a
  /// delegation must be able to undo it without a dialogue they have to
  /// explain to whoever is standing next to them.
  Future<bool> revoke(String delegationId, {String? reason}) async {
    if (state.isRevoking) return false;
    final key = _revokeKeys.putIfAbsent(delegationId, _uuid.v4);
    state = state.copyWith(
      revokingId: delegationId,
      clearFailure: true,
      clearLastRevoked: true,
    );
    try {
      final revoked = await _dataSource.revoke(
        trackingNumber: trackingNumber,
        delegationId: delegationId,
        reason: reason,
        idempotencyKey: key,
      );
      _revokeKeys.remove(delegationId);
      if (!mounted) return true;
      state = state.copyWith(
        delegations: _replace(revoked),
        clearRevoking: true,
        lastRevoked: revoked,
      );
      return true;
    } on Object catch (error) {
      if (!mounted) return false;
      // Keep the key: the same attempt may be retried, and the backend's
      // idempotency record makes that a no-op rather than a second write.
      state = state.copyWith(
        clearRevoking: true,
        failure: _errorCodeOf(error) ?? kHandoverTransportFailure,
      );
      // A delegation that is already gone, used or expired cannot be revoked
      // again, and the list on screen is stale — re-read so the customer sees
      // the truth behind the message.
      unawaited(load(keepFailure: true));
      return false;
    }
  }

  void dismissFailure() => state = state.copyWith(clearFailure: true);

  void dismissRevokedNotice() => state = state.copyWith(clearLastRevoked: true);

  /// Current UTC, for widgets deciding what is active/expired right now.
  DateTime now() => _clock();

  List<HandoverDelegation> _replace(HandoverDelegation updated) => [
    for (final d in state.delegations)
      if (d.id == updated.id) updated else d,
  ];

  static String? _errorCodeOf(Object error) {
    if (error is! DioException) return null;
    final data = error.response?.data;
    if (data is Map) {
      final code = data['errorCode'];
      if (code is String && code.trim().isNotEmpty) return code.trim();
    }
    return null;
  }
}
