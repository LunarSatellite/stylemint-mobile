import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_copy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/handover_delegation_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Can't be there when it arrives?" — delegated parcel handover, on the
/// parcel the customer is already looking at.
///
/// Creation and management both live here, on the order detail screen, rather
/// than behind a settings destination the customer would have to go and find.
/// A person who needs this needs it about *this* parcel, now.
///
/// Draws nothing until the first read completes and nothing at all for a
/// delivered/returned parcel with no history.
class HandoverDelegationCard extends ConsumerStatefulWidget {
  const HandoverDelegationCard({
    required this.trackingNumber,
    super.key,
    this.canDelegate = true,
    this.clock,
  });

  final String trackingNumber;

  /// False once the parcel is delivered, returning or returned — the backend
  /// refuses a new delegation then, so the button is not offered. Existing
  /// history still renders.
  final bool canDelegate;

  final DateTime Function()? clock;

  @override
  ConsumerState<HandoverDelegationCard> createState() =>
      _HandoverDelegationCardState();
}

class _HandoverDelegationCardState
    extends ConsumerState<HandoverDelegationCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref
            .read(
              handoverDelegationNotifierProvider(
                widget.trackingNumber,
              ).notifier,
            )
            .load(),
      );
    });
  }

  DateTime _now() => widget.clock?.call() ?? DateTime.now().toUtc();

  @override
  Widget build(BuildContext context) {
    final provider = handoverDelegationNotifierProvider(widget.trackingNumber);
    final state = ref.watch(provider);
    final now = _now();

    // Nothing while the first read is in flight, and nothing at all if that
    // read failed with no delegations to show: this card appears unprompted,
    // so a network error is not the customer's problem to look at.
    if (!state.loaded) return const SizedBox.shrink();

    final active = state.activeAt(now);
    final history = state.historyAt(now);
    if (active == null && history.isEmpty) {
      if (!widget.canDelegate || state.loadFailed) {
        return const SizedBox.shrink();
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Container(
        key: const ValueKey('handover-delegation-card'),
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: const Text(
                "Can't be there when it arrives?",
                style: DesignTokens.h3,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              active == null
                  ? 'Authorise one person to take this parcel for '
                        'you, inside a time window you set. You can '
                        'withdraw it at any moment.'
                  : 'One person is authorised to take this parcel for you.',
              style: DesignTokens.mediumRegular,
            ),
            if (state.failure != null) ...[
              const SizedBox(height: DesignTokens.s12),
              HandoverRefusalNotice(
                errorCode: state.failure!,
                onDismiss: ref.read(provider.notifier).dismissFailure,
              ),
            ],
            if (state.lastRevoked != null) ...[
              const SizedBox(height: DesignTokens.s12),
              _RevokedConfirmation(
                delegation: state.lastRevoked!,
                onDismiss: ref.read(provider.notifier).dismissRevokedNotice,
              ),
            ],
            if (active != null) ...[
              const SizedBox(height: DesignTokens.s16),
              _ActiveDelegation(
                delegation: active,
                nowUtc: now,
                revoking: state.revokingId == active.id,
                onRevoke: () => ref.read(provider.notifier).revoke(active.id),
              ),
            ] else if (widget.canDelegate) ...[
              const SizedBox(height: DesignTokens.s16),
              Semantics(
                button: true,
                label: 'Authorise someone to receive this parcel for you',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const ValueKey('handover-start-button'),
                    onPressed: () => showHandoverDelegationSheet(
                      context,
                      trackingNumber: widget.trackingNumber,
                      clock: widget.clock,
                    ),
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Authorise someone to receive it'),
                  ),
                ),
              ),
            ],
            if (history.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s16),
              const Divider(height: 1, color: DesignTokens.bgAppBodyLight),
              const SizedBox(height: DesignTokens.s12),
              Semantics(
                header: true,
                child: Text(
                  'Earlier authorisations',
                  style: DesignTokens.mediumRegular.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              for (final d in history) ...[
                _HistoryRow(delegation: d, nowUtc: now),
                const SizedBox(height: DesignTokens.s12),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// The live authorisation, with revocation one tap away.
class _ActiveDelegation extends StatelessWidget {
  const _ActiveDelegation({
    required this.delegation,
    required this.nowUtc,
    required this.revoking,
    required this.onRevoke,
  });

  final HandoverDelegation delegation;
  final DateTime nowUtc;
  final bool revoking;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final status = delegation.effectiveStatusAt(nowUtc);
    return Container(
      key: const ValueKey('handover-active-delegation'),
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and status wrap rather than sitting in a Row, so a long name
          // at 1.3x text scale on a 320dp screen pushes down, never sideways.
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: DesignTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                delegation.delegateDisplayName,
                style: DesignTokens.mediumRegular.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            HandoverCopy.relationship(delegation.relationship),
            style: DesignTokens.smallDescription,
          ),
          const SizedBox(height: DesignTokens.s12),
          _Fact(
            icon: Icons.schedule_rounded,
            label: 'Window',
            value: HandoverCopy.windowSentence(
              delegation.windowStartUtc,
              delegation.windowEndUtc,
            ),
          ),
          const SizedBox(height: 6),
          _Fact(
            icon: delegation.isPendingAt(nowUtc)
                ? Icons.hourglass_empty_rounded
                : Icons.lock_open_rounded,
            label: 'Right now',
            value: HandoverCopy.activeWindowState(delegation, nowUtc),
          ),
          const SizedBox(height: 6),
          _Fact(
            icon: Icons.rule_rounded,
            label: 'May accept',
            value: HandoverCopy.exceptionSummary(delegation.allowedExceptions),
          ),
          const SizedBox(height: DesignTokens.s12),
          // The escape hatch. One tap, no confirmation dialog: a customer who
          // was pressured into creating this must be able to undo it without a
          // second screen they would have to explain to whoever is watching.
          // Revoking is always the safe direction, so nothing guards it.
          Semantics(
            button: true,
            enabled: !revoking,
            label:
                'Revoke now. ${delegation.delegateDisplayName} will no longer '
                'be able to take this parcel.',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('handover-revoke-button'),
                onPressed: revoking ? null : onRevoke,
                style: OutlinedButton.styleFrom(
                  foregroundColor: DesignTokens.colorError,
                  side: const BorderSide(color: DesignTokens.colorError),
                ),
                icon: revoking
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.block_rounded, size: 18),
                label: const Text('Revoke now'),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Takes effect immediately — even if the courier is already at the '
            'door.',
            style: DesignTokens.smallDescription,
          ),
        ],
      ),
    );
  }
}

