import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Buy It Again" — a horizontal row of predicted-reorder cards, sourced
/// from the backend's nightly purchase-cadence job
/// (`orders.reorder-predictions-recalculate`). Draws no card and no empty
/// state when there are no suggestions or the fetch fails — this is a
/// passive upsell surface, not a primary screen, so it should never make
/// Your Orders look broken to a customer with no purchase history yet.
///
/// What it does keep in every one of those cases is the [_RestockEntry] row
/// beneath, because the rail's "See all" link was the only way in to
/// `/orders/buy-it-again` and everything behind it. A new account has no
/// rhythm to read yet, so it got no rail, so the restock screens — and the
/// refill basket and its rules, which are only linked from there — existed
/// but could not be opened. An empty forecast is still empty; it is the door
/// that has to stay, not the content behind it.
class BuyItAgainSection extends ConsumerStatefulWidget {
  const BuyItAgainSection({super.key});

  @override
  ConsumerState<BuyItAgainSection> createState() => _BuyItAgainSectionState();
}

class _BuyItAgainSectionState extends ConsumerState<BuyItAgainSection> {
  static const _uuid = Uuid();
  bool _addingBasket = false;

  @override
  Widget build(BuildContext context) {
    // Replenishment prediction is personalisation, so it passes the same
    // Memory Vault gate the adaptive storefront does. A paused customer sees
    // no rail, no consent card and no link to the screen — an entry point
    // that could only say "paused" is an entry point that dangles. Undoing
    // the pause is a Memory Vault job and it has its own tile on Profile,
    // which is not gated on personalisation and so outlives this one.
    final allowed = ref.watch(personalizationAllowedProvider);
    if (allowed.asData?.value != true) return const SizedBox.shrink();

    // Same staleness fix as the order list: the shell keeps this screen
    // mounted across tab switches, so refetch on every revisit rather than
    // relying on provider lifecycle.
    ref.listen<int>(
      ordersTabVisitedProvider,
      (_, _) => ref.read(reorderSuggestionsNotifierProvider.notifier).load(),
    );

    final preference = ref.watch(replenishmentPreferenceNotifierProvider);
    if (preference is ReplenishmentPreferenceLoading ||
        preference is ReplenishmentPreferenceFailed) {
      return const _RestockEntry();
    }
    final preferenceLoaded = preference as ReplenishmentPreferenceLoaded;
    if (!preferenceLoaded.enabled) {
      // The invitation, and under it the way in regardless: a customer who
      // declines the rail still owns rules, a pause and a refill plan, and
      // those are reached through the same screen.
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReplenishmentConsentCard(
            saving: preferenceLoaded.saving,
            onEnable: () => _setPreference(true),
          ),
          const _RestockEntry(),
        ],
      );
    }

    final state = ref.watch(reorderSuggestionsNotifierProvider);

    return state.maybeWhen(
      loadSuccess: (suggestions) {
        if (suggestions.isEmpty) return const _RestockEntry();
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your restock forecast',
                            style: DesignTokens.sectionInnerTitle,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Based on your purchase rhythm — '
                            'you stay in control.',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('restock-pause'),
                      tooltip: 'Pause restock predictions',
                      onPressed: preferenceLoaded.saving
                          ? null
                          : () => _setPreference(false),
                      icon: const Icon(Icons.pause_circle_outline_rounded),
                      color: DesignTokens.textMuted,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: DesignTokens.s4),
                    FilledButton.icon(
                      key: const ValueKey('restock-add-basket'),
                      onPressed: _addingBasket
                          ? null
                          : () => _reviewAndAddBasket(suggestions),
                      style: FilledButton.styleFrom(
                        backgroundColor: DesignTokens.primaryGreen,
                        foregroundColor: DesignTokens.bgAppFoundation,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: _addingBasket
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.playlist_add_rounded, size: 17),
                      label: Text(
                        _addingBasket ? 'Adding' : 'Build basket',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.s8),
              SizedBox(
                height: 178,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                  ),
                  itemCount: suggestions.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: DesignTokens.s12),
                  itemBuilder: (_, i) => _SuggestionCard(
                    suggestion: suggestions[i],
                    onAddToCart: () => _addToCart(context, ref, suggestions[i]),
                    onDismiss: () => ref
                        .read(reorderSuggestionsNotifierProvider.notifier)
                        .dismiss(suggestions[i].productId),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s8,
                ),
                child: TextButton(
                  key: const ValueKey('restock-see-all'),
                  onPressed: () => context.push(RouteNames.buyItAgain),
                  child: Semantics(
                    button: true,
                    label: 'See all restock estimates',
                    excludeSemantics: true,
                    child: const Text('See all restock estimates'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const _RestockEntry(),
    );
  }

  Future<void> _setPreference(bool enabled) async {
    final saved = await ref
        .read(replenishmentPreferenceNotifierProvider.notifier)
        .setEnabled(enabled);
    if (!mounted) return;
    if (!saved) {
      SmSnackbar.error(context, "Couldn't save your preference. Try again.");
      return;
    }
    if (enabled) {
      await ref.read(reorderSuggestionsNotifierProvider.notifier).load();
      if (!mounted) return;
      SmSnackbar.success(context, 'Restock predictions are on');
    } else {
      SmSnackbar.success(context, 'Restock predictions are paused');
    }
  }

  Future<void> _reviewAndAddBasket(
    List<ReorderSuggestionDto> suggestions,
  ) async {
    final totalUnits = suggestions.fold<int>(
      0,
      (sum, item) => sum + item.suggestedQuantity,
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Build your restock basket?'),
        content: Text(
          'We will add $totalUnits predicted item${totalUnits == 1 ? '' : 's'} '
          'from ${suggestions.length} product${suggestions.length == 1 ? '' : 's'} '
          'to your cart. Nothing is purchased automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Add to cart'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _addingBasket = true);
    var added = 0;
    for (final suggestion in suggestions) {
      final ok = await ref
          .read(cartNotifierProvider.notifier)
          .addItem(
            productId: suggestion.productId,
            quantity: suggestion.suggestedQuantity,
            idempotencyKey: _uuid.v4(),
          );
      if (ok) added++;
    }
    if (!mounted) return;
    setState(() => _addingBasket = false);
    if (added == suggestions.length) {
      SmSnackbar.success(context, 'Your restock basket is ready in cart');
    } else if (added > 0) {
      SmSnackbar.error(
        context,
        'Added $added of ${suggestions.length} products. Review your cart.',
      );
    } else {
      SmSnackbar.error(context, "Couldn't build the basket. Please try again.");
    }
  }

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    ReorderSuggestionDto suggestion,
  ) async {
    final ok = await ref
        .read(cartNotifierProvider.notifier)
        .addItem(
          productId: suggestion.productId,
          quantity: suggestion.suggestedQuantity,
          idempotencyKey: _uuid.v4(),
        );
    if (!context.mounted) return;
    if (ok) {
      SmSnackbar.success(context, 'Added ${suggestion.productName} to cart');
    } else {
      SmSnackbar.error(context, "Couldn't add to cart. Please try again.");
    }
  }
}

/// The durable way in to the restock area, drawn wherever the rail above is
/// not. It promises nothing: no count, no estimate, no "you have N items
/// due" — the screen it opens is where an empty forecast gets to say so in
/// its own words.
class _RestockEntry extends StatelessWidget {
  const _RestockEntry();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DesignTokens.s16,
      0,
      DesignTokens.s16,
      DesignTokens.s16,
    ),
    child: InkWell(
      key: const ValueKey('restock-entry'),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      onTap: () => context.push(RouteNames.buyItAgain),
      child: Semantics(
        button: true,
        label: 'Open restock and refill',
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.s12),
          decoration: BoxDecoration(
            color: DesignTokens.bgAppBody,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(color: DesignTokens.borderDefault),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.event_repeat_outlined,
                color: DesignTokens.textMuted,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Restock and refill',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your restock estimates, the refill basket and the '
                      'rules behind them.',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              const Icon(
                Icons.chevron_right_rounded,
                color: DesignTokens.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ReplenishmentConsentCard extends StatelessWidget {
  const _ReplenishmentConsentCard({
    required this.saving,
    required this.onEnable,
  });

  final bool saving;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DesignTokens.s16,
      0,
      DesignTokens.s16,
      DesignTokens.s16,
    ),
    child: DecoratedBox(
      // The Mall separates layers with tone and shadow, not with a border
      // and a bespoke two-stop green.
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreenDark,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: DesignTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Row(
          children: [
            const Icon(
              Icons.autorenew_rounded,
              color: DesignTokens.primaryGreen,
              size: 28,
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Know when you might be due',
                    style: DesignTokens.mediumSemibold,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Let StyleMint estimate when your regular items may '
                    'need restocking. We never purchase automatically.',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            FilledButton(
              key: const ValueKey('restock-enable'),
              onPressed: saving ? null : onEnable,
              child: Text(saving ? 'Saving' : 'Turn on'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.suggestion,
    required this.onAddToCart,
    required this.onDismiss,
  });

  final ReorderSuggestionDto suggestion;
  final VoidCallback onAddToCart;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      padding: const EdgeInsets.all(DesignTokens.s8),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.s8),
                // The Mall is video-first: a product photograph belongs to
                // the product details page, so this rail draws the kit's
                // typographic ground, seeded from the product id so the same
                // product looks the same wherever it appears. The DTO's
                // `thumbnailUrl` is deliberately not read here.
                child: SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: MallTypeGround(
                    seed: suggestion.productId,
                    monogram: suggestion.productName.characters.firstOrNull,
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: DesignTokens.textMuted,
                  style: IconButton.styleFrom(
                    backgroundColor: DesignTokens.bgAppFoundation,
                    minimumSize: const Size(24, 24),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            suggestion.productName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            formatMoney(
              Money(amount: suggestion.price, currency: suggestion.currency),
            ),
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            // outlinedButtonStyle() bakes in a much taller minimumSize +
            // 12px vertical padding meant for full-width primary buttons —
            // forcing that into a 28px-tall box left less room than the
            // padding alone needed, clipping "Add" down to unrecognizable
            // slivers. This card needs its own compact style instead of
            // fighting the shared one's minimum height.
            child: OutlinedButton(
              onPressed: onAddToCart,
              style: OutlinedButton.styleFrom(
                foregroundColor: DesignTokens.textWhite,
                side: const BorderSide(color: DesignTokens.borderDefault),
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.buttonRadius,
                  ),
                ),
              ),
              child: const Text('Add', style: TextStyle(fontSize: 11)),
            ),
          ),
        ],
      ),
    );
  }
}
