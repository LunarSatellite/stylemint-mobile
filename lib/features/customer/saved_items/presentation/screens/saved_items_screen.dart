import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/notifiers/saved_items_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Saved Items — rebuilt to the design-PDF spec: filter chips, a vertical list
/// of saved-item rows (64x64 thumbnail, name, variant info, price + old price,
/// stock tag, per-item action), a "Pro Tip" card, and bottom Add-All / Clear-All
/// actions.
///
/// Real data: id, name, image, price. The PDF also shows variant info, an old
/// (strikethrough) price, and a stock status — none of which are on [SavedItem]
/// yet, so they're rendered as deterministic `MOCK` values per row until the
/// API exposes them.
class SavedItemsScreen extends ConsumerWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedItemsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Saved Items', style: DesignTokens.sectionInnerTitle),
        centerTitle: true,
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (items, hasMore, nextCursor) {
          if (items.isEmpty) {
            return const SmEmptyState(
              message:
                  "You haven't saved any items yet. Tap the heart on products you love.",
              icon: Icons.bookmark_border_rounded,
            );
          }
          final notifier = ref.read(savedItemsNotifierProvider.notifier);
          return RefreshIndicator(
            color: DesignTokens.primaryGreen,
            onRefresh: () => notifier.load(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n is ScrollEndNotification &&
                    n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                    hasMore) {
                  notifier.loadMore();
                }
                return false;
              },
              child: ListView(
                padding: const EdgeInsets.all(DesignTokens.s16),
                children: [
                  const _FilterChips(),
                  const SizedBox(height: DesignTokens.s16),
                  ...List.generate(items.length, (i) {
                    return _SavedItemRow(
                      item: items[i],
                      onRemove: () => notifier.removeItem(items[i].id),
                      onAction: () => SmSnackbar.success(
                          context, 'Added to cart (coming soon).'),
                    );
                  }),
                  const SizedBox(height: DesignTokens.s8),
                  const _ProTip(),
                  const SizedBox(height: DesignTokens.s16),
                  SmPrimaryButton(
                    label: 'Add All to Cart',
                    height: DesignTokens.buttonHeight,
                    borderRadius: DesignTokens.buttonRadius,
                    color: DesignTokens.primaryGreen,
                    labelColor: DesignTokens.buttonPrimaryText,
                    onPressed: () async => SmSnackbar.success(
                        context, 'Added all to cart (coming soon).'),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  TextButton(
                    onPressed: () {
                      for (final it in items) {
                        notifier.removeItem(it.id);
                      }
                    },
                    style: TextButton.styleFrom(
                      minimumSize:
                          const Size.fromHeight(DesignTokens.buttonHeight),
                    ),
                    child: Text('Clear All Saved Items',
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.colorError)),
                  ),
                  const SizedBox(height: DesignTokens.s16),
                ],
              ),
            ),
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load saved items.',
          onRetry: () => ref.read(savedItemsNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

// ── Filter chips ──────────────────────────────────────────────────────────────
class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _Chip(label: 'Filter', icon: Icons.tune_rounded),
          _Chip(label: 'Sort By', icon: Icons.swap_vert_rounded),
          _Chip(label: 'In Stock'),
          _Chip(label: 'Low Stock'),
          _Chip(label: 'Out of Stock'),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: DesignTokens.s8),
      padding:
          const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: DesignTokens.chipsDefaultBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: DesignTokens.iconLight),
            const SizedBox(width: DesignTokens.s4),
          ],
          Text(label,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight)),
        ],
      ),
    );
  }
}

// ── Saved item row ────────────────────────────────────────────────────────────
enum _Stock { inStock, lowStock, outOfStock }

class _SavedItemRow extends StatelessWidget {
  const _SavedItemRow({
    required this.item,
    required this.onRemove,
    required this.onAction,
  });

  final SavedItem item;
  final VoidCallback onRemove;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    // SavedForLaterItemDto carries no stock or compare-at price, so the row
    // shows real data only: stock defaults to in-stock (a saved item that
    // lists is available) and there is no strikethrough old price.
    // BACKEND GAP: add per-variant stock + original price to the saved DTO to
    // restore the low/out-of-stock tags and discount strikethrough.
    const stock = _Stock.inStock;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s12),
      padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.s12, horizontal: DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s12),
            child: Image.network(
              item.productImageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: DesignTokens.iconLight),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.textLight)),
                    ),
                    // Spec: 20px gray ghost remove icon.
                    GestureDetector(
                      onTap: onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.all(DesignTokens.s4),
                        child: Icon(Icons.delete_outline,
                            size: 20, color: DesignTokens.iconLight),
                      ),
                    ),
                  ],
                ),
                if (item.variantLabel != null &&
                    item.variantLabel!.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(item.variantLabel!,
                      style: DesignTokens.smallRegular.copyWith(
                        fontSize: 11,
                        color: DesignTokens.textMuted,
                      )),
                ],
                const SizedBox(height: DesignTokens.s8),
                Text(formatMoney(item.price),
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textWhite,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: DesignTokens.s8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StockTag(stock: stock),
                    _RowAction(stock: stock, onTap: onAction),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StockTag extends StatelessWidget {
  const _StockTag({required this.stock});

  final _Stock stock;

  @override
  Widget build(BuildContext context) {
    final (String label, Color bg, Color fg) = switch (stock) {
      _Stock.inStock => (
          'In Stock',
          const Color(0xFFCDF4DD),
          const Color(0xFF016630)
        ),
      _Stock.lowStock => (
          'Only 3 Left !',
          const Color(0xFFFFF085),
          const Color(0xFF894B00)
        ),
      _Stock.outOfStock => (
          'Out of Stock',
          const Color(0xFFFFC9C9),
          const Color(0xFF9F0712)
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.0,
            color: fg,
          )),
    );
  }
}

class _RowAction extends StatelessWidget {
  const _RowAction({required this.stock, required this.onTap});

  final _Stock stock;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outOfStock = stock == _Stock.outOfStock;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        outOfStock ? 'Notify Me when available' : 'Add to Cart',
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 1.2,
          color: DesignTokens.primaryGreen,
          decoration: TextDecoration.underline,
          decorationColor: DesignTokens.primaryGreen,
        ),
      ),
    );
  }
}

// ── Pro Tip ───────────────────────────────────────────────────────────────────
class _ProTip extends StatelessWidget {
  const _ProTip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.s12, horizontal: DesignTokens.s16),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: DesignTokens.bgAppFoundation,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.lightbulb_outline_rounded,
                size: 18, color: DesignTokens.secondaryYellow),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pro Tip',
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.textWhite)),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Enable price drop alerts in notification settings to get the best deals on your saved items!',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textWhite, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
