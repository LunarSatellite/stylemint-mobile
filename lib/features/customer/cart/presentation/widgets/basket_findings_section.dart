import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/basket_finding.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The key a cart line carries so a finding can scroll to it. Keyed on the
/// cart line id, which is exactly what `BasketFinding.lineIds` holds.
Key basketLineAnchorKey(String lineId) =>
    GlobalObjectKey('cart-line-anchor-$lineId');

/// The client-side meaning of a `suggestedAction.kind`.
///
/// `suggestedAction.path` is a *description* of a guarded server route, never a
/// URL handed to the HTTP client. Each kind below resolves to a path this app
/// already has; a kind that resolves to nothing renders no button at all,
/// rather than a button that would issue an arbitrary request.
enum _ResolvedActionKind {
  /// `openProduct` → push the existing product-detail route with the id taken
  /// from the described path's last segment. Read-only navigation.
  openProduct,

  /// `reviewLine` / `reviewLines` → scroll the cart to the lines the finding
  /// names, so the customer can use the line's own controls. The described
  /// `DELETE /v1/cart/lines/{lineId}` is reached only by the customer tapping
  /// that existing per-line control — never from here.
  reviewLines,
}

_ResolvedActionKind? _resolveActionKind(String kind) => switch (kind) {
  'openProduct' => _ResolvedActionKind.openProduct,
  'reviewLine' || 'reviewLines' => _ResolvedActionKind.reviewLines,
  // Unrecognised: the customer sees the finding, not a broken control.
  _ => null,
};

/// The product id described by `/v1/public/products/{id}`. Null when the path
/// is not the shape this build knows, which suppresses the button.
String? _productIdFromPath(String path) {
  final segments = path
      .split('?')
      .first
      .split('/')
      .where((s) => s.isNotEmpty)
      .toList();
  if (segments.length < 2) return null;
  if (segments[segments.length - 2] != 'products') return null;
  final id = segments.last;
  if (id.isEmpty || id.contains('{')) return null;
  return id;
}

/// Pill label, tone and glyph for a finding.
///
/// A kind this build does not know gets its *stage* — a value the backend
/// sent — or no pill at all. Nothing here invents a meaning for it.
({String label, MallStatusTone tone, IconData icon})? _findingBadge(
  BasketFinding finding,
) => switch (finding.kind) {
  BasketFindingKind.restrictedItem => (
    label: 'Safety check',
    tone: MallStatusTone.danger,
    icon: Icons.gpp_maybe_outlined,
  ),
  BasketFindingKind.priceChanged => (
    label: 'Price changed',
    tone: MallStatusTone.caution,
    icon: Icons.sell_outlined,
  ),
  BasketFindingKind.currencyMismatch => (
    label: 'Currency',
    tone: MallStatusTone.caution,
    icon: Icons.currency_exchange_rounded,
  ),
  BasketFindingKind.duplicateListing => (
    label: 'Duplicate',
    tone: MallStatusTone.info,
    icon: Icons.copy_all_outlined,
  ),
  BasketFindingKind.betterValuePerUnit => (
    label: 'Comparison',
    tone: MallStatusTone.info,
    icon: Icons.straighten_rounded,
  ),
  BasketFindingKind.deliverySplit => (
    label: 'Delivery',
    tone: MallStatusTone.progress,
    icon: Icons.local_shipping_outlined,
  ),
  BasketFindingKind.slowestLine => (
    label: 'Timing',
    tone: MallStatusTone.progress,
    icon: Icons.schedule_rounded,
  ),
  BasketFindingKind.unknown => switch (finding.stage) {
    BasketFindingStage.inspect => (
      label: 'Inspected',
      tone: MallStatusTone.neutral,
      icon: Icons.search_rounded,
    ),
    BasketFindingStage.compare => (
      label: 'Compared',
      tone: MallStatusTone.neutral,
      icon: Icons.compare_arrows_rounded,
    ),
    BasketFindingStage.coordinate => (
      label: 'Coordinated',
      tone: MallStatusTone.neutral,
      icon: Icons.hub_outlined,
    ),
    BasketFindingStage.unknown => null,
  },
};

/// What the basket optimiser noticed, on the cart screen.
///
/// Order: the one safety finding band first (`restrictedItem`), then price
/// integrity (`priceChanged`, `currencyMismatch`), then everything else in the
/// order the backend sent it. Nothing is dropped or collapsed, so the quieter
/// Compare and Coordinate findings still read in their own order below.
///
/// No heading, no card and no reassurance render when `findings` is empty —
/// silence is the backend saying nothing, and "your basket looks good" would
/// be a claim it never made.
class BasketFindingsSection extends ConsumerWidget {
  const BasketFindingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final optimization = ref.watch(basketOptimizationProvider).asData?.value;
    final findings = optimization?.findings ?? const <BasketFinding>[];
    if (findings.isEmpty) return const SizedBox.shrink();

    return BasketFindingsList(
      findings: findings,
      onOpenProduct: (productId) => context.push(
        RouteNames.productDetail.replaceFirst(':productId', productId),
      ),
      onReviewLines: _scrollToFirstLine,
    );
  }

  /// Brings the first named cart line into view. Read-only: it moves the
  /// viewport and nothing else.
  void _scrollToFirstLine(List<String> lineIds) {
    for (final lineId in lineIds) {
      final anchor = basketLineAnchorKey(lineId);
      final anchorContext = anchor is GlobalObjectKey
          ? anchor.currentContext
          : null;
      if (anchorContext == null) continue;
      unawaited(
        Scrollable.ensureVisible(
          anchorContext,
          duration: const Duration(milliseconds: 240),
          alignment: 0.1,
          curve: Curves.easeOutCubic,
        ),
      );
      return;
    }
  }
}

