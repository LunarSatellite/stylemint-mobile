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
                    campaign.title?.isNotEmpty == true
                        ? campaign.title!
                        : 'Untitled brief',
                    style: DesignTokens.oneLinerSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                _CommissionBadge(
                  minPercent: campaign.commissionMinPercent,
                  maxPercent: campaign.commissionMaxPercent,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            Row(
              children: [
                MoneyText(
                  campaign.boostBudget,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Text('boost budget', style: DesignTokens.tiny),
                const Spacer(),
                _StatusBadge(state: campaign.state),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionBadge extends StatelessWidget {
  const _CommissionBadge({required this.minPercent, required this.maxPercent});

  final double minPercent;
  final double maxPercent;

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
        '${(minPercent * 100).toStringAsFixed(0)}-${(maxPercent * 100).toStringAsFixed(0)}%',
        style: DesignTokens.tiny.copyWith(color: DesignTokens.primaryGreen),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final BrandBriefState state;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (state) {
      BrandBriefState.draft => ('Draft', DesignTokens.textMuted),
      BrandBriefState.locked => ('Locked', DesignTokens.primaryGreen),
      BrandBriefState.retired => ('Retired', DesignTokens.colorInfo),
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
