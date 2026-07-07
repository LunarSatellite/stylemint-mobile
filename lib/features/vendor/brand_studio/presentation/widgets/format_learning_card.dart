import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FormatLearningCard extends StatelessWidget {
  const FormatLearningCard({required this.learning, super.key});

  final FormatLearning learning;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  learning.formatLabel,
                  style: DesignTokens.mediumSemibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s6,
                  vertical: DesignTokens.s4,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(
                    DesignTokens.chipRadius,
                  ),
                ),
                child: Text(
                  '${learning.count}',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Completion ${learning.avgCompletionRate.toStringAsFixed(0)}% '
            '· Conversion ${learning.avgConversionRate.toStringAsFixed(1)}%',
            style: DesignTokens.smallRegular,
          ),
          const Spacer(),
          Text(
            learning.takeaway,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.colorInfo),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