/// The provider-free body, so the ordering and the degrade-gracefully rules
/// are testable from a fixture without a repository.
class BasketFindingsList extends StatelessWidget {
  const BasketFindingsList({
    required this.findings,
    super.key,
    this.onOpenProduct,
    this.onReviewLines,
  });

  final List<BasketFinding> findings;
  final void Function(String productId)? onOpenProduct;
  final void Function(List<String> lineIds)? onReviewLines;

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();
    final ordered = orderBasketFindings(findings);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: const Text(
              'What we noticed',
              style: DesignTokens.mediumSemibold,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          // Deliberately no count, total, percentage or summary line: every
          // number on this screen comes from a fact the backend sent.
          const Text(
            'Checked against your basket. Nothing has been changed.',
            style: DesignTokens.smallRegular,
          ),
          for (final finding in ordered)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s8),
              child: BasketFindingCard(
                finding: finding,
                onOpenProduct: onOpenProduct,
                onReviewLines: onReviewLines,
              ),
            ),
        ],
      ),
    );
  }
}

/// One finding: its badge, headline, detail, facts with their sources, and —
/// where the action kind maps to a client path — its button.
class BasketFindingCard extends StatelessWidget {
  const BasketFindingCard({
    required this.finding,
    super.key,
    this.onOpenProduct,
    this.onReviewLines,
  });

  final BasketFinding finding;
  final void Function(String productId)? onOpenProduct;
  final void Function(List<String> lineIds)? onReviewLines;

  @override
  Widget build(BuildContext context) {
    final badge = _findingBadge(finding);
    // A safety finding is heavier in three non-colour ways at once: its own
    // word ("Safety check"), its own glyph, and a rule down the leading edge.
    final isSafety = finding.isSafety;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.s12),
        border: Border.all(
          color: isSafety
              ? DesignTokens.colorError
              : DesignTokens.borderDefault,
          width: isSafety ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (badge != null) ...[
              Semantics(
                container: true,
                child: MallStatusPill(
                  label: badge.label,
                  tone: badge.tone,
                  icon: badge.icon,
                  dense: true,
                  semanticLabel: isSafety
                      ? 'Safety check on this basket line'
                      : badge.label,
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
            ],
            Text(finding.headline, style: DesignTokens.mediumSemibold),
            if (finding.detail.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(finding.detail, style: DesignTokens.smallDescription),
            ],
            if (finding.facts.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s8),
              for (final fact in finding.facts)
                _FactRow(
                  key: ValueKey('${fact.label}/${fact.source}'),
                  fact: fact,
                ),
            ],
            _ActionButton(
              finding: finding,
              onOpenProduct: onOpenProduct,
              onReviewLines: onReviewLines,
            ),
          ],
        ),
      ),
    );
  }
}

/// One fact, rendered exactly as the backend sent it, above the record it came
/// from. Values are never reformatted, combined or totalled.
class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact, super.key});

  final BasketFindingFact fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s4),
      child: Semantics(
        // Its own node, so a screen reader reads one fact — value and source
        // together — instead of the whole card as a single run of text.
        container: true,
        label: '${fact.label}: ${fact.value}. Source: ${fact.source}',
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column, not Row: at 320dp and 1.3x a label/value pair on one
            // line is the classic overflow here.
            Text(fact.label, style: DesignTokens.smallRegular),
            Text(
              fact.value,
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            Text(
              'Source: ${fact.source}',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textContentSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The finding's action, or nothing.
///
/// Nothing runs on build. The button exists only when the kind maps to a
/// client path, and the mapped path runs only from the customer's tap.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.finding,
    this.onOpenProduct,
    this.onReviewLines,
  });

  final BasketFinding finding;
  final void Function(String productId)? onOpenProduct;
  final void Function(List<String> lineIds)? onReviewLines;

  @override
  Widget build(BuildContext context) {
    final action = finding.suggestedAction;
    if (action == null) return const SizedBox.shrink();

    final resolved = _resolveActionKind(action.kind);
    if (resolved == null) return const SizedBox.shrink();

    VoidCallback? onPressed;
    switch (resolved) {
      case _ResolvedActionKind.openProduct:
        final productId = _productIdFromPath(action.path);
        final open = onOpenProduct;
        if (productId != null && open != null) {
          onPressed = () => open(productId);
        }
      case _ResolvedActionKind.reviewLines:
        final review = onReviewLines;
        if (review != null && finding.lineIds.isNotEmpty) {
          onPressed = () => review(finding.lineIds);
        }
    }
    if (onPressed == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: SizedBox(
        width: double.infinity,
        child: Semantics(
          container: true,
          button: true,
          label: action.label,
          excludeSemantics: true,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              foregroundColor: DesignTokens.textWhite,
              side: const BorderSide(color: DesignTokens.borderDefault),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
            ),
            child: Text(
              action.label,
              textAlign: TextAlign.center,
              style: DesignTokens.mediumSemibold,
            ),
          ),
        ),
      ),
    );
  }
}
