import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorProductTile extends StatelessWidget {
  const VendorProductTile({
    required this.product,
    required this.onTap,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    super.key,
  });

  final VendorProduct product;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  Color _statusColor() {
    return switch (product.status) {
      VendorProductStatus.active => DesignTokens.primaryGreen,
      VendorProductStatus.draft => DesignTokens.secondaryYellow,
      VendorProductStatus.outOfStock => DesignTokens.colorError,
      VendorProductStatus.discontinued => DesignTokens.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s6,
        ),
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s8),
              child: Image.network(
                product.imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: DesignTokens.bgAppBodyLight,
                  child: const Icon(Icons.image,
                      color: DesignTokens.textMuted),
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    formatMoney(product.price),
                    style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Row(
                    children: [
                      _StatusBadge(
                        label: product.status.label,
                        color: _statusColor(),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      Text(
                        'Stock: ${product.stockCount}',
                        style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted),
                      ),
                      const Spacer(),
                      Icon(Icons.star,
                          size: 14, color: DesignTokens.secondaryYellow),
                      const SizedBox(width: 2),
                      Text(
                        product.rating.toStringAsFixed(1),
                        style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              PopupMenuButton<String>(
                color: DesignTokens.bgAppBody,
                icon: const Icon(Icons.more_vert,
                    color: DesignTokens.iconLight),
                onSelected: (action) {
                  switch (action) {
                    case 'edit':
                      onEdit?.call();
                    case 'duplicate':
                      onDuplicate?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit')),
                  if (onDuplicate != null)
                    const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate')),
                  if (onDelete != null)
                    const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: DesignTokens.colorError))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Text(
        label,
        style: DesignTokens.tiny.copyWith(
            color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
