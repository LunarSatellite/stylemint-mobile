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
    return Container(
      width: 280,
      padding: const EdgeInsets.all(DesignTokens.s8),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(DesignTokens.s12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: SizedBox(
              width: 64, height: 64,
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
          const SizedBox(width: DesignTokens.s12),
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
                MoneyText(product.price,
                    style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textLight)),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          GestureDetector(
            onTap: () => _addToCart(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                  vertical: DesignTokens.s6),
              decoration: BoxDecoration(
                color: DesignTokens.primaryGreen,
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
              ),
              child: Text('Add',
                  style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