/// A finished authorisation. Read-only, and honest about which of the four
/// states it ended in.
class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.delegation, required this.nowUtc});

  final HandoverDelegation delegation;
  final DateTime nowUtc;

  @override
  Widget build(BuildContext context) {
    final status = delegation.effectiveStatusAt(nowUtc);
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: DesignTokens.s8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                delegation.delegateDisplayName,
                style: DesignTokens.mediumRegular,
              ),
              _StatusPill(status: status, dense: true),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            HandoverCopy.windowSentence(
              delegation.windowStartUtc,
              delegation.windowEndUtc,
            ),
            style: DesignTokens.smallDescription,
          ),
          if (delegation.revocationReason case final reason?
              when reason.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Reason: $reason',
              style: DesignTokens.smallDescription,
            ),
          ],
        ],
      ),
    );
  }
}

/// Shown for one beat after a successful revoke, so the escape hatch visibly
/// worked rather than the row just quietly changing colour.
class _RevokedConfirmation extends StatelessWidget {
  const _RevokedConfirmation({
    required this.delegation,
    required this.onDismiss,
  });

  final HandoverDelegation delegation;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('handover-revoked-confirmation'),
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Semantics(
      liveRegion: true,
      label:
          'Revoked. ${delegation.delegateDisplayName} can no longer take this '
          'parcel, and their code no longer works.',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              'Revoked. ${delegation.delegateDisplayName} can no longer take '
              'this parcel, and their code no longer works.',
              style: DesignTokens.mediumRegular,
            ),
          ),
          TextButton(onPressed: onDismiss, child: const Text('OK')),
        ],
      ),
    ),
  );
}

/// Mall kit pill. Tone *and* glyph differ per status, so the four states are
/// told apart without colour — see [HandoverCopy.statusTone].
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, this.dense = false});

  final HandoverDelegationStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) => MallStatusPill(
    label: HandoverCopy.statusLabel(status),
    tone: HandoverCopy.statusTone(status),
    icon: switch (status) {
      HandoverDelegationStatus.active => Icons.lock_open_rounded,
      HandoverDelegationStatus.consumed => Icons.check_circle_outline_rounded,
      HandoverDelegationStatus.revoked => Icons.block_rounded,
      HandoverDelegationStatus.expired => Icons.timer_off_outlined,
      HandoverDelegationStatus.unknown => Icons.help_outline_rounded,
    },
    semanticLabel: HandoverCopy.statusSemantics(status),
    dense: dense,
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
        Icon(icon, size: 15, color: DesignTokens.textMuted),
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
