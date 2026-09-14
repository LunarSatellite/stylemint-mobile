import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/audience_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Followers and engagement rate imported from the connected platforms.
/// Nothing here is typed in by the creator.
class AudienceSummaryCard extends StatelessWidget {
  const AudienceSummaryCard({super.key, required this.summary});

  final AudienceSummary summary;

  @override
  Widget build(BuildContext context) {
    final usesViews = summary.platforms
        .where((p) => p.engagementBasis == 'views')
        .map((p) => p.platform.displayName)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Audience', style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'From your connected platforms. Updates when you refresh.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Total followers',
                  value: _count(summary.totalFollowers),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: _Stat(
                  label: 'Avg. engagement rate',
                  value: _rate(summary.averageEngagementRatePercent),
                ),
              ),
            ],
          ),
          if (summary.platforms.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s16),
            const Divider(height: 1, color: DesignTokens.borderDefault),
            const SizedBox(height: DesignTokens.s8),
            for (final p in summary.platforms) _PlatformRow(row: p),
          ],
          if (usesViews.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              '${usesViews.join(' and ')} ${usesViews.length == 1 ? "doesn't" : "don't"} '
              'share follower counts, so the rate there is based on views.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: DesignTokens.titleLarge),
        const SizedBox(height: DesignTokens.s4),
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}

class _PlatformRow extends StatelessWidget {
  const _PlatformRow({required this.row});

  final PlatformAudience row;

  @override
  Widget build(BuildContext context) {
    final followers = row.followerCount == null
        ? 'Followers not shared'
        : '${_count(row.followerCount)} followers';
    final rate = row.engagementRatePercent == null
        ? 'no post stats yet'
        : '${_rate(row.engagementRatePercent)} engagement';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s6),
      child: Row(
        children: [
          Icon(row.platform.icon, size: 18, color: row.platform.color),
          const SizedBox(width: DesignTokens.s8),
          Text(row.platform.displayName, style: DesignTokens.oneLinerSemibold),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              '$followers · $rate',
              textAlign: TextAlign.end,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _count(int? value) {
  if (value == null) return '—';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String _rate(double? value) =>
    value == null ? '—' : '${value.toStringAsFixed(value >= 10 ? 1 : 2)}%';
