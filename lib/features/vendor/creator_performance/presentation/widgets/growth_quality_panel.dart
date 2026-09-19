// This file keeps explicit evidence wording visible for merchant trust review.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final growthQualityProvider = FutureProvider.autoDispose
    .family<GrowthQualityBoard, int>((ref, days) async {
      final result = await ref
          .watch(apiClientProvider)
          .get(
            '/api/v1/vendor/growth-quality',
            queryParameters: {'days': days},
          );
      return GrowthQualityBoard.fromJson(result as Map<String, dynamic>);
    });

class GrowthQualityBoard {
  const GrowthQualityBoard({
    required this.activePartnerships,
    required this.attributedRevenue,
    required this.affiliateConversions,
    required this.evidencePolicy,
    required this.creators,
  });
  factory GrowthQualityBoard.fromJson(Map<String, dynamic> json) =>
      GrowthQualityBoard(
        activePartnerships: (json['activePartnerships'] as num?)?.toInt() ?? 0,
        attributedRevenue: (json['attributedRevenue'] as num?)?.toDouble() ?? 0,
        affiliateConversions:
            (json['affiliateConversions'] as num?)?.toInt() ?? 0,
        evidencePolicy: json['evidencePolicy']?.toString() ?? '',
        creators: (json['creators'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(GrowthQualityCreator.fromJson)
            .toList(growable: false),
      );
  final int activePartnerships;
  final double attributedRevenue;
  final int affiliateConversions;
  final String evidencePolicy;
  final List<GrowthQualityCreator> creators;
}

class GrowthQualityCreator {
  const GrowthQualityCreator({
    required this.creatorId,
    required this.score,
    required this.recommendation,
    required this.revenue,
    required this.conversions,
    required this.communityReactions,
    required this.riskSignals,
  });
  factory GrowthQualityCreator.fromJson(Map<String, dynamic> json) =>
      GrowthQualityCreator(
        creatorId: json['creatorId']?.toString() ?? '',
        score: (json['qualityScore'] as num?)?.toInt() ?? 0,
        recommendation:
            json['recommendation']?.toString() ?? 'observe_before_spend',
        revenue: (json['attributedRevenue'] as num?)?.toDouble() ?? 0,
        conversions: (json['affiliateConversions'] as num?)?.toInt() ?? 0,
        communityReactions: (json['communityReactions'] as num?)?.toInt() ?? 0,
        riskSignals: (json['qualityRiskSignals'] as num?)?.toInt() ?? 0,
      );
  final String creatorId;
  final int score;
  final String recommendation;
  final double revenue;
  final int conversions;
  final int communityReactions;
  final int riskSignals;

  String get action => switch (recommendation) {
    'scale_partnership' => 'Scale this partnership',
    'coach_and_test' => 'Coach, then run another test',
    'review_quality_risk' => 'Review quality risk before spend',
    _ => 'Observe before increasing spend',
  };
}

class GrowthQualityPanel extends ConsumerStatefulWidget {
  const GrowthQualityPanel({required this.days, super.key});
  final int days;
  static const loadKey = ValueKey<String>('growth-quality-load');

  @override
  ConsumerState<GrowthQualityPanel> createState() => _GrowthQualityPanelState();
}

class _GrowthQualityPanelState extends ConsumerState<GrowthQualityPanel> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: _Shell(
          child: Row(
            children: [
              const _OrbitIcon(),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Growth quality',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Connect community energy to verified sales',
                      style: TextStyle(
                        color: DesignTokens.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: GrowthQualityPanel.loadKey,
                onPressed: () => setState(() => expanded = true),
                icon: const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFF67F5C7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: ref
          .watch(growthQualityProvider(widget.days))
          .when(
            loading: () =>
                const _Shell(child: Center(child: CircularProgressIndicator())),
            error: (_, _) => _Shell(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Growth evidence is unavailable right now.',
                      style: TextStyle(color: DesignTokens.textLight),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(growthQualityProvider(widget.days)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (board) => _Shell(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _OrbitIcon(),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Growth quality board',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => expanded = false),
                        icon: const Icon(
                          Icons.expand_less_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Active',
                          value: '${board.activePartnerships}',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: 'Revenue',
                          value:
                              'NPR ${board.attributedRevenue.toStringAsFixed(0)}',
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: 'Conversions',
                          value: '${board.affiliateConversions}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (board.creators.isEmpty)
                    const Text(
                      'No linked growth evidence in this window yet.',
                      style: TextStyle(color: DesignTokens.textLight),
                    )
                  else
                    for (final creator in board.creators.take(3)) ...[
                      _CreatorDecision(creator: creator),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 6),
                  Text(
                    board.evidencePolicy,
                    style: const TextStyle(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 72),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF132A2A), Color(0xFF171F33)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF67F5C7).withValues(alpha: .18)),
    ),
    child: child,
  );
}

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon();
  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF67F5C7).withValues(alpha: .12),
    ),
    child: const Icon(Icons.hub_outlined, color: Color(0xFF67F5C7)),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: DesignTokens.textMuted, fontSize: 10),
      ),
      const SizedBox(height: 3),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class _CreatorDecision extends StatelessWidget {
  const _CreatorDecision({required this.creator});
  final GrowthQualityCreator creator;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _color.withValues(alpha: .15),
          ),
          child: Text(
            '${creator.score}',
            style: TextStyle(color: _color, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                creator.action,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'NPR ${creator.revenue.toStringAsFixed(0)} • ${creator.conversions} conversions • ${creator.communityReactions} reactions',
                style: const TextStyle(
                  color: DesignTokens.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (creator.riskSignals > 0)
          const Icon(Icons.shield_outlined, color: Color(0xFFFFB36B), size: 18),
      ],
    ),
  );
  Color get _color => creator.riskSignals > 0
      ? const Color(0xFFFFB36B)
      : const Color(0xFF67F5C7);
}
