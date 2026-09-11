import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/reorder_suggestion_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Buy It Again" — a horizontal row of predicted-reorder cards, sourced
/// from the backend's nightly purchase-cadence job
/// (`orders.reorder-predictions-recalculate`). Renders nothing (not even an
/// empty state) when there are no suggestions or the fetch fails — this is
/// a passive upsell surface, not a primary screen, so it should never make
/// Your Orders look broken to a customer with no purchase history yet.
class BuyItAgainSection extends ConsumerWidget {
  const BuyItAgainSection({super.key});

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Same staleness fix as the order list: the shell keeps this screen
    // mounted across tab switches, so refetch on every revisit rather than
    // relying on provider lifecycle.
    ref.listen<int>(
      ordersTabVisitedProvider,
      (_, _) => ref.read(reorderSuggestionsNotifierProvider.notifier).load(),
    );

    final state = ref.watch(reorderSuggestionsNotifierProvider);

    return state.maybeWhen(
      loadSuccess: (suggestions) {
        if (suggestions.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: DesignTokens.s16),
                child: Text('Buy It Again', style: DesignTokens.sectionInnerTitle),
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
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Future<void> _addToCart(
    BuildContext context,
    WidgetRef ref,
    ReorderSuggestionDto suggestion,
  ) async {
    final ok = await ref.read(cartNotifierProvider.notifier).addItem(
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
                child: SizedBox(
                  height: 72,
                  width: double.infinity,
                  child: suggestion.thumbnailUrl == null ||
                          suggestion.thumbnailUrl!.isEmpty
                      ? const ColoredBox(
                          color: DesignTokens.bgAppBodyLight,
                          child: Icon(
                            Icons.shopping_bag_outlined,
                            color: DesignTokens.textMuted,
                          ),
                        )
                      : Image.network(
                          suggestion.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _e, _s) => const ColoredBox(
                            color: DesignTokens.bgAppBodyLight,
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: DesignTokens.textMuted,
                            ),
                          ),
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
            formatMoney(Money(amount: suggestion.price, currency: suggestion.currency)),
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
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
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
