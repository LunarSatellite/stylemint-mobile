import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/domain/entities/agent_mandate.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_commerce_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_mandate_issue_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/presentation/widgets/agent_proposal_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_commerce/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// **Connected assistants** — the customer's whole relationship with outside
/// AI shopping agents, on one screen.
///
/// Four things live here, in the order a customer needs them:
/// 1. baskets waiting on their confirmation, because that is the only thing
///    on this screen that somebody else is waiting for;
/// 2. the assistants that currently hold authority, each with its limits in
///    plain sight and a one-tap withdrawal;
/// 3. mandates that have ended, so revoking leaves a record rather than a gap;
/// 4. everything any assistant asked for — allowed and refused alike.
class ConnectedAssistantsScreen extends ConsumerWidget {
  const ConnectedAssistantsScreen({super.key, this.clock});

  final DateTime Function()? clock;

  DateTime _now() => clock?.call() ?? DateTime.now().toUtc();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agentCommerceNotifierProvider);
    final notifier = ref.read(agentCommerceNotifierProvider.notifier);
    final now = _now();
    final awaiting = state.awaitingAt(now);
    final active = state.activeAt(now);
    final ended = state.endedAt(now);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Connected assistants'),
      ),
      body: RefreshIndicator(
        onRefresh: notifier.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s32,
          ),
          children: [
            const Text(
              'An outside AI assistant can shop on your behalf here, but only '
              'inside a mandate you issue: what it may do, how much it may '
              'spend, in which currency, which products, and for how long.',
              style: DesignTokens.mediumRegular,
            ),
            const SizedBox(height: DesignTokens.s16),
            Semantics(
              container: true,
              button: true,
              label: 'Connect an outside assistant by issuing a new mandate',
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const ValueKey('agent-connect-button'),
                  onPressed: () =>
                      showAgentMandateIssueSheet(context, clock: clock),
                  icon: const Icon(Icons.add_moderator_outlined, size: 18),
                  label: const Text('Connect an assistant'),
                ),
              ),
            ),

            if (state.failure != null) ...[
              const SizedBox(height: DesignTokens.s16),
              AgentActionFailureNotice(
                errorCode: state.failure!,
                onDismiss: notifier.dismissFailure,
              ),
            ],
            if (state.lastRevokedName != null) ...[
              const SizedBox(height: DesignTokens.s16),
              _RevokedConfirmation(
                agentName: state.lastRevokedName!,
                onDismiss: notifier.dismissRevokeConfirmation,
              ),
            ],
            if (state.loadFailed) ...[
              const SizedBox(height: DesignTokens.s16),
              const _QuietLoadFailure(),
            ],

            // ── 1. Waiting on the customer ──
            const SizedBox(height: DesignTokens.s24),
            _SectionHeader(
              title: 'Waiting on you',
              subtitle: awaiting.isEmpty
                  ? 'No assistant has a basket waiting on you.'
                  : 'An assistant has prepared these. Nothing is bought until '
                        'you open one and confirm it.',
            ),
            for (final proposal in awaiting) ...[
              const SizedBox(height: DesignTokens.s12),
              _ProposalCard(proposal: proposal, nowUtc: now, clock: clock),
            ],

            // ── 2. Live mandates ──
            const SizedBox(height: DesignTokens.s24),
            const _SectionHeader(
              title: 'Assistants with a mandate',
              subtitle: AgentCommerceCopy.revocationPromise,
            ),
            if (state.loaded && active.isEmpty) ...[
              const SizedBox(height: DesignTokens.s12),
              const MallEmptyState(
                key: ValueKey('agent-no-mandates'),
                title: 'No assistant can act on your behalf',
                body:
                    'Nobody else’s software holds any authority on your '
                    'account right now.',
                icon: Icons.shield_outlined,
              ),
            ],
            for (final mandate in active) ...[
              const SizedBox(height: DesignTokens.s12),
              _MandateCard(
                mandate: mandate,
                nowUtc: now,
                revoking: state.revokingId == mandate.id,
                onRevoke: () => notifier.revoke(mandate),
              ),
            ],

            // ── 3. Ended mandates ──
            if (ended.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s24),
              const _SectionHeader(
                title: 'Mandates that have ended',
                subtitle:
                    'Revoked or expired. Kept so you can see what an '
                    'assistant once held.',
              ),
              for (final mandate in ended) ...[
                const SizedBox(height: DesignTokens.s12),
                _MandateCard(mandate: mandate, nowUtc: now, revoking: false),
              ],
            ],

            // ── 4. Activity, refusals included ──
            const SizedBox(height: DesignTokens.s24),
            const _SectionHeader(
              title: 'What your assistants did',
              subtitle:
                  'Everything they asked for, allowed and refused. A '
                  'refusal is the proof your limits are doing something, so '
                  'none are hidden.',
            ),
            if (state.loaded && state.activity.isEmpty) ...[
              const SizedBox(height: DesignTokens.s12),
              const MallEmptyState(
                key: ValueKey('agent-no-activity'),
                title: 'Nothing has happened yet',
                body:
                    'When an assistant reads your catalogue, fills a basket '
                    'or is refused, it appears here.',
                icon: Icons.receipt_long_outlined,
              ),
            ],
            for (final entry in state.activity) ...[
              const SizedBox(height: DesignTokens.s12),
              _ActivityRow(entry: entry),
            ],

            if (!state.loaded && state.loading) ...[
              const SizedBox(height: DesignTokens.s24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(header: true, child: Text(title, style: DesignTokens.h3)),
      if (subtitle != null) ...[
        const SizedBox(height: DesignTokens.s4),
        Text(subtitle!, style: DesignTokens.smallDescription),
      ],
    ],
  );
}

