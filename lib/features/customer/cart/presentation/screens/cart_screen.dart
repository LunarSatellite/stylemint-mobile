import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/widgets/cart_item_tile.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cartNotifierProvider);

    ref.listen<CartState>(cartNotifierProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: (cart) {
          final hadItems = previous?.maybeWhen(
            loadSuccess: (c) => c.items.isNotEmpty,
            orElse: () => false,
          ) ?? false;
          if (cart.items.isEmpty && hadItems) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item removed from cart')),
            );
          }
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('My Cart', style: DesignTokens.titleLarge),
        centerTitle: false,
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (cart) {
          if (cart.items.isEmpty) {
            return const SmEmptyState(
              message: 'Your cart is empty. Start shopping!',
              icon: Icons.shopping_cart_outlined,
            );
          }
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: DesignTokens.primaryGreen,
                  onRefresh: () =>
                      ref.read(cartNotifierProvider.notifier).fetchCart(),
                  child: ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (_, i) => CartItemTile(
                      item: cart.items[i],
                      onIncrement: () {
                        ref.read(cartNotifierProvider.notifier).updateItem(
                              itemId: cart.items[i].id,
                              quantity: cart.items[i].quantity + 1,
                            );
                      },
                      onDecrement: () {
                        final newQty = cart.items[i].quantity - 1;
                        if (newQty <= 0) {
                          ref
                              .read(cartNotifierProvider.notifier)
                              .removeItem(cart.items[i].id);
                        } else {
                          ref.read(cartNotifierProvider.notifier).updateItem(
                                itemId: cart.items[i].id,
                                quantity: newQty,
                              );
                        }
                      },
                      onDelete: () {
                        ref
                            .read(cartNotifierProvider.notifier)
                            .removeItem(cart.items[i].id);
                      },
                    ),
                  ),
                ),
              ),
              _CheckoutBar(cart: cart),
            ],
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load your cart.',
          onRetry: () =>
              ref.read(cartNotifierProvider.notifier).fetchCart(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: const Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        formatMoney(cart.total),
                        style: DesignTokens.oneLinerSemibold.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      Text(
                        ' (${cart.items.length} item${cart.items.length == 1 ? '' : 's'})',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (cart.shippingTotal.amount > 0)
                    Text(
                      'incl. ${formatMoney(cart.shippingTotal)} shipping',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                style: DesignTokens.primaryButtonStyle(),
                onPressed: () => context.push(RouteNames.checkout),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
