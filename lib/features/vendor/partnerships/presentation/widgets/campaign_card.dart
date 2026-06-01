import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CampaignCard extends StatelessWidget {
  const CampaignCard({super.key, required this.campaign, required this.onTap});

  final CampaignBrief campaign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.s12),
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    campaign.title,
                    style: DesignTokens.oneLinerSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                _CommissionBadge(rate: campaign.commissionRate),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              campaign.description,
              style: DesignTokens.smallRegular,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                MoneyText(
                  campaign.budget,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Text('budget', style: DesignTokens.tiny),
                const Spacer(),
                _StatusBadge(status: campaign.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionBadge extends StatelessWidget {
  const _CommissionBadge({required this.rate});

  final double rate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(
        '${rate.toStringAsFixed(0)}%',
        style: DesignTokens.tiny.copyWith(color: DesignTokens.primaryGreen),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final CampaignStatus status;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (status) {
      CampaignStatus.active => ('Active', DesignTokens.primaryGreen),
      CampaignStatus.draft => ('Draft', DesignTokens.textMuted),
      CampaignStatus.paused => ('Paused', DesignTokens.warning500),
      CampaignStatus.completed => ('Completed', DesignTokens.colorInfo),
    };

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
