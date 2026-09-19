import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The LLM narrative from `GET /v1/cart/optimize` — the `insights` list and
/// the `savingsTip`.
///
/// This is the one part of that endpoint that can state something no record
/// supports, and it renders on the same screen as findings that all cite the
/// record they rest on. So:
///
/// * it renders **only** when the backend also sent `narrativeDisclosure`,
///   and that disclosure renders with it, above the text it describes;
/// * it renders the disclosure **verbatim** — fixed backend copy describing
///   the narrative's provenance, not text this client may reword;
/// * it carries three non-colour carriers separating it from a finding: the
///   word "AI suggestion" on its pill, its own glyph, and an italic body with
///   no `Source:` line anywhere in it.
///
/// With the narrative flag off — today's default — `insights` is empty and
/// `savingsTip` is null, so nothing here renders at all: no card, no heading.
class BasketInsightsCard extends StatelessWidget {
  const BasketInsightsCard({required this.optimization, super.key});

  final BasketOptimization? optimization;

  @override
  Widget build(BuildContext context) {
    final summary = optimization;
    // Renders nothing while loading, on error, with the narrative flag off,
    // and — deliberately — when narrative text arrived without the disclosure
    // that marks it. An unmarked ungrounded claim is worse than a missing one.
    if (summary == null || !summary.canRenderNarrative) {
      return const SizedBox.shrink();
    }
    final disclosure = summary.narrativeDisclosure!;
    final insights = summary.insights
        .where((i) => i.trim().isNotEmpty)
        .toList(growable: false);
    final tip = summary.savingsTip;
    final hasTip = tip != null && tip.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          // No fill, unlike a finding card: the narrative reads as an aside
          // beside the solid blocks that carry evidence.
          borderRadius: BorderRadius.circular(DesignTokens.s12),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                container: true,
                child: const Text(
                  'Basket Insights',
                  style: DesignTokens.mediumSemibold,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              Semantics(
                container: true,
                child: const MallStatusPill(
                  label: 'AI suggestion',
                  tone: MallStatusTone.neutral,
                  icon: Icons.auto_awesome,
                  dense: true,
                  semanticLabel: 'AI suggestion, not based on your basket',
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              // The disclosure sits directly above the text it describes,
              // inside the same box, so the mark is read before the claim.
              //
              // Merged into one semantics node with the narrative, so a screen
              // reader cannot reach the claim without the mark either: the
              // disclosure is the first thing in that node, verbatim.
              MergeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NarrativeDisclosure(text: disclosure),
                    const SizedBox(height: DesignTokens.s8),
                    for (final insight in insights)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.s4,
                        ),
                        child: Text(insight, style: _narrativeBody),
                      ),
                    if (hasTip)
                      Text(
                        tip,
                        style: _narrativeBody.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Mall small-regular token, italicised: the narrative differs from every
/// finding's upright body text in greyscale as well as in colour.
final TextStyle _narrativeBody = DesignTokens.smallRegular.copyWith(
  fontStyle: FontStyle.italic,
);

/// The backend's fixed disclosure, rendered exactly as sent.
class _NarrativeDisclosure extends StatelessWidget {
  const _NarrativeDisclosure({required this.text});

  /// Fixed backend copy. Never shortened, reworded or restyled here, and
  /// never truncated — it is the only thing marking what sits below it.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decorative: the words carry the meaning, so the glyph is not read.
        const ExcludeSemantics(
          child: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline,
              size: 14,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Text(text, style: DesignTokens.smallDescription),
        ),
      ],
    );
  }
}
