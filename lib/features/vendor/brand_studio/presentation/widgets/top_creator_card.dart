import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TopCreatorCard extends StatelessWidget {
  const TopCreatorCard({required this.creator, super.key});

  final TopCreatorByAttributedSales creator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  creator.creatorAccountId,
                  style: DesignTokens.mediumSemibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s8,
                  vertical: DesignTokens.s4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.chipRadius,
                  ),
                ),
                child: Text(
                  '${creator.roiRatio.toStringAsFixed(1)}x ROI',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s6),
          Text(
            '${creator.reelsInWindow} reels · ${creator.attributedUnitsSold} units sold',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              Expanded(
                child: MoneyText(
                  creator.attributedRevenue,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
              Text(
                'commission ',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              MoneyText(
                creator.commissionPaid,
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
