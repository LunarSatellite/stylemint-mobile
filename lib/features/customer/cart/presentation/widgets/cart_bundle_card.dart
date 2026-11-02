import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_format.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One bundle in the cart (shop bundles contract §B8): its lines, grouped by
/// the shop that ships them, under one price. The number of bundles is
/// changed here, never on one line (`bundle_line_quantity_locked`).
/// Removing one line breaks the bundle — the rest go back to list price —
/// so it asks first.
class CartBundleCard extends StatelessWidget {
  const CartBundleCard({
    required this.group,
    required this.lines,
    required this.onQuantity,
    required this.onRemoveBundle,
    required this.onUnbundle,
    required this.onRemoveLine,
    this.busy = false,
    this.lineKey,
    super.key,
  });

  static Key cardKey(String groupId) => Key('cart-bundle-$groupId');
  static Key unbundleKey(String groupId) => Key('cart-bundle-unbundle-$groupId');
  static Key removeKey(String groupId) => Key('cart-bundle-remove-$groupId');
  static Key plusKey(String groupId) => Key('cart-bundle-plus-$groupId');
  static Key minusKey(String groupId) => Key('cart-bundle-minus-$groupId');
  static Key removeLineKey(String lineId) => Key('cart-bundle-line-remove-$lineId');
  static const Key confirmBreakKey = Key('cart-bundle-confirm-break');

  final CartBundleGroup group;
  final List<CartItem> lines;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemoveBundle;
  final VoidCallback onUnbundle;
  final ValueChanged<CartItem> onRemoveLine;
  final bool busy;

  /// Wraps each line (the cart's basket-finding scroll anchors).
  final Key Function(String lineId)? lineKey;

  int get _shopCount {
    final shops = <String>{
      for (final l in lines)
        if ((l.vendorAccountId ?? l.vendorName) != null)
          (l.vendorAccountId ?? l.vendorName)!,
    };
    return shops.length;
  }

  Future<void> _confirmRemoveLine(BuildContext context, CartItem line) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Break up the bundle?'),
        content: Text(
          'Removing ${line.productName} takes the bundle price off the other '
          'items in "${group.title}". They stay in your cart at their full '
          'price.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep bundle'),
          ),
          TextButton(
            key: confirmBreakKey,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove item'),
          ),
        ],
      ),
    );
    if (ok ?? false) onRemoveLine(line);
  }

  @override
  Widget build(BuildContext context) {
    final shops = _shopCount;
    final counts = bundleCountsLabel(items: lines.length, shops: shops);
    return Padding(
      key: cardKey(group.groupId),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s8,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(
            color: group.isPurchasable
                ? DesignTokens.primaryGreen.withValues(alpha: 0.5)
                : DesignTokens.colorWarning,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: DesignTokens.primaryGreen,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: DesignTokens.mediumSemibold,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (counts.isNotEmpty)
                          Text(
                            shops > 1
                                ? '$counts · each shop ships its own parcel'
                                : counts,
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bundleMoney(group.total),
                        style: DesignTokens.mediumSemibold,
                      ),
                      if (group.saving.amount > 0) ...[
                        Text(
                          bundleMoney(group.listTotal),
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          'You save ${bundleMoney(group.saving)}',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (!group.isPurchasable)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                ),
                padding: const EdgeInsets.all(DesignTokens.s8),
                decoration: BoxDecoration(
                  color: DesignTokens.warningFillDark,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                ),
                child: Text(
                  '${bundleUnavailableSentence(group.unavailableReason)} '
                  'Remove it, or buy the items separately.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.warningTextLight,
                  ),
                ),
              ),
            for (final line in lines)
              KeyedSubtree(
                key: lineKey?.call(line.id) ?? ValueKey(line.id),
                child: _BundleLineRow(
                  line: line,
                  onRemove: busy
                      ? null
                      : () => _confirmRemoveLine(context, line),
                ),
              ),
            const Divider(height: 1, color: DesignTokens.borderDefault),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s8,
                vertical: DesignTokens.s4,
              ),
              child: Row(
                children: [
                  IconButton(
                    key: minusKey(group.groupId),
                    tooltip: 'One bundle fewer',
                    onPressed: busy || group.quantity <= 1
                        ? null
                        : () => onQuantity(group.quantity - 1),
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  Text(
                    '${group.quantity}',
                    style: DesignTokens.mediumSemibold,
                  ),
                  IconButton(
                    key: plusKey(group.groupId),
                    tooltip: 'One more bundle',
                    onPressed: busy || !group.isPurchasable
                        ? null
                        : () => onQuantity(group.quantity + 1),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                  const Spacer(),
                  TextButton(
                    key: unbundleKey(group.groupId),
                    onPressed: busy ? null : onUnbundle,
                    child: Text(
                      group.isPurchasable ? 'Unbundle' : 'Buy separately',
                    ),
                  ),
                  TextButton(
                    key: removeKey(group.groupId),
                    onPressed: busy ? null : onRemoveBundle,
                    style: TextButton.styleFrom(
                      foregroundColor: DesignTokens.colorError,
                    ),
                    child: const Text('Remove'),
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

class _BundleLineRow extends StatelessWidget {
  const _BundleLineRow({
    required this.line,
    required this.onRemove,
  });

  final CartItem line;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final list = line.bundleListUnitPrice;
    final shop = line.vendorName;
    final detail = [
      if (line.variantName.isNotEmpty) line.variantName,
      if (line.quantity > 1) '× ${line.quantity}',
      if (shop != null) shop,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s12,
        DesignTokens.s8,
        DesignTokens.s4,
        DesignTokens.s8,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: SizedBox(
              width: 44,
              height: 44,
              child: MallNetworkImage(url: line.productImageUrl),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.productName,
                  style: DesignTokens.smallRegular,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                bundleMoney(line.unitPrice),
                style: DesignTokens.smallRegular,
              ),
              if (list != null && list.amount > line.unitPrice.amount)
                Text(
                  bundleMoney(list),
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
            ],
          ),
          IconButton(
            key: CartBundleCard.removeLineKey(line.id),
            tooltip: 'Remove ${line.productName}',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
