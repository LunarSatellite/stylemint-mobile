import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The facts above a product's name on the details page: its rating, free
/// delivery, the saving, and a flash sale's live deadline.
///
/// Every badge here is conditional, and each condition is the field that
/// would make the claim true. It was not always so: the rating badge was
/// unconditional, so a product the catalogue had never reviewed opened
/// wearing "0.0 Stars".
///
/// It lived inside `product_detail_screen.dart` as a private widget. It is
/// its own file so the honesty rules above can be tested directly instead of
/// through a screen that needs a dozen providers to stand up.
class ProductBadgesRow extends StatelessWidget {
  const ProductBadgesRow({required this.product, super.key, this.now});

  final ProductDetail product;

  /// Clock behind the flash-sale countdown; tests pin it.
  final DateTime Function()? now;

  /// The discount, **floored**, the way `MallProductVm.discountPercent`
  /// floors it. This used to round, so a product at 19.6% off was a "20% Off"
  /// badge here and a "-19%" pill on the tile that opened it — the same
  /// product claiming two different savings one tap apart.
  int? get discountPercent {
    final was = product.compareAtPrice;
    if (was == null || was.amount <= 0) return null;
    final percent = ((1 - product.price.amount / was.amount) * 100).floor();
    return percent > 0 ? percent : null;
  }

  @override
  Widget build(BuildContext context) {
    final discountPct = discountPercent;
    final endsAt = product.flashSaleEndsAt;

    return Wrap(
      spacing: DesignTokens.s8,
      runSpacing: DesignTokens.s6,
      children: [
        // A rating, only where the catalogue has one.
        if (product.reviewCount > 0 && product.rating > 0)
          ProductBadge(
            icon: Icons.star_rounded,
            iconColor: DesignTokens.secondaryYellow,
            label: product.rating.toStringAsFixed(1),
            spokenLabel: 'Rated ${product.rating.toStringAsFixed(1)} out of 5',
          ),
        // Only when an enabled delivery option really is free.
        if (product.delivery?.hasFreeDelivery ?? false)
          const ProductBadge(
            icon: Icons.local_shipping_outlined,
            iconColor: DesignTokens.primaryGreen,
            label: 'Free Delivery',
          ),
        if (discountPct != null)
          ProductBadge(
            icon: Icons.sell_outlined,
            iconColor: DesignTokens.primaryGreen,
            label: '$discountPct% Off',
          ),
        // The kit's live countdown. The old badge formatted the remaining
        // time once, at build, so "ends in 2h" sat there saying 2h for the
        // next two hours and stayed on screen after the sale had ended.
        if (endsAt != null)
          MallCountdown(
            endsUtc: endsAt,
            now: now,
            builder: (context, remaining) => remaining == null
                ? const SizedBox.shrink()
                : ProductBadge(
                    icon: Icons.bolt_rounded,
                    iconColor: DesignTokens.colorError,
                    label: 'Flash Sale · ends in ${remaining.text}',
                    spokenLabel: 'Flash sale ends in ${remaining.spoken}',
                  ),
          ),
      ],
    );
  }
}

/// One fact, never a control: a glyph, a word, one spoken node, no tap
/// target.
class ProductBadge extends StatelessWidget {
  const ProductBadge({
    required this.icon,
    required this.iconColor,
    required this.label,
    super.key,
    this.spokenLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  /// What a screen reader says instead of [label], for a badge whose display
  /// form is compressed (a countdown's "4h 12m", a bare "4.6").
  final String? spokenLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: spokenLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8,
          vertical: DesignTokens.s4,
        ),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: DesignTokens.s4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                  fontFeatures: mallTabularFigures,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
