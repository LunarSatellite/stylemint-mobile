import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CoachingScoreCard extends StatelessWidget {
  const CoachingScoreCard({
    super.key,
    required this.overallScore,
    required this.areas,
    required this.suggestions,
  });

  final double overallScore;
  final List<FeedbackArea> areas;
  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    final scorePercent = (overallScore * 100).round();
    final Color scoreColor = overallScore >= 0.7
        ? DesignTokens.primaryGreen
        : overallScore >= 0.4
        ? DesignTokens.warning500
        : DesignTokens.colorError;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.coffee, color: DesignTokens.warning500, size: 20),
              const SizedBox(width: DesignTokens.s8),
              Text('AI Coaching', style: DesignTokens.h3),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: overallScore,
                    strokeWidth: 6,
                    backgroundColor: DesignTokens.bgAppBodyLight,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                  ),
                  Center(
                    child: Text(
                      '$scorePercent%',
                      style: DesignTokens.oneLinerSemibold.copyWith(
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          ...areas.map((area) => _AreaBar(area: area)),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            const Divider(color: DesignTokens.borderDefault),
            const SizedBox(height: DesignTokens.s8),
            Text('Suggestions', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline,
                        color: DesignTokens.warning500, size: 16),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: Text(s, style: DesignTokens.smallRegular),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AreaBar extends StatelessWidget {
  const _AreaBar({required this.area});

  final FeedbackArea area;

  @override
  Widget build(BuildContext context) {
    final Color barColor = area.score >= 0.7
        ? DesignTokens.primaryGreen
        : area.score >= 0.4
        ? DesignTokens.warning500
        : DesignTokens.colorError;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(area.label, style: DesignTokens.smallRegular),
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s4),
              child: LinearProgressIndicator(
                value: area.score,
                minHeight: 6,
                backgroundColor: DesignTokens.bgAppBodyLight,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          SizedBox(
            width: 36,
            child: Text(
              '${(area.score * 100).round()}%',
              style: DesignTokens.tiny,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
