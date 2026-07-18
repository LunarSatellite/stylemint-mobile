import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
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
    // Card fills the screen width minus 12px padding on each side so one
    // product is fully visible; additional products peek in from the right.
    final cardWidth = MediaQuery.of(context).size.width - 24;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: DesignTokens.s12),
        itemBuilder: (_, index) =>
            _ProductTile(product: products[index], ref: ref, width: cardWidth),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.ref,
    required this.width,
  });

  final TaggedProductEntity product;
  final WidgetRef ref;
  final double width;

  Future<void> _addToCart(BuildContext context) async {
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    await ref.read(cartNotifierProvider.notifier).addItem(
          productId: product.id,
          quantity: 1,
          idempotencyKey:
              'reel-atc-${product.id}-${DateTime.now().millisecondsSinceEpoch}',
        );
    if (context.mounted) await context.push('/cart');
  }

  void _openProduct(BuildContext context) =>
      context.push('/product/${product.id}');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(DesignTokens.s8),
          decoration: BoxDecoration(
            color: const Color(0xFF333333).withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Row(
            children: [
              // Tapping the image opens the product detail page.
              GestureDetector(
                onTap: () => _openProduct(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: product.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const ColoredBox(
                                color: DesignTokens.bgAppBodyLight),
                            errorWidget: (_, _, _) => const ColoredBox(
                                color: DesignTokens.bgAppBodyLight,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: DesignTokens.iconLight,
                                )),
                          )
                        : const ColoredBox(color: DesignTokens.bgAppBodyLight),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              // Tapping the name also opens the product detail page.
              Expanded(
                child: GestureDetector(
                  onTap: () => _openProduct(context),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.textWhite),
                      ),
                      const SizedBox(height: DesignTokens.s4),
                      MoneyText(
                        product.price,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
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
