import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TemplateCard extends StatelessWidget {
  const TemplateCard({super.key, required this.template});

  final CampaignTemplate template;

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
                  template.title,
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
                  borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
                ),
                child: Text(
                  '${template.recommendedCommission.toStringAsFixed(0)}%',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s6),
          Text(
            template.description,
            style: DesignTokens.smallRegular,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: DesignTokens.warning500),
              const SizedBox(width: DesignTokens.s4),
              Expanded(
                child: Text(
                  template.tips.firstOrNull ?? '',
                  style: DesignTokens.tiny,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          MoneyText(
            template.recommendedBudget,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