/// One assistant's authority, with every limit the backend enforces on show —
/// a cap the customer cannot see is not a limit they agreed to.
class _MandateCard extends StatelessWidget {
  const _MandateCard({
    required this.mandate,
    required this.nowUtc,
    required this.revoking,
    this.onRevoke,
  });

  final AgentMandate mandate;
  final DateTime nowUtc;
  final bool revoking;

  /// Null for a mandate that has already ended; there is nothing to withdraw.
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final state = mandate.effectiveStateAt(nowUtc);
    final scopes = mandate.scopes;
    final cap = AgentCommerceCopy.money(
      mandate.maxOrderAmount,
      mandate.currency,
    );
    final expiry = AgentCommerceCopy.date(mandate.expiresUtc);
    final expiryIn = AgentCommerceCopy.daysFromNow(mandate.expiresUtc, nowUtc);
    return Container(
      key: ValueKey('agent-mandate-card-${mandate.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  mandate.agentName.isEmpty
                      ? 'Unnamed assistant'
                      : mandate.agentName,
                  style: DesignTokens.mediumRegular.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              MallStatusPill(
                label: AgentCommerceCopy.mandateStateLabel(state),
                tone: AgentCommerceCopy.mandateStateTone(state),
                icon: AgentCommerceCopy.mandateStateIcon(state),
                semanticLabel:
                    'Mandate is ${AgentCommerceCopy.mandateStateLabel(state)}',
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),

          _Fact(
            icon: Icons.payments_outlined,
            label: 'Spending limit',
            value: '$cap per order, in ${mandate.currency} only',
          ),
          const SizedBox(height: 6),
          _Fact(
            icon: Icons.inventory_2_outlined,
            label: 'May buy',
            value: AgentCommerceCopy.allowlistSummary(
              mandate.allowedProductIds.length,
            ),
          ),
          const SizedBox(height: 6),
          _Fact(
            icon: Icons.event_busy_outlined,
            label: state == AgentMandateState.revoked
                ? 'Would have expired'
                : 'Expires',
            value: '$expiry ($expiryIn)',
          ),
          if (mandate.revokedUtc != null) ...[
            const SizedBox(height: 6),
            _Fact(
              icon: Icons.block_rounded,
              label: 'Revoked',
              value: AgentCommerceCopy.dateTime(mandate.revokedUtc!),
            ),
          ],

          const SizedBox(height: DesignTokens.s12),
          Text(
            'It may:',
            style: DesignTokens.smallDescription.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          if (scopes.isEmpty)
            const Text('Nothing at all.', style: DesignTokens.smallDescription)
          else
            for (final scope in AgentMandateScope.values)
              if (scopes.has(scope))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3, right: 6),
                        child: Icon(
                          AgentCommerceCopy.scopeIcon(scope),
                          size: 13,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          AgentCommerceCopy.scopeTitle(scope),
                          style: DesignTokens.smallDescription,
                        ),
                      ),
                    ],
                  ),
                ),
          if (scopes.hasUnrecognised) ...[
            const SizedBox(height: 4),
            Row(
              key: const ValueKey('agent-unrecognised-scopes'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3, right: 6),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 13,
                    color: DesignTokens.warning300,
                  ),
                ),
                Expanded(
                  child: Text(
                    AgentCommerceCopy.unrecognisedScopes(
                      scopes.unrecognisedCount,
                    ),
                    style: DesignTokens.smallDescription.copyWith(
                      color: DesignTokens.warning300,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (onRevoke != null && state == AgentMandateState.active) ...[
            const SizedBox(height: DesignTokens.s16),
            Semantics(
              container: true,
              button: true,
              enabled: !revoking,
              label:
                  'Revoke ${mandate.agentName}’s mandate now. '
                  '${AgentCommerceCopy.revocationPromise}',
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: ValueKey('agent-revoke-button-${mandate.id}'),
                  onPressed: revoking ? null : onRevoke,
                  icon: revoking
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Revoke this mandate now'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignTokens.colorError,
                    side: const BorderSide(color: DesignTokens.colorError),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A parked basket. Deliberately **no confirm button here**: the customer
/// opens it and reads it first, because confirming from a list would mean
/// agreeing to a charge they never saw.
class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.proposal,
    required this.nowUtc,
    this.clock,
  });

  final AgentProposal proposal;
  final DateTime nowUtc;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final statusLabel = AgentCommerceCopy.proposalStatusLabel(
      proposal.status,
      rawStatus: proposal.rawStatus,
    );
    final total = AgentCommerceCopy.money(
      proposal.quotedTotal,
      proposal.currency,
    );
    return Container(
      key: ValueKey('agent-proposal-card-${proposal.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.warning300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MallStatusPill(
            label: statusLabel,
            tone: AgentCommerceCopy.proposalStatusTone(proposal.status),
            icon: AgentCommerceCopy.proposalStatusIcon(proposal.status),
            semanticLabel: 'Basket status: $statusLabel',
            dense: true,
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            '${proposal.itemCount} item'
            '${proposal.itemCount == 1 ? '' : 's'} · $total',
            style: DesignTokens.mediumRegular.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Decide by ${AgentCommerceCopy.dateTime(proposal.expiresUtc)}.',
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s12),
          Semantics(
            container: true,
            button: true,
            label: 'Open this basket and read every line before deciding',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: ValueKey('agent-review-button-${proposal.id}'),
                onPressed: () => showAgentProposalSheet(
                  context,
                  proposal: proposal,
                  clock: clock,
                ),
                child: const Text('Review the basket'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One row of the ledger. A refusal reads as a refusal, by glyph and by word.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final AgentActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final outcome = AgentCommerceCopy.activityOutcome(allowed: entry.allowed);
    final reason = entry.allowed
        ? null
        : AgentCommerceCopy.refusalReason(entry.errorCode);
    final when = AgentCommerceCopy.dateTime(entry.recordedUtc);
    return Container(
      key: ValueKey('agent-activity-${entry.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Semantics(
        label:
            '$outcome. ${AgentCommerceCopy.activityAction(entry.action)}. '
            '${entry.agentName}. $when.'
            '${reason == null ? '' : ' $reason'}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    AgentCommerceCopy.activityAction(entry.action),
                    style: DesignTokens.mediumRegular.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                MallStatusPill(
                  label: outcome,
                  tone: AgentCommerceCopy.activityTone(allowed: entry.allowed),
                  icon: AgentCommerceCopy.activityIcon(allowed: entry.allowed),
                  dense: true,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.agentName.isEmpty ? 'An assistant' : entry.agentName} · '
              '${AgentCommerceCopy.dateTime(entry.recordedUtc)}',
              style: DesignTokens.smallDescription,
            ),
            if (reason != null) ...[
              const SizedBox(height: 4),
              Text(
                reason,
                key: ValueKey('agent-activity-reason-${entry.id}'),
                style: DesignTokens.smallDescription.copyWith(
                  color: DesignTokens.colorError,
                ),
              ),
            ],
            if (entry.detail != null) ...[
              const SizedBox(height: 4),
              Text(entry.detail!, style: DesignTokens.smallDescription),
            ],
          ],
        ),
      ),
    );
  }
}

class _RevokedConfirmation extends StatelessWidget {
  const _RevokedConfirmation({
    required this.agentName,
    required this.onDismiss,
  });

  final String agentName;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('agent-revoked-confirmation'),
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.primaryGreenDark,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Semantics(
      liveRegion: true,
      label:
          '$agentName can no longer act on your behalf. '
          '${AgentCommerceCopy.revocationPromise}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.block_rounded,
                size: 18,
                color: DesignTokens.primaryGreen,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  '$agentName can no longer act on your behalf.',
                  style: DesignTokens.mediumRegular.copyWith(
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            AgentCommerceCopy.revocationPromise,
            style: DesignTokens.smallDescription,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onDismiss,
              child: const Text('Got it'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QuietLoadFailure extends StatelessWidget {
  const _QuietLoadFailure();

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('agent-load-failure'),
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Semantics(
      liveRegion: true,
      child: const Text(
        'This list did not load, so it may be out of date. Pull down to try '
        'again — nothing here has changed.',
        style: DesignTokens.smallDescription,
      ),
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '$label: $value',
    excludeSemantics: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DesignTokens.smallDescription,
              children: [
                TextSpan(
                  text: '$label  ',
                  style: DesignTokens.smallDescription.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
