import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final MarketInsight insight;

  @override
  Widget build(BuildContext context) {
    final competitionColor = switch (insight.competitionLevel) {
      CompetitionLevel.low => DesignTokens.primaryGreen,
      CompetitionLevel.medium => DesignTokens.warning500,
      CompetitionLevel.high => DesignTokens.colorError,
    };

    return Container(
      width: 200,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(insight.category, style: DesignTokens.mediumSemibold),
              const Spacer(),
              if (insight.trending)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s6,
                    vertical: DesignTokens.s4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.trending_up,
                        size: 12,
                        color: DesignTokens.primaryGreen,
                      ),
                      const SizedBox(width: DesignTokens.s4),
                      Text(
                        'Trending',
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Avg Commission: ${insight.averageCommission.toStringAsFixed(0)}%',
            style: DesignTokens.smallRegular,
          ),
          const SizedBox(height: DesignTokens.s4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: competitionColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: DesignTokens.s6),
              Text(
                '${insight.competitionLevel.name} competition',
                style: DesignTokens.tiny.copyWith(color: competitionColor),
              ),
            ],
          ),
          const Spacer(),
          Text(
            insight.recommendedActions.firstOrNull ?? '',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.colorInfo),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
