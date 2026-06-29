import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorProductTile extends StatelessWidget {
  const VendorProductTile({
    required this.product,
    required this.onTap,
    this.onMore,
    super.key,
  });

  final VendorProduct product;
  final VoidCallback onTap;
  final VoidCallback? onMore;

  static const _lowStockThreshold = 100;

  bool get _isDraft => product.status == VendorProductStatus.draft;
  bool get _isOutOfStock => product.status == VendorProductStatus.outOfStock;
  bool get _isActive => product.status == VendorProductStatus.active;

  bool get _isLowStock =>
      product.stockCount < _lowStockThreshold && _isActive;

  String get _stockValue =>
      product.stockCount == 0 ? 'Not Set Yet' : '${product.stockCount} units';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s6,
        ),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          children: [
            // ── Top: image + info + 3-dot ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
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
                        child: const Icon(
                          Icons.image,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  // Name / price / badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: DesignTokens.mediumSemibold,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onMore != null)
                              GestureDetector(
                                onTap: onMore,
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.only(left: DesignTokens.s4),
                                  child: Icon(
                                    Icons.more_vert,
                                    size: 20,
                                    color: DesignTokens.iconLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          product.commissionRate != null
                              ? '${formatMoney(product.price)} · ${product.commissionRate!.toStringAsFixed(0)}% Commission'
                              : formatMoney(product.price),
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                        // Draft shows no badges
                        if (!_isDraft) ...[
                          const SizedBox(height: DesignTokens.s8),
                          Wrap(
                            spacing: DesignTokens.s6,
                            runSpacing: DesignTokens.s4,
                            children: [
                              _SalesBadge(count: product.totalSales),
                              if (_isLowStock) const _LowStockBadge(),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ── Divider ───────────────────────────────────────────────────
            Divider(
              height: 1,
              thickness: 1,
              color: DesignTokens.borderDefault.withValues(alpha: 0.4),
            ),
            // ── Stats ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s12,
              ),
              child: Column(
                children: [
                  // Draft and Active show In Stock; Out of Stock omits it
                  if (!_isOutOfStock) ...[
                    _StatRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'In Stock',
                      value: _stockValue,
                    ),
                    const SizedBox(height: DesignTokens.s8),
                  ],
                  // Draft hides Ratings and Featured in
                  if (!_isDraft) ...[
                    _StatRow(
                      icon: Icons.star_outline,
                      label: product.reviewCount != null
                          ? 'Ratings (${product.reviewCount} Reviews)'
                          : 'Ratings',
                      value: product.rating.toStringAsFixed(1),
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    _AssetStatRow(
                      assetIcon: 'assets/images/vendordashboard/icon_featured_in.png',
                      label: 'Featured in',
                      value: product.reelCount != null
                          ? '${product.reelCount} reels'
                          : '— reels',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class _SalesBadge extends StatelessWidget {
  const _SalesBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFB8E6FE),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 12,
            color: Color(0xFF0D1B2A),
          ),
          const SizedBox(width: DesignTokens.s4),
          Text(
            '$count sales this month',
            style: DesignTokens.tiny.copyWith(
              color: const Color(0xFF0D1B2A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockBadge extends StatelessWidget {
  const _LowStockBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF085),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_outlined,
            size: 12,
            color: Color(0xFF0D1B2A),
          ),
          const SizedBox(width: DesignTokens.s4),
          Text(
            'Low Stock',
            style: DesignTokens.tiny.copyWith(
              color: const Color(0xFF0D1B2A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat row ──────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s6),
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}

class _AssetStatRow extends StatelessWidget {
  const _AssetStatRow({
    required this.assetIcon,
    required this.label,
    required this.value,
  });

  final String assetIcon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(assetIcon, width: 14, height: 14, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s6),
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}
