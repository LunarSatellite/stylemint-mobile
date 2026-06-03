import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Horizontal strip of products tagged on a reel. Each tile shows the
/// product image, name, price and an "Add to Cart" button gated through the
/// shared [ensureAuth].
class TaggedProductsSection extends ConsumerWidget {
  const TaggedProductsSection({required this.products, super.key});

  final List<TaggedProductEntity> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: DesignTokens.s12),
        itemBuilder: (_, index) =>
            _ProductTile(product: products[index], ref: ref),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.ref});

  final TaggedProductEntity product;
  final WidgetRef ref;

  Future<void> _addToCart(BuildContext context) async {
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    // TODO(cart): add [product] to the cart once authenticated.
  }

  @override
  Widget build(BuildContext context) {
    // Spec: 310px card, rgba(51,51,51,0.6) + backdrop blur(20), 16px radius.
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
      width: 310,
      padding: const EdgeInsets.all(DesignTokens.s8),
      decoration: BoxDecoration(
        color: const Color(0xFF333333).withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s12),
            child: SizedBox(
              width: 72, height: 72,
              child: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(
                          color: DesignTokens.bgAppBodyLight),
                      errorWidget: (_, _, _) => const ColoredBox(
                          color: DesignTokens.bgAppBodyLight,
                          child: Icon(Icons.image_not_supported_outlined,
                              color: DesignTokens.iconLight)),
                    )
                  : const ColoredBox(color: DesignTokens.bgAppBodyLight),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite)),
                const SizedBox(height: DesignTokens.s4),
                // Spec: price 14/600/130%, #D4D4D8, right-aligned.
                MoneyText(product.price,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: DesignTokens.textLight,
                    )),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          // Spec: "Add to Cart" underlined green text link (not a filled pill).
          GestureDetector(
            onTap: () => _addToCart(context),
            child: const Text(
              'Add to Cart',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.2,
                color: DesignTokens.primaryGreen,
                decoration: TextDecoration.underline,
                decorationColor: DesignTokens.primaryGreen,
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
