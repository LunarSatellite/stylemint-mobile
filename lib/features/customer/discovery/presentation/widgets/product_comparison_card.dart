import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Product comparison ──────────────────────────────────────────────────────

/// "Which one should I buy?" — Voyager "Intelligent Product Decision
/// Engine" surfaced in-app. Renders nothing while loading, on error, or
/// when there are no alternatives to compare against.
class ProductComparisonCard extends ConsumerWidget {
  const ProductComparisonCard({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparison = ref
        .watch(productComparisonProvider(productId))
        .asData
        ?.value;
    // Null covers both a failure and a 204 — the endpoint now answers 204
    // rather than shipping "A popular choice in its category." Either way
    // there is no card, and a 204 raises nothing.
    if (comparison == null || !comparison.hasContent) {
      return const SizedBox.shrink();
    }

    // Each of the three is optional and each is guarded on its own. A label
    // is never rendered without the value it labels: an absent bestForTag
    // used to print a dangling "Best for: " and an absent howItDiffers an
    // empty span after the product name.
    final bestForTag = comparison.bestForTag;
    final recommendation = comparison.recommendation;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bestForTag != null && bestForTag.isNotEmpty) ...[
            Semantics(
              header: true,
              label: 'Best for: $bestForTag',
              child: ExcludeSemantics(
                child: Row(
                  children: [
                    const Icon(
                      Icons.compare_arrows,
                      size: 18,
                      color: DesignTokens.primaryGreen,
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: Text(
                        'Best for: $bestForTag',
                        style: DesignTokens.mediumSemibold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
          if (recommendation != null && recommendation.isNotEmpty) ...[
            Text(
              recommendation,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
          ],
          ...comparison.alternatives.map(
            (point) => Semantics(
              button: true,
              label: switch (point.howItDiffers) {
                final String d when d.isNotEmpty =>
                  'View ${point.productName}. $d',
                _ => 'View ${point.productName}',
              },
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: () => context.push(
                    RouteNames.productDetail.replaceFirst(
                      ':productId',
                      point.productId,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.s4,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: DesignTokens.textMuted,
                        ),
                        const SizedBox(width: DesignTokens.s4),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textWhite,
                              ),
                              children: [
                                // The colon belongs to the explanation. With no
                                // explanation the name stands alone rather than
                                // trailing a separator into an empty span.
                                if (point.howItDiffers case final d?
                                    when d.isNotEmpty) ...[
                                  TextSpan(
                                    text: '${point.productName}: ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: d),
                                ] else
                                  TextSpan(
                                    text: point.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
