import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/notifiers/assistant_thread_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The products one assistant turn suggested, each with its own add control.
///
/// Three rules are structural here, not stylistic:
///
/// * The shelf is built **only** from `turn.suggestedProductIds`, and a user
///   turn's list is empty by construction, so a customer's own message has no
///   shelf and there is nothing to "approve".
/// * Adding happens on an explicit press of a labelled button and nowhere
///   else — never on build, on scroll, or on opening the thread.
/// * A suggested id that does not resolve is simply absent. There is no
///   placeholder card standing in for a product that may not exist.
///
/// Tiles are the Mall's video-first tiles: a reel where the product has one,
/// the typographic tile where it does not, and no product photograph either
/// way. Tapping one opens the ordinary product page. There is no path from
/// here to checkout.
class AssistantSuggestionShelf extends ConsumerWidget {
  const AssistantSuggestionShelf({
    required this.conversationId,
    required this.turn,
    super.key,
  });

  final String conversationId;
  final CompanionTurn turn;

  static const Key shelfKey = Key('assistant-suggestion-shelf');
  static const double tileWidth = 172;

  static Key addKey(String productId) => Key('assistant-add-$productId');

  /// Height of the add control, so the horizontal shelf can be sized exactly
  /// and never overflows at a large text scale.
  static double controlHeight(BuildContext context) =>
      MallMetrics.textHeight(
        MallMetrics.scalerOf(context),
        fontSize: 13,
        lineHeight: 1.3,
      ) +
      DesignTokens.s16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!turn.hasSuggestions) return const SizedBox.shrink();

    final resolved = ref.watch(suggestedProductsProvider(turn));
    final products = resolved.asData?.value ?? const <MallProductVm>[];
    final loading = resolved.isLoading;

    // Nothing resolved: say nothing. A shelf of stubs would be a claim the
    // catalogue does not support.
    if (!loading && products.isEmpty) return const SizedBox.shrink();

    final height =
        MallProductTile.heightFor(context, width: tileWidth) +
        DesignTokens.s8 +
        controlHeight(context);

    return Padding(
      key: shelfKey,
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.fromSTEB(DesignTokens.s4, 0, 0, 0),
            child: MallEyebrow('Minty suggested'),
          ),
          const SizedBox(height: DesignTokens.s8),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.fromSTEB(
                DesignTokens.s4,
                0,
                DesignTokens.s4,
                0,
              ),
              itemCount: loading ? 2 : products.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: DesignTokens.s12),
              itemBuilder: (context, index) => loading
                  ? SmSkeleton.box(width: tileWidth, height: height)
                  : _Suggestion(
                      conversationId: conversationId,
                      turn: turn,
                      product: products[index],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestion extends ConsumerWidget {
  const _Suggestion({
    required this.conversationId,
    required this.turn,
    required this.product,
  });

  final String conversationId;
  final CompanionTurn turn;
  final MallProductVm product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final add = ref.watch(
      assistantThreadProvider(
        conversationId,
      ).select((s) => s.adds[suggestionKey(turn.id, product.id)]),
    );
    final busy = add?.busy ?? false;
    final added = add?.added ?? false;

    return SizedBox(
      width: AssistantSuggestionShelf.tileWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MallProductTile(
            product: product,
            onTap: () => context.push(
              RouteNames.productDetail.replaceFirst(':productId', product.id),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          SizedBox(
            height: AssistantSuggestionShelf.controlHeight(context),
            child: Semantics(
              button: true,
              enabled: !busy && !added,
              label: added
                  ? '${product.name} is in your bag'
                  : 'Add ${product.name} to your bag',
              excludeSemantics: true,
              child: _AddToBagButton(
                key: AssistantSuggestionShelf.addKey(product.id),
                busy: busy,
                added: added,
                onPressed: () => _add(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final notifier = ref.read(
      assistantThreadProvider(conversationId).notifier,
    );
    final ok = await notifier.addSuggestion(turn: turn, productId: product.id);
    if (ok || messenger == null) return;
    final failure = ref
        .read(assistantThreadProvider(conversationId))
        .adds[suggestionKey(turn.id, product.id)]
        ?.error;
    messenger.showSnackBar(
      SnackBar(content: Text(failure ?? 'That could not be added.')),
    );
  }
}

class _AddToBagButton extends StatelessWidget {
  const _AddToBagButton({
    required this.busy,
    required this.added,
    required this.onPressed,
    super.key,
  });

  final bool busy;
  final bool added;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    final label = added
        ? 'In your bag'
        : busy
        ? 'Adding…'
        : 'Add to bag';
    return Material(
      color: added ? DesignTokens.primaryGreenDark : DesignTokens.surfaceRaised,
      borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        onTap: busy || added ? null : () => unawaited(onPressed()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                added
                    ? Icons.check_circle_outline_rounded
                    : Icons.add_shopping_cart_outlined,
                size: 15,
                color: added
                    ? DesignTokens.primaryGreen
                    : DesignTokens.textLight,
              ),
              const SizedBox(width: DesignTokens.s8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                    color: added
                        ? DesignTokens.primaryGreen
                        : DesignTokens.textWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
