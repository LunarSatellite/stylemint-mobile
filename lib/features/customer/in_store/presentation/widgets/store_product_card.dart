import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A product on the store screen's grid: the kit's typographic ground, the
/// name and the price. Never a product photograph — the Mall is video-first.
class StoreProductCard extends StatelessWidget {
  const StoreProductCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  final StoreProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.s12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The Mall is video-first: a product photograph belongs to
            // product detail (owner directive, 2026-09-16). A store product
            // carries no reel of its own, so it gets the kit's typographic
            // ground — seeded on the product id, so the same item wears the
            // same face on every surface it appears on.
            Expanded(
              child: MallTypeGround(
                seed: product.id,
                monogram: product.name.trim().isEmpty
                    ? null
                    : product.name.trim()[0].toUpperCase(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    formatMoney(product.price),
                    style: DesignTokens.oneLinerSemibold,
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
