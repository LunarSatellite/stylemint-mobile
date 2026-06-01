import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/reach/domain/entities/reach.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class BoostCampaignCard extends StatelessWidget {
  const BoostCampaignCard({super.key, required this.campaign});

  final BoostCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final progress =
        campaign.budget.amount > 0
            ? campaign.spentAmount.amount / campaign.budget.amount
            : 0.0;

    final Color statusColor = switch (campaign.status) {
      BoostStatus.active => DesignTokens.primaryGreen,
      BoostStatus.paused => DesignTokens.warning500,
      BoostStatus.completed => DesignTokens.textMuted,
      BoostStatus.rejected => DesignTokens.colorError,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(campaign.platform.icon, color: campaign.platform.color, size: 20),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  campaign.platform.displayName,
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              _StatusBadge(label: campaign.status.name, color: statusColor),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Metric(label: 'Budget', value: campaign.budget),
              _Metric(label: 'Spent', value: campaign.spentAmount),
              _Metric(
                label: 'Impress.',
                value: _formatCount(campaign.impressions),
              ),
              _Metric(label: 'Clicks', value: _formatCount(campaign.clicks)),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: DesignTokens.bgAppBodyLight,
              valueColor: AlwaysStoppedAnimation(statusColor),
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of budget spent',
            style: DesignTokens.tiny,
          ),
          if (campaign.endAt != null) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Ends ${campaign.endAt!.year}-${campaign.endAt!.month.toString().padLeft(2, '0')}-${campaign.endAt!.day.toString().padLeft(2, '0')}',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final val = value;
    return Column(
      children: [
        if (val is Money)
          MoneyText(val, style: DesignTokens.smallRegular)
        else
          Text(value.toString(), style: DesignTokens.smallRegular),
        const SizedBox(height: DesignTokens.s4),
        Text(label, style: DesignTokens.tiny),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
        label.capitalize(),
        style: DesignTokens.tiny.copyWith(color: color),
      ),
    );
  }
}

extension _StringX on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
