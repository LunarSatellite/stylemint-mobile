import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/entities/drop_party.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/screens/drop_party_detail_screen.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class DropPartyCard extends StatelessWidget {
  const DropPartyCard({super.key, required this.party});

  final DropParty party;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DropPartyDetailScreen(partyId: party.id),
      ),
    ),
    borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    child: Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusChip(status: party.status),
              const Spacer(),
              Icon(
                Icons.people_outline_rounded,
                color: DesignTokens.textMuted,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text('${party.attendeeCount}', style: DesignTokens.smallRegular),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          Text(
            party.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s6),
          Text(
            party.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('EEE, MMM d · h:mm a').format(party.startsAt),
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: 2),
          Text(
            '${party.duration.inMinutes} min event',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DropPartyStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      DropPartyStatus.live => ('LIVE', DesignTokens.colorError),
      DropPartyStatus.scheduled => ('SCHEDULED', DesignTokens.colorInfo),
      DropPartyStatus.ended => ('ENDED', DesignTokens.textMuted),
      DropPartyStatus.cancelled => ('CANCELLED', DesignTokens.colorWarning),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8,
          vertical: DesignTokens.s4,
        ),
        child: Text(
          label,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textWhite),
        ),
      ),
    );
  }
}
