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
        title: const Text('Your Cart', style: DesignTokens.sectionInnerTitle),
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
                  child: ListView(
                    children: [
                      ...List.generate(cart.items.length, (i) {
                        return CartItemTile(
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
                        );
                      }),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(DesignTokens.s16, 0,
                            DesignTokens.s16, DesignTokens.s8),
                        child: _PromoRow(),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16),
                        child: _BillDetailsCard(cart: cart),
                      ),
                      if (cart.supportedCreatorsCount > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              DesignTokens.s16,
                              DesignTokens.s12,
                              DesignTokens.s16,
                              DesignTokens.s16),
                          child: _AppreciatedContainer(
                            creatorCount: cart.supportedCreatorsCount,
                          ),
                        ),
                    ],
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

// "Have a Promo Code?" row.
class _PromoRow extends StatelessWidget {
  const _PromoRow();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO(cart): open the promo-code entry sheet (Apply Promo Code spec).
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.s12, horizontal: DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          children: [
            const Icon(Icons.local_offer_outlined,
                size: 16, color: DesignTokens.iconLight),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text('Have a Promo Code?',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textWhite)),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: DesignTokens.iconLight),
          ],
        ),
      ),
    );
  }
}

// Bill Details card — Sub Total / Shipping / Tax / Grand Total.
class _BillDetailsCard extends StatelessWidget {
  const _BillDetailsCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final shipping = cart.shippingTotal.amount <= 0
        ? 'Free'
        : formatMoney(cart.shippingTotal);
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.s16, horizontal: DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill Details', style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          _BillRow(
              label: 'Sub Total (${cart.items.length} items)',
              value: formatMoney(cart.subtotal)),
          const SizedBox(height: DesignTokens.s8),
          _BillRow(label: 'Shipping', value: shipping),
          const SizedBox(height: DesignTokens.s8),
          _BillRow(
              label: 'Tax (Estimated 13%)', value: formatMoney(cart.taxTotal)),
          const Divider(
              color: DesignTokens.borderDefault, height: DesignTokens.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total',
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.textWhite)),
              Text(formatMoney(cart.total),
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: DesignTokens.textWhite,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textLight)),
        Text(value,
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textLight)),
      ],
    );
  }
}

// "You are appreciated" container.
// creatorCount = cart.supportedCreatorsCount (backend
// CartAppreciationSummaryDto.supportedCreatorsCount).
class _AppreciatedContainer extends StatelessWidget {
  const _AppreciatedContainer({required this.creatorCount});

  final int creatorCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite, size: 16, color: DesignTokens.primaryGreen),
              const SizedBox(width: DesignTokens.s8),
              Text('You are appreciated',
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.textWhite)),
            ],
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Thank you so much! you are supporting $creatorCount creators with this order',
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textLight, height: 1.4),
          ),
        ],
      ),
    );
  }
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
                  'Proceed to checkout',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
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
