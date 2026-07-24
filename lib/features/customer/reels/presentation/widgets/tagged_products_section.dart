import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
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
    // Spec: "Tagged Product Card" — fixed 310px card width.
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: DesignTokens.s12),
        itemBuilder: (_, index) => _ProductTile(product: products[index]),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  const _ProductTile({required this.product});

  final TaggedProductEntity product;

  Future<void> _addToCart(BuildContext context, WidgetRef ref) async {
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    if (!context.mounted) return;
    final succeeded = await ref.read(cartNotifierProvider.notifier).addItem(
          productId: product.id,
          quantity: 1,
          idempotencyKey:
              'reel-atc-${product.id}-${DateTime.now().millisecondsSinceEpoch}',
        );
    if (!context.mounted) return;
    if (succeeded) {
      await context.push('/cart');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add to cart. Please try again.'),
          backgroundColor: DesignTokens.colorError,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openProduct(BuildContext context) =>
      context.push('/product/${product.id}');

  void _changeQuantity(WidgetRef ref, CartItem item, int delta) {
    final newQuantity = item.quantity + delta;
    if (newQuantity <= 0) {
      ref.read(cartNotifierProvider.notifier).removeItem(item.id);
    } else {
      ref.read(cartNotifierProvider.notifier).updateItem(
            itemId: item.id,
            quantity: newQuantity,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItem = ref.watch(cartNotifierProvider).maybeWhen(
          loadSuccess: (cart) {
            for (final item in cart.items) {
              if (item.productId == product.id) return item;
            }
            return null;
          },
          orElse: () => null,
        );
    final inCart = cartItem != null;
    // The blur lives in its own IgnorePointer'd layer, separate from the
    // interactive Row below — a GestureDetector/InkWell *nested inside* a
    // BackdropFilter can fail to receive touches (unlike the rail buttons
    // in reel_actions.dart, which wrap their BackdropFilter instead of
    // being wrapped by it).
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: SizedBox(
        width: 310,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333).withValues(alpha: 0.60),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(DesignTokens.s8),
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
              const SizedBox(width: DesignTokens.s8),
              // Tapping the name/price row also opens the product detail page.
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.textWhite),
                      ),
                      const SizedBox(height: 2),
                      MoneyText(
                        product.price,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              // Once it's in the cart, swap the "add" pill for a real
              // quantity stepper so +/- works right here instead of just
              // showing a static "added" icon that does nothing further. An
              // explicit green "In Cart" badge sits above it so the state is
              // obvious at a glance, not just implied by the stepper shape.
              if (inCart)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            size: 12, color: DesignTokens.primaryGreen),
                        const SizedBox(width: 3),
                        Text(
                          'In Cart',
                          style: DesignTokens.tiny
                              .copyWith(color: DesignTokens.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _QuantityStepper(
                      quantity: cartItem.quantity,
                      onDecrement: () => _changeQuantity(ref, cartItem, -1),
                      onIncrement: () => _changeQuantity(ref, cartItem, 1),
                    ),
                  ],
                )
              else
                // A real, filled pill button — not a text link — so it reads
                // instantly as "you can buy this right here."
                Material(
                  color: DesignTokens.primaryGreen,
                  borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
                    onTap: () => _addToCart(context, ref),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s12,
                        vertical: DesignTokens.s8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(DesignTokens.buttonRadius),
                        boxShadow: [
                          BoxShadow(
                            color: DesignTokens.primaryGreen
                                .withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 18,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ),
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

// ─── QUANTITY STEPPER ─────────────────────────────────────────────────────────
// Replaces the "add" pill once a tagged product is in the cart — lets the
// customer adjust quantity (down to removal) without leaving the reel.
// Matches the subtle bordered-square stepper already established on the
// product detail page (_StepperButton), not a solid block of color — this
// card already carries a bold green "add" pill elsewhere in the row, so the
// in-cart state should read as quiet/settled, not compete with it.
class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepperSquare(icon: Icons.remove_rounded, onTap: onDecrement),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
          child: Text(
            '$quantity',
            style: DesignTokens.oneLinerSemibold
                .copyWith(color: DesignTokens.primaryGreen),
          ),
        ),
        _StepperSquare(icon: Icons.add_rounded, onTap: onIncrement),
      ],
    );
  }
}

class _StepperSquare extends StatelessWidget {
  const _StepperSquare({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.s8),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreenLight,
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            border: Border.all(color: DesignTokens.primaryGreen),
          ),
          child: Icon(icon, size: 14, color: DesignTokens.primaryGreen),
        ),
      ),
    );
  }
}
