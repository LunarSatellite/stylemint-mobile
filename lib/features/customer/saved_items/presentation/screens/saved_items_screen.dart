import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/domain/entities/saved_item.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/notifiers/saved_items_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
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
            return _EmptyState(onContinue: () => context.go(RouteNames.home));
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
                      backgroundColor: DesignTokens.bgAppBodyLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                      ),
                    ),
                    child: Text('Clear All Saved Items',
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.textWhite)),
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
    final stock = switch (item.stockStatus) {
      'lowStock' => _Stock.lowStock,
      'outOfStock' => _Stock.outOfStock,
      _ => _Stock.inStock,
    };

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
                Row(
                  children: [
                    Text(formatMoney(item.price),
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w600,
                        )),
                    if (item.originalPrice != null) ...[
                      const SizedBox(width: DesignTokens.s8),
                      Text(
                        formatMoney(item.originalPrice!),
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DesignTokens.s8),
                Row(
                  children: [
                    _StockTag(stock: stock),
                    if (item.isFreeShipping) ...[
                      const SizedBox(width: DesignTokens.s8),
                      _Badge(
                        label: 'Free Shipping',
                        icon: Icons.local_shipping_outlined,
                        bg: const Color(0xFFDDEEFF),
                        fg: const Color(0xFF004999),
                      ),
                    ],
                    if (item.priceDrop != null) ...[
                      const SizedBox(width: DesignTokens.s8),
                      _Badge(
                        label: 'Price Dropped ${formatMoney(item.priceDrop!)}',
                        icon: Icons.savings_outlined,
                        bg: const Color(0xFFFFF085),
                        fg: const Color(0xFF894B00),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DesignTokens.s8),
                _RowAction(stock: stock, onTap: onAction),
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

// ── Badge (Free Shipping / Price Dropped) ────────────────────────────────────
class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.0,
              )),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration — stacked placeholder cards
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _PlaceholderCard(offsetY: -40, offsetX: -30, initials: 'SD'),
                _PlaceholderCard(offsetY: 0, offsetX: 20, initials: 'AP'),
                _PlaceholderCard(offsetY: 40, offsetX: -20, initials: 'JS'),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.s24),
          Text('No Saved Items Yet',
              style: DesignTokens.sectionInnerTitle.copyWith(
                color: DesignTokens.textWhite,
                fontSize: 20,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: DesignTokens.s12),
          Text(
            'When you tap the heart icon in the product detail screen you will be able to view it here',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.s32),
          SmPrimaryButton(
            label: 'Continue Shopping →',
            height: DesignTokens.buttonHeight,
            borderRadius: DesignTokens.buttonRadius,
            color: DesignTokens.primaryGreen,
            labelColor: DesignTokens.buttonPrimaryText,
            onPressed: () async => onContinue(),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.offsetY,
    required this.offsetX,
    required this.initials,
  });

  final double offsetY;
  final double offsetX;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Container(
        width: 200,
        height: 52,
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.s12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: DesignTokens.primaryGreen,
              child: Text(initials,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    width: 80,
                    decoration: BoxDecoration(
                      color: DesignTokens.secondaryYellow.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 6,
                    width: 110,
                    decoration: BoxDecoration(
                      color: DesignTokens.textMuted.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
