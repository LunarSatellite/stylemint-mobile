// Decision copy intentionally stays explicit for merchant trust review.
// ignore_for_file: lines_longer_than_80_chars, sort_constructors_first, specify_nonobvious_property_types

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final intentDecisionBoardProvider = FutureProvider.autoDispose
    .family<IntentDecisionBoard, int>((ref, days) async {
      final response = await ref
          .watch(apiClientProvider)
          .get(
            '/api/v1/vendor/intent-decision-board',
            queryParameters: {'days': days, 'limit': 20},
          );
      return IntentDecisionBoard.fromJson(response as Map<String, dynamic>);
    });

class IntentDecisionBoard {
  const IntentDecisionBoard({
    required this.governance,
    required this.channels,
    required this.opportunities,
  });
  final String governance;
  final List<IntentChannelSummary> channels;
  final List<IntentOpportunity> opportunities;
  factory IntentDecisionBoard.fromJson(Map<String, dynamic> json) =>
      IntentDecisionBoard(
        governance: json['governance'] as String? ?? '',
        channels: (json['channels'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(IntentChannelSummary.fromJson)
            .toList(growable: false),
        opportunities: (json['opportunities'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(IntentOpportunity.fromJson)
            .toList(growable: false),
      );
}

class IntentChannelSummary {
  const IntentChannelSummary({
    required this.channel,
    required this.signalCount,
    required this.knownShopperCount,
  });
  final String channel;
  final int signalCount;
  final int knownShopperCount;
  factory IntentChannelSummary.fromJson(Map<String, dynamic> json) =>
      IntentChannelSummary(
        channel: json['channel']?.toString() ?? '',
        signalCount: (json['signalCount'] as num?)?.toInt() ?? 0,
        knownShopperCount: (json['knownShopperCount'] as num?)?.toInt() ?? 0,
      );
}

class IntentOpportunity {
  const IntentOpportunity({
    required this.subject,
    required this.searches,
    required this.unmet,
    required this.cartActions,
    required this.purchases,
    required this.conversion,
    required this.recommendation,
  });
  final String subject;
  final int searches;
  final int unmet;
  final int cartActions;
  final int purchases;
  final double conversion;
  final String recommendation;
  factory IntentOpportunity.fromJson(Map<String, dynamic> json) =>
      IntentOpportunity(
        subject: json['subject'] as String? ?? '',
        searches: (json['searches'] as num?)?.toInt() ?? 0,
        unmet: (json['unmetSearches'] as num?)?.toInt() ?? 0,
        cartActions: (json['cartActions'] as num?)?.toInt() ?? 0,
        purchases: (json['purchases'] as num?)?.toInt() ?? 0,
        conversion:
            (json['purchaseConversionPercent'] as num?)?.toDouble() ?? 0,
        recommendation: json['recommendation'] as String? ?? 'observe',
      );
  String get action => switch (recommendation) {
    'assess_catalog_gap' => 'Consider stocking this gap',
    'investigate_checkout_friction' => 'Investigate checkout friction',
    'protect_availability' => 'Protect stock availability',
    _ => 'Keep observing',
  };
}

class IntentDecisionBoardPanel extends ConsumerStatefulWidget {
  const IntentDecisionBoardPanel({required this.days, super.key});
  final int days;
  static const loadKey = ValueKey<String>('intent-board-load');
  @override
  ConsumerState<IntentDecisionBoardPanel> createState() =>
      _IntentDecisionBoardPanelState();
}

class _IntentDecisionBoardPanelState
    extends ConsumerState<IntentDecisionBoardPanel> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    if (!expanded) {
      return _Shell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.hub_outlined, color: DesignTokens.primaryGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Intent decision board',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Connect searches, baskets and purchases to see where to stock, investigate or protect availability.',
              style: TextStyle(color: DesignTokens.textLight, height: 1.4),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: IntentDecisionBoardPanel.loadKey,
              onPressed: () => setState(() => expanded = true),
              icon: const Icon(Icons.auto_graph_rounded),
              label: const Text('Build decision board'),
            ),
          ],
        ),
      );
    }
    return ref
        .watch(intentDecisionBoardProvider(widget.days))
        .when(
          loading: () => const _Shell(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (_, _) => _Shell(
            child: Column(
              children: [
                const Text(
                  'Decision board is unavailable right now.',
                  style: TextStyle(color: DesignTokens.textLight),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(intentDecisionBoardProvider(widget.days)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (board) => _Shell(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommended next moves',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                if (board.opportunities.isEmpty)
                  const Text(
                    'Not enough linked signals yet.',
                    style: TextStyle(color: DesignTokens.textLight),
                  )
                else
                  for (final item in board.opportunities.take(5)) ...[
                    _OpportunityTile(item),
                    const SizedBox(height: 8),
                  ],
                const SizedBox(height: 8),
                Text(
                  board.governance,
                  style: const TextStyle(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

class _OpportunityTile extends StatelessWidget {
  const _OpportunityTile(this.item);
  final IntentOpportunity item;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFF202421),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${item.conversion.toStringAsFixed(1)}%',
              style: const TextStyle(
                color: DesignTokens.primaryGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${item.searches} search · ${item.unmet} unmet · ${item.cartActions} cart · ${item.purchases} bought',
          style: const TextStyle(color: DesignTokens.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Text(
          item.action,
          style: const TextStyle(
            color: DesignTokens.primaryGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF171A18),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0x4432D477)),
    ),
    child: child,
  );
}
