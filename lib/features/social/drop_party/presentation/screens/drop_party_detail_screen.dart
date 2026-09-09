import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/notifiers/drop_party_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class DropPartyDetailScreen extends ConsumerWidget {
  const DropPartyDetailScreen({super.key, required this.partyId});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dropPartyDetailNotifierProvider(partyId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Drop Party', style: DesignTokens.sectionInnerTitle),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (_) => _Failure(
          onRetry: () => ref
              .read(dropPartyDetailNotifierProvider(partyId).notifier)
              .loadParty(partyId),
        ),
        loadSuccess: (party) => _Content(party: party, partyId: partyId),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _Content extends ConsumerWidget {
  const _Content({required this.party, required this.partyId});

  final DropParty party;
  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = switch (party.status) {
      DropPartyStatus.scheduled => 'RSVP',
      DropPartyStatus.live => 'Join live party',
      DropPartyStatus.ended => 'Ended',
      DropPartyStatus.cancelled => 'Cancelled',
    };
    final enabled =
        party.status == DropPartyStatus.scheduled ||
        party.status == DropPartyStatus.live;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        _StatusHeader(status: party.status),
        const SizedBox(height: DesignTokens.s16),
        Text(party.title, style: DesignTokens.titleMedium),
        const SizedBox(height: DesignTokens.s8),
        Text(party.description, style: DesignTokens.bodyText),
        const SizedBox(height: DesignTokens.s24),
        _InfoRow(
          icon: Icons.schedule_rounded,
          label: 'Starts',
          value: DateFormat('EEEE, MMM d · h:mm a').format(party.startsAt),
        ),
        _InfoRow(
          icon: Icons.timer_outlined,
          label: 'Duration',
          value: '${party.duration.inMinutes} minutes',
        ),
        _InfoRow(
          icon: Icons.people_outline_rounded,
          label: 'Attendees',
          value: '${party.attendeeCount}',
        ),
        if (party.reelIsOrphaned)
          const Padding(
            padding: EdgeInsets.only(top: DesignTokens.s12),
            child: Text(
              'The linked reel is no longer available.',
              style: DesignTokens.smallRegular,
            ),
          ),
        if (party.cancellationReason?.trim().isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s12),
            child: Text(
              'Cancellation reason: ${party.cancellationReason}',
              style: DesignTokens.smallRegular,
            ),
          ),
        const SizedBox(height: DesignTokens.s24),
        SizedBox(
          height: DesignTokens.buttonHeight,
          child: ElevatedButton(
            onPressed: enabled ? () => _participate(context, ref) : null,
            style: DesignTokens.primaryButtonStyle(),
            child: Text(action),
          ),
        ),
        const SizedBox(height: DesignTokens.s24),
        _InviteCode(party: party),
      ],
    );
  }

  Future<void> _participate(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(
      dropPartyDetailNotifierProvider(partyId).notifier,
    );
    final result = party.status == DropPartyStatus.live
        ? await notifier.joinLive(partyId)
        : await notifier.rsvp(partyId);
    if (!context.mounted) return;
    result.fold(
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update your party attendance.'),
        ),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            party.status == DropPartyStatus.live
                ? 'Joined live party.'
                : 'RSVP confirmed.',
          ),
        ),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.status});

  final DropPartyStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      DropPartyStatus.scheduled => 'Scheduled',
      DropPartyStatus.live => 'Live now',
      DropPartyStatus.ended => 'Ended',
      DropPartyStatus.cancelled => 'Cancelled',
    };
    return Text(
      label.toUpperCase(),
      style: DesignTokens.smallRegular.copyWith(
        color: DesignTokens.primaryGreen,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
    child: Row(
      children: [
        Icon(icon, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s12),
        Expanded(child: Text(label, style: DesignTokens.smallRegular)),
        Text(
          value,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    ),
  );
}

class _InviteCode extends StatelessWidget {
  const _InviteCode({required this.party});

  final DropParty party;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: DesignTokens.cardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Invite code', style: DesignTokens.oneLinerSemibold),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            Expanded(
              child: Text(party.joinCode, style: DesignTokens.titleMedium),
            ),
            IconButton(
              tooltip: 'Copy code',
              icon: const Icon(Icons.copy, color: DesignTokens.primaryGreen),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: party.joinCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite code copied.')),
                );
              },
            ),
            IconButton(
              tooltip: 'Share invite',
              icon: const Icon(Icons.share, color: DesignTokens.primaryGreen),
              onPressed: () => unawaited(
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Join "${party.title}" on Style Mint with code ${party.joinCode}.',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
  );
}
