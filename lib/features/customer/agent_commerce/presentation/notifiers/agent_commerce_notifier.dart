import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/data/datasources/agent_commerce_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_commerce_copy.dart';
import 'package:uuid/uuid.dart';

/// Mandates, pending baskets and the activity ledger for the signed-in
/// customer.
///
/// ## What this class must never hold
///
/// A mandate credential. This is a provider: it outlives the screen, any
/// `ref.read` can inspect it, and a Riverpod observer or a crash reporter
/// could serialize it. Issuing is therefore driven by the sheet's own
/// `State`, which hands this notifier nothing but an
/// [AgentCommerceNotifier.refresh] call once the
/// mandate exists. [AgentMandate] has no credential field, so there is no way
/// to leak one through this state object.
class AgentCommerceState {
  const AgentCommerceState({
    this.mandates = const <AgentMandate>[],
    this.proposals = const <AgentProposal>[],
    this.activity = const <AgentActivityEntry>[],
    this.loading = false,
    this.loaded = false,
    this.mandatesFailed = false,
    this.proposalsFailed = false,
    this.activityFailed = false,
    this.revokingId,
    this.decidingProposalId,
    this.failure,
    this.lastRevokedName,
  });

  final List<AgentMandate> mandates;
  final List<AgentProposal> proposals;

  /// Allowed calls and refusals, newest first, exactly as the backend
  /// returned them. Nothing is filtered: a refusal is the evidence the
  /// customer's limits did something.
  final List<AgentActivityEntry> activity;

  final bool loading;

  /// A first read has completed. Distinguishes "nothing yet" from "nothing
  /// at all", so the screen does not flash an empty state.
  final bool loaded;

  /// Whether the last read of each list failed. Tracked per list because the
  /// three are separate endpoints: one of them failing must not blank the
  /// other two — least of all the mandates, where an empty list reads as
  /// "no assistant can act on your behalf" moments after issuing one.
  final bool mandatesFailed;
  final bool proposalsFailed;
  final bool activityFailed;

  /// Any of the three lists did not come back on the last read.
  bool get loadFailed => mandatesFailed || proposalsFailed || activityFailed;

  /// The mandate whose revoke call is in flight, if any.
  final String? revokingId;

  /// The proposal whose confirm/reject call is in flight, if any.
  final String? decidingProposalId;

  /// Backend `errorCode` of the last refused action the customer took, or
  /// [AgentCommerceCopy.transportFailure]. Only ever set by something they
  /// did — a failed background read sets [loadFailed] instead.
  final String? failure;

  /// Set after a successful revoke so the screen can confirm the escape
  /// hatch actually worked.
  final String? lastRevokedName;

  List<AgentMandate> activeAt(DateTime nowUtc) => mandates
      .where((m) => m.effectiveStateAt(nowUtc) == AgentMandateState.active)
      .toList(growable: false);

  List<AgentMandate> endedAt(DateTime nowUtc) => mandates
      .where((m) => m.effectiveStateAt(nowUtc) != AgentMandateState.active)
      .toList(growable: false);

  /// Baskets still waiting on the customer. An expired one drops out of here
  /// and into the history below it, rather than offering a button that would
  /// fail.
  List<AgentProposal> awaitingAt(DateTime nowUtc) =>
      proposals.where((p) => p.actionableAt(nowUtc)).toList(growable: false);

  List<AgentProposal> settledAt(DateTime nowUtc) =>
      proposals.where((p) => !p.actionableAt(nowUtc)).toList(growable: false);

  bool get isBusy => revokingId != null || decidingProposalId != null;

  AgentCommerceState copyWith({
    List<AgentMandate>? mandates,
    List<AgentProposal>? proposals,
    List<AgentActivityEntry>? activity,
    bool? loading,
    bool? loaded,
    bool? mandatesFailed,
    bool? proposalsFailed,
    bool? activityFailed,
    String? revokingId,
    bool clearRevoking = false,
    String? decidingProposalId,
    bool clearDeciding = false,
    String? failure,
    bool clearFailure = false,
    String? lastRevokedName,
    bool clearLastRevoked = false,
  }) => AgentCommerceState(
    mandates: mandates ?? this.mandates,
    proposals: proposals ?? this.proposals,
    activity: activity ?? this.activity,
    loading: loading ?? this.loading,
    loaded: loaded ?? this.loaded,
    mandatesFailed: mandatesFailed ?? this.mandatesFailed,
    proposalsFailed: proposalsFailed ?? this.proposalsFailed,
    activityFailed: activityFailed ?? this.activityFailed,
    revokingId: clearRevoking ? null : (revokingId ?? this.revokingId),
    decidingProposalId: clearDeciding
        ? null
        : (decidingProposalId ?? this.decidingProposalId),
    failure: clearFailure ? null : (failure ?? this.failure),
    lastRevokedName: clearLastRevoked
        ? null
        : (lastRevokedName ?? this.lastRevokedName),
  );
}

