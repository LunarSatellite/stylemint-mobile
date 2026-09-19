import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_recommendation.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// What Minty suggests before a conversation has started.
///
/// This shelf used to be impossible to build honestly: the service labelled
/// everything "Matches your food preferences" with a hand-written 0.7, while
/// querying a category id that does not exist. It now sends a basis and a
/// reason, and both are rendered as sent:
///
/// * The eyebrow comes from the basis, so a globally popular item is captioned
///   as popular and only a [RecommendationBasis.shoppedCategory] item may
///   mention the shopper at all.
/// * The reason line is the **server's own sentence**, verbatim. It names a
///   real product the customer really interacted with, or says plainly that
///   the item is popular right now. Rephrasing it here is how a checked
///   sentence becomes an unchecked claim.
///
/// There is no score, no percentage and no bar — nothing on this path ranks
/// anything. Tapping a card opens the item. Nothing here adds to a bag,
/// reserves or prices anything (§5.9).
class CompanionRecommendationsShelf extends ConsumerWidget {
  const CompanionRecommendationsShelf({super.key});

  static const Key shelfKey = Key('companion-recommendations-shelf');
  static const int maxCards = 3;

  static Key cardKey(String entityId) => Key('companion-rec-$entityId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations =
        ref.watch(companionRecommendationsProvider).asData?.value ??
        const <CompanionRecommendation>[];
    // Nothing to show, or nothing loaded yet: say nothing. An empty shelf
    // would be a promise the server did not make.
    if (recommendations.isEmpty) return const SizedBox.shrink();

    final shown = recommendations.take(maxCards).toList(growable: false);
    return Padding(
      key: shelfKey,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MallEyebrow('Minty suggests'),
          const SizedBox(height: DesignTokens.s8),
          for (final recommendation in shown) ...[
            _RecommendationCard(recommendation: recommendation),
            const SizedBox(height: DesignTokens.s8),
          ],
        ],
      ),
    );
  }
}

/// One suggestion. Text only — the Mall is video-first and a product
/// photograph belongs on product detail, so the wire's `thumbnailUrl` is not
/// modelled and cannot be drawn here.
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final CompanionRecommendation recommendation;

  static IconData _iconFor(RecommendationBasis basis) => switch (basis) {
    RecommendationBasis.shoppedCategory => Icons.history_outlined,
    RecommendationBasis.popularNow => Icons.local_fire_department_outlined,
    RecommendationBasis.unknown => Icons.storefront_outlined,
  };

  String? get _route => switch (recommendation.entityType) {
    'product' => RouteNames.productDetail.replaceFirst(
      ':productId',
      recommendation.entityId,
    ),
    'reel' => RouteNames.reelDetail.replaceFirst(
      ':reelId',
      recommendation.entityId,
    ),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final reason = recommendation.reason;
    final friendMessage = recommendation.friendMessage;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MallSignalChip(
              signal: MallSignal(
                label: recommendation.basis.label,
                icon: _iconFor(recommendation.basis),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              recommendation.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.mediumSemibold,
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s4),
              // Verbatim, as sent.
              Text(
                reason,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.smallDescription,
              ),
            ],
            if (friendMessage.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(
                friendMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.smallDescription,
              ),
            ],
          ],
        ),
      ),
    );

    if (route == null) {
      return Semantics(
        label: _spoken,
        excludeSemantics: true,
        child: card,
      );
    }
    return Semantics(
      button: true,
      label: 'Open ${recommendation.title}. $_spoken',
      excludeSemantics: true,
      child: InkWell(
        key: CompanionRecommendationsShelf.cardKey(recommendation.entityId),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        onTap: () => context.push(route),
        child: card,
      ),
    );
  }

  /// The spoken form keeps the server's sentence intact too.
  String get _spoken {
    final reason = recommendation.reason;
    return reason.isEmpty ? recommendation.basis.label : reason;
  }
}
