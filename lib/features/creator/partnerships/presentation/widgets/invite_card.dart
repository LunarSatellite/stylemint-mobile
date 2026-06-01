import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class InviteCard extends StatelessWidget {
  const InviteCard({
    super.key,
    required this.invite,
    required this.onAccept,
    required this.onDecline,
  });

  final PartnershipInvite invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final isExpired = invite.expiresAt.isBefore(DateTime.now());
    final isPending = invite.status == PartnershipStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: isPending && !isExpired
            ? Border.all(
                color: DesignTokens.primaryGreen.withValues(alpha: 0.3),
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(invite.vendorLogoUrl),
                backgroundColor: DesignTokens.bgAppBodyLight,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invite.vendorName, style: DesignTokens.oneLinerSemibold),
                    Text(
                      '${(invite.commissionRate * 100).toStringAsFixed(0)}% commission',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPending || isExpired)
                _StatusBadge(status: invite.status, isExpired: isExpired),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(invite.campaignBrief, style: DesignTokens.mediumRegular),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Expires ${_formatDate(invite.expiresAt)}',
            style: DesignTokens.tiny.copyWith(
              color: isExpired ? DesignTokens.colorError : DesignTokens.textMuted,
            ),
          ),
          if (isPending && !isExpired) ...[
            const SizedBox(height: DesignTokens.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onDecline,
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.textMuted,
                  ),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: DesignTokens.s8),
                ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    foregroundColor: DesignTokens.textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.buttonRadius,
                      ),
                    ),
                  ),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.isExpired});

  final PartnershipStatus status;
  final bool isExpired;

  @override
  Widget build(BuildContext context) {
    if (isExpired && status == PartnershipStatus.pending) {
      return _badge('Expired', DesignTokens.colorError);
    }
    return switch (status) {
      PartnershipStatus.accepted => _badge('Accepted', DesignTokens.primaryGreen),
      PartnershipStatus.declined => _badge('Declined', DesignTokens.textMuted),
      PartnershipStatus.active => _badge('Active', DesignTokens.primaryGreen),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(
        label,
        style: DesignTokens.tiny.copyWith(color: color),
      ),
    );
  }
}