/// How many activity rows to ask for. Enough to cover a weekend of an agent
/// working, small enough to render without paging.
const int kAgentActivityPageSize = 60;

class AgentCommerceNotifier extends StateNotifier<AgentCommerceState> {
  AgentCommerceNotifier({
    required AgentCommerceDataSource dataSource,
    Uuid uuid = const Uuid(),
    bool loadOnCreate = true,
  }) : _ds = dataSource,
       _uuid = uuid,
       super(const AgentCommerceState()) {
    if (loadOnCreate) unawaited(refresh());
  }

  final AgentCommerceDataSource _ds;
  final Uuid _uuid;

  /// Re-reads all three lists. Failures here are quiet: the customer did not
  /// ask for this read, so a red box would be noise.
  ///
  /// The three reads run side by side but succeed or fail on their own. A
  /// list that fails keeps whatever it last showed and is flagged, so only
  /// its own section says it may be out of date.
  Future<void> refresh() async {
    if (!mounted) return;
    state = state.copyWith(loading: true);
    // Started before any is awaited, so they still run concurrently.
    final mandatesRead = _attempt(_ds.listMandates);
    final proposalsRead = _attempt(_ds.listProposals);
    final activityRead = _attempt(
      () => _ds.listActivity(limit: kAgentActivityPageSize),
    );
    final mandates = await mandatesRead;
    final proposals = await proposalsRead;
    final activity = await activityRead;
    if (!mounted) return;
    state = state.copyWith(
      // A null here means that read failed; copyWith then keeps the last
      // good list rather than replacing it with nothing.
      mandates: mandates,
      proposals: proposals,
      activity: activity,
      loading: false,
      loaded: true,
      mandatesFailed: mandates == null,
      proposalsFailed: proposals == null,
      activityFailed: activity == null,
    );
  }

  /// One read, with any failure folded into `null`.
  static Future<T?> _attempt<T extends Object>(
    Future<T> Function() read,
  ) async {
    try {
      return await read();
    } on Object {
      return null;
    }
  }

  /// Withdraws a mandate. One call, one step, from the mandate itself.
  Future<bool> revoke(AgentMandate mandate) async {
    if (!mounted || state.revokingId != null) return false;
    state = state.copyWith(
      revokingId: mandate.id,
      clearFailure: true,
      clearLastRevoked: true,
    );
    try {
      await _ds.revokeMandate(
        mandateId: mandate.id,
        idempotencyKey: _uuid.v4(),
      );
      if (!mounted) return true;
      state = state.copyWith(
        clearRevoking: true,
        lastRevokedName: mandate.agentName,
      );
      await refresh();
      return true;
    } on Object catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        clearRevoking: true,
        failure: agentErrorCodeOf(error),
      );
      return false;
    }
  }

  /// The human act. Only ever called from the basket sheet, which has just
  /// shown the customer every line and the total.
  Future<bool> confirm(AgentProposal proposal) =>
      _decide(proposal, confirm: true);

  Future<bool> reject(AgentProposal proposal) =>
      _decide(proposal, confirm: false);

  Future<bool> _decide(AgentProposal proposal, {required bool confirm}) async {
    if (!mounted || state.decidingProposalId != null) return false;
    state = state.copyWith(decidingProposalId: proposal.id, clearFailure: true);
    try {
      final key = _uuid.v4();
      if (confirm) {
        await _ds.confirmProposal(proposalId: proposal.id, idempotencyKey: key);
      } else {
        await _ds.rejectProposal(proposalId: proposal.id, idempotencyKey: key);
      }
      if (!mounted) return true;
      state = state.copyWith(clearDeciding: true);
      await refresh();
      return true;
    } on Object catch (error) {
      if (!mounted) return false;
      state = state.copyWith(
        clearDeciding: true,
        failure: agentErrorCodeOf(error),
      );
      return false;
    }
  }

  void dismissFailure() {
    if (!mounted) return;
    state = state.copyWith(clearFailure: true);
  }

  void dismissRevokeConfirmation() {
    if (!mounted) return;
    state = state.copyWith(clearLastRevoked: true);
  }
}

/// Reads the backend `errorCode` out of a failed call, falling back to a
/// transport sentinel so the customer is never shown a raw exception.
String agentErrorCodeOf(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final code = data['errorCode'];
      if (code is String && code.trim().isNotEmpty) return code.trim();
    }
  }
  return AgentCommerceCopy.transportFailure;
}
