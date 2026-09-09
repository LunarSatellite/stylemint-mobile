import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/widgets/cart_item_tile.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── CART SCREEN ──────────────────────────────────────────────────────────────
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  Future<void> _openPromoSheet() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PromoBottomSheet(),
    );
    if (code != null && code.isNotEmpty) {
      final applied = await ref
          .read(cartNotifierProvider.notifier)
          .applyPromo(code);
      if (!mounted || applied) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to apply that promo code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cartNotifierProvider);

    ref.listen<CartState>(cartNotifierProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: (cart) {
          final hadItems = previous?.maybeWhen(
                loadSuccess: (c) => c.items.isNotEmpty,
                orElse: () => false,
              ) ??
              false;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
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
                    padding: const EdgeInsets.only(bottom: DesignTokens.s16),
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
                              ref
                                  .read(cartNotifierProvider.notifier)
                                  .updateItem(
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
                          onSaveForLater: () {
                            ref
                                .read(cartNotifierProvider.notifier)
                                .saveForLater(cart.items[i].id);
                          },
                        );
                      }),
                      // Promo pill
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            DesignTokens.s16,
                            DesignTokens.s16,
                            DesignTokens.s16,
                            DesignTokens.s12),
                        child: _PromoRow(
                          appliedCode: cart.appliedPromoCode?.code,
                          onTap: _openPromoSheet,
                        ),
                      ),
                      // Ticket card: bill details + scallop + appreciation stub
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16),
                        child: _TicketCard(
                          cart: cart,
                          promoCode: cart.appliedPromoCode?.code,
                          promoDiscount: cart.appliedPromoCode?.discount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _CheckoutBar(
                cart: cart,
                onCheckout: () => context.push(RouteNames.checkout),
              ),
            ],
          );
        },
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load your cart.',
          onRetry: () => ref.read(cartNotifierProvider.notifier).fetchCart(),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

// ─── PROMO PILL ───────────────────────────────────────────────────────────────
class _PromoRow extends StatelessWidget {
  const _PromoRow({required this.onTap, this.appliedCode});

  final VoidCallback onTap;
  final String? appliedCode;

  bool get _applied => appliedCode != null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: DesignTokens.primaryGreen, width: 1.5),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _applied ? 'Promo Code Applied' : 'Have a Promo Code?',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _applied
                    ? Icons.check_circle_outline_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: 13,
                color: DesignTokens.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TICKET CARD ─────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.cart,
    this.promoCode,
    this.promoDiscount,
  });

  final Cart cart;
  final String? promoCode;
  final Money? promoDiscount;

  static const _scallopsRadius = 9.0;
  static const _cardRadius = 16.0;
  static const _topColor = DesignTokens.bgAppBody;
  static const _stubColor = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    final isFreeShipping = cart.shippingTotal.amount <= 0;
    final hasStub = cart.supportedCreatorsCount > 0;
    final pageColor = DesignTokens.bgAppFoundation;

    return Container(
      decoration: BoxDecoration(
        color: _topColor,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bill details ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bill Details',
                  style: DesignTokens.oneLinerSemibold,
                ),
                const SizedBox(height: 16),
                _BillRow(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Sub Total (${cart.items.length} items)',
                  value: formatMoney(cart.subtotal),
                ),
                const SizedBox(height: 12),
                _BillRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Shipping',
                  valueBadge: isFreeShipping ? 'Free' : null,
                  value: isFreeShipping
                      ? null
                      : formatMoney(cart.shippingTotal),
                ),
                const SizedBox(height: 12),
                _BillRow(
                  icon: Icons.percent_rounded,
                  label: 'Tax (Estimated 13%)',
                  value: formatMoney(cart.taxTotal),
                ),
                // Promo discount row — visible only when a code is applied
                if (promoDiscount != null) ...[
                  const SizedBox(height: 12),
                  _BillRow(
                    label: 'Promo Code (${promoCode!.toUpperCase()})',
                    value: '- ${formatMoney(promoDiscount!)}',
                    valueColor: DesignTokens.primaryGreen,
                    iconWidget: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.primaryGreen.withOpacity(0.15),
                        border: Border.all(
                            color: DesignTokens.primaryGreen, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.local_offer_rounded,
                        size: 11,
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 1,
                  width: double.infinity,
                  child: CustomPaint(painter: _DashedLinePainter()),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Grand Total',
                      style: DesignTokens.mediumSemibold,
                    ),
                    Text(
                      formatMoney(cart.total),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Scalloped divider ────────────────────────────────────────────
          if (hasStub)
            SizedBox(
              height: _scallopsRadius * 2,
              width: double.infinity,
              child: CustomPaint(
                painter: _ScallopPainter(
                  topColor: _topColor,
                  stubColor: _stubColor,
                  holeColor: pageColor,
                  radius: _scallopsRadius,
                ),
              ),
            ),

          // ── Appreciation stub ────────────────────────────────────────────
          if (hasStub)
            Container(
              decoration: const BoxDecoration(
                color: _stubColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(_cardRadius),
                  bottomRight: Radius.circular(_cardRadius),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.favorite, size: 22, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are appreciated',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thank you so much! you are supporting '
                          '${cart.supportedCreatorsCount} creators with this order',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── BILL ROW ─────────────────────────────────────────────────────────────────
class _BillRow extends StatelessWidget {
  const _BillRow({
    this.icon,
    this.iconWidget,
    required this.label,
    this.value,
    this.valueBadge,
    this.valueColor,
  }) : assert(icon != null || iconWidget != null,
            '_BillRow requires icon or iconWidget');

  final IconData? icon;
  final Widget? iconWidget;
  final String label;
  final String? value;
  final String? valueBadge;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Custom widget takes priority over IconData
        iconWidget ??
            Icon(icon!, size: 14, color: DesignTokens.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textWhite),
          ),
        ),
        if (valueBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: DesignTokens.primaryGreen,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              valueBadge!,
              style: DesignTokens.smallRegular.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          )
        else
          Text(
            value ?? '',
            style: DesignTokens.smallRegular.copyWith(
              color: valueColor ?? DesignTokens.textLight,
              fontSize: 12,
              fontWeight:
                  valueColor != null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
      ],
    );
  }
}

// ─── PAINTERS ─────────────────────────────────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.borderDefault
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const dashWidth = 6.0;
    const dashGap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}

class _ScallopPainter extends CustomPainter {
  const _ScallopPainter({
    required this.topColor,
    required this.stubColor,
    required this.holeColor,
    required this.radius,
  });

  final Color topColor;
  final Color stubColor;
  final Color holeColor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, radius),
        Paint()..color = topColor);
    canvas.drawRect(Rect.fromLTWH(0, radius, size.width, radius),
        Paint()..color = stubColor);
    final holePaint = Paint()
      ..color = holeColor
      ..style = PaintingStyle.fill;
    double x = radius;
    while (x <= size.width + radius) {
      canvas.drawCircle(Offset(x, radius), radius, holePaint);
      x += radius * 2;
    }
  }

  @override
  bool shouldRepaint(_ScallopPainter old) =>
      old.topColor != topColor ||
      old.stubColor != stubColor ||
      old.holeColor != holeColor ||
      old.radius != radius;
}

// ─── PROMO BOTTOM SHEET ───────────────────────────────────────────────────────
class _PromoBottomSheet extends StatefulWidget {
  const _PromoBottomSheet();

  @override
  State<_PromoBottomSheet> createState() => _PromoBottomSheetState();
}

class _PromoBottomSheetState extends State<_PromoBottomSheet> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final code = _controller.text.trim();
    if (code.isEmpty) return;
    setState(() => _loading = true);
    // Validation and discount calculation are performed by the Cart API.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.of(context).pop(code); // returns code to CartScreen
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, 24 + bottom),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enter your promo code',
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.textWhite,
                  fontSize: 20,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close,
                    size: 20, color: DesignTokens.textLight),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textWhite, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Promo Code',
              hintStyle: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted, fontSize: 14),
              filled: true,
              fillColor: DesignTokens.bgAppBodyLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              onPressed: _loading ? null : _apply,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : const Text(
                      'Apply',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── CHECKOUT BAR ─────────────────────────────────────────────────────────────
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart, required this.onCheckout});

  final Cart cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, DesignTokens.s16),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    size: 18, color: DesignTokens.textWhite),
                const SizedBox(width: DesignTokens.s8),
                const Text('Total Order', style: DesignTokens.mediumSemibold),
                const Spacer(),
                Text(formatMoney(cart.total),
                    style: DesignTokens.oneLinerSemibold
                        .copyWith(color: DesignTokens.textWhite)),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                ),
                onPressed: onCheckout,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Proceed to checkout',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ),
                    SizedBox(width: DesignTokens.s8),
                    Icon(Icons.arrow_forward_rounded,
                        size: 18, color: DesignTokens.buttonPrimaryText),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
