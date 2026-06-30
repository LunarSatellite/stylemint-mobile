import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/notifiers/checkout_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const _uuid = Uuid();

  PaymentMethod? _selectedPayment;
  ShippingAddress? _selectedAddress;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutNotifierProvider);

    ref.listen<CheckoutState>(checkoutNotifierProvider, (previous, next) {
      next.maybeWhen(
        loadSuccess: (summary, _) {
          if (_selectedPayment == null) {
            setState(() => _selectedPayment = summary.paymentMethod);
          }
          if (_selectedAddress == null) {
            setState(() => _selectedAddress = summary.shippingAddress);
          }
        },
        loadFailure: (failure, _) {},
        orElse: () {},
      );

      next.placeOrderState.maybeWhen(
        success: (orderId) {
          context.pushReplacement(
            RouteNames.orderSuccess.replaceAll(':orderId', orderId),
          );
        },
        failure: (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Order failed: ${failure.runtimeType}'),
              backgroundColor: DesignTokens.colorError,
            ),
          );
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
        title: const Text('Checkout', style: DesignTokens.sectionInnerTitle),
        centerTitle: false,
      ),
      body: state.when(
        initial: (p) => _loader(placeOrderState: p),
        loadInProgress: (p) => _loader(placeOrderState: p),
        loadSuccess: (summary, placeOrderState) {
          final effectiveAddress = _selectedAddress ?? summary.shippingAddress;
          final hasAddress =
              effectiveAddress.line1.trim().isNotEmpty;
          final isProcessing = placeOrderState.maybeWhen(
            processing: () => true,
            orElse: () => false,
          );
          final selectedPayment = _selectedPayment ?? summary.paymentMethod;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  children: [
                    // ── Shipping address ───────────────────────────────
                    _ShippingAddressCard(
                      address: effectiveAddress,
                      hasAddress: hasAddress,
                      onAddAddress: () => _showAddAddressSheet(context),
                      onChangeAddress: () =>
                          _showPickAddressSheet(context, summary),
                    ),
                    const SizedBox(height: DesignTokens.s16),

                    // ── Bill details ticket card ───────────────────────
                    _BillTicketCard(
                      summary: summary,
                      onSubTotalTap: () =>
                          _showCartItemsSheet(context, summary),
                    ),
                    const SizedBox(height: DesignTokens.s24),

                    // ── Payment method list ────────────────────────────
                    Text('Payment Method',
                        style: DesignTokens.sectionInnerTitle),
                    const SizedBox(height: DesignTokens.s12),
                    _PaymentMethodList(
                      availableMethods: _buildPaymentMethods(summary),
                      selectedMethod: selectedPayment,
                      onSelect: (method) =>
                          setState(() => _selectedPayment = method),
                    ),
                    const SizedBox(height: DesignTokens.s32),
                  ],
                ),
              ),
              _BottomBar(
                hasAddress: hasAddress,
                isProcessing: isProcessing,
                onAddAddress: () => _showAddAddressSheet(context),
                onPlaceOrder: () {
                  ref.read(checkoutNotifierProvider.notifier).placeOrder(
                    addressId: effectiveAddress.id,
                    paymentMethodId: selectedPayment.id,
                    idempotencyKey: _uuid.v4(),
                  );
                },
              ),
            ],
          );
        },
        loadFailure: (failure, _) => SmErrorView(
          message: 'Failed to load checkout details.',
          onRetry: () => ref.read(checkoutNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  List<PaymentMethod> _buildPaymentMethods(CheckoutSummary summary) {
    // Use the full list loaded from the payment-methods API when available.
    if (summary.availablePaymentMethods.isNotEmpty) {
      return summary.availablePaymentMethods;
    }
    // Fallback: show only the default payment method from the summary.
    return [summary.paymentMethod];
  }

  // ── CART ITEMS SHEET ──────────────────────────────────────────────────────
  void _showCartItemsSheet(BuildContext context, CheckoutSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CartItemsSheet(summary: summary),
    );
  }

  // ── ADDRESS PICKER SHEET ──────────────────────────────────────────────────
  void _showPickAddressSheet(BuildContext context, CheckoutSummary summary) {
    final addresses = summary.availableAddresses.isNotEmpty
        ? summary.availableAddresses
        : [summary.shippingAddress];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickAddressSheet(
        addresses: addresses,
        selectedAddress: _selectedAddress ?? summary.shippingAddress,
        onSelect: (address) {
          Navigator.pop(context);
          setState(() => _selectedAddress = address);
        },
        onAddNew: () {
          Navigator.pop(context);
          _showAddAddressSheet(context);
        },
      ),
    );
  }

  // ── ADD ADDRESS SHEET ─────────────────────────────────────────────────────
  void _showAddAddressSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.bgAppBody,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddAddressSheet(
        onSaved: () {
          Navigator.pop(context);
          ref.read(checkoutNotifierProvider.notifier).load();
        },
      ),
    );
  }

  Widget _loader({
    PlaceOrderState placeOrderState = const PlaceOrderState.initial(),
  }) {
    final isProcessing = placeOrderState.maybeWhen(
      processing: () => true,
      orElse: () => false,
    );
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: DesignTokens.primaryGreen),
          if (isProcessing) ...[
            const SizedBox(height: DesignTokens.s16),
            Text(
              'Placing your order...',
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SHIPPING ADDRESS CARD ────────────────────────────────────────────────────
// No address  → _NoAddressCard (truck prompt + "+" button)
// Has address → display card, tappable → opens address picker sheet
class _ShippingAddressCard extends StatelessWidget {
  const _ShippingAddressCard({
    required this.address,
    required this.hasAddress,
    required this.onAddAddress,
    required this.onChangeAddress,
  });

  final ShippingAddress address;
  final bool hasAddress;
  final VoidCallback onAddAddress;
  final VoidCallback onChangeAddress;

  @override
  Widget build(BuildContext context) {
    if (!hasAddress) {
      return _NoAddressCard(onAdd: onAddAddress);
    }

    final addressLine = StringBuffer()..write(address.line1);
    if (address.line2 != null && address.line2!.isNotEmpty) {
      addressLine.write(', ${address.line2}');
    }
    addressLine.write(', ${address.city}');
    if (address.stateProvince != null) addressLine.write(', ${address.stateProvince}');
    if (address.postalCode != null) addressLine.write(' ${address.postalCode}');

    return GestureDetector(
      onTap: onChangeAddress,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.primaryGreenLight,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: const Icon(Icons.location_on_outlined,
                  color: DesignTokens.primaryGreen),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: DesignTokens.oneLinerSemibold
                            .copyWith(color: DesignTokens.textWhite),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: DesignTokens.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s8, vertical: 2),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryGreenLight,
                            borderRadius: BorderRadius.circular(
                                DesignTokens.buttonRadius),
                          ),
                          child: Text(
                            'Default',
                            style: DesignTokens.tiny
                                .copyWith(color: DesignTokens.primaryGreen),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    addressLine.toString(),
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: DesignTokens.iconLight),
          ],
        ),
      ),
    );
  }
}

class _NoAddressCard extends StatelessWidget {
  const _NoAddressCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.s12, horizontal: DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.s8),
            decoration: BoxDecoration(
              color: const Color(0xFF3A2F03),
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                size: 28, color: DesignTokens.secondaryYellow),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shipping Address',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You're almost there! Add a shipping address to continue.",
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          GestureDetector(
            onTap: onAdd,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: DesignTokens.buttonGrayFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add_rounded,
                  size: 20, color: DesignTokens.textWhite),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BILL TICKET CARD ─────────────────────────────────────────────────────────
class _BillTicketCard extends StatelessWidget {
  const _BillTicketCard({
    required this.summary,
    required this.onSubTotalTap,
  });

  final CheckoutSummary summary;
  final VoidCallback onSubTotalTap;

  static const _scallopsRadius = 9.0;
  static const _cardRadius = 16.0;
  static const _topColor = DesignTokens.bgAppBody;
  static const _stubColor = Color(0xFF2A2A2A);

  @override
  Widget build(BuildContext context) {
    final isFreeShipping = summary.shipping.amount <= 0;
    final hasDiscount = summary.discount.amount > 0;
    final pageColor = DesignTokens.bgAppFoundation;

    return Container(
      decoration: BoxDecoration(
        color: _topColor,
        borderRadius: BorderRadius.circular(_cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill Details',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // Sub Total — tappable, opens cart items sheet
                GestureDetector(
                  onTap: onSubTotalTap,
                  behavior: HitTestBehavior.opaque,
                  child: _BillRow(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Sub Total (${summary.items.length} items)',
                    value: formatMoney(summary.subtotal),
                    // Underline the label to hint it's tappable
                    labelUnderline: true,
                  ),
                ),
                const SizedBox(height: 12),

                _BillRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Shipping',
                  valueBadge: isFreeShipping ? 'Free' : null,
                  value: isFreeShipping ? null : formatMoney(summary.shipping),
                ),
                const SizedBox(height: 12),

                _BillRow(
                  icon: Icons.percent_rounded,
                  label: 'Tax (Estimated 13%)',
                  value: formatMoney(summary.tax),
                ),

                if (hasDiscount) ...[
                  const SizedBox(height: 12),
                  _BillRow(
                    icon: Icons.local_offer_outlined,
                    label: 'Promo Code Discount',
                    value: '-${formatMoney(summary.discount)}',
                    valueColor: const Color(0xFFFF6467),
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
                    Text(
                      'Grand Total',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatMoney(summary.total),
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

          // Scalloped divider
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

          // Appreciation stub
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
                  child: const Icon(Icons.favorite,
                      size: 22, color: Colors.white),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thank you so much! you are supporting the creators with this order',
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
    required this.icon,
    required this.label,
    this.value,
    this.valueBadge,
    this.valueColor,
    this.labelUnderline = false,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String? valueBadge;
  final Color? valueColor;
  final bool labelUnderline;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DesignTokens.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
              fontSize: 13,
              decoration:
              labelUnderline ? TextDecoration.underline : TextDecoration.none,
              decorationColor: DesignTokens.textLight,
            ),
          ),
        ),
        if (valueBadge != null)
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              valueBadge!,
              style: DesignTokens.smallRegular.copyWith(
                fontSize: 12,
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
              fontSize: 13,
            ),
          ),
      ],
    );
  }
}

// ─── PAYMENT ICON ─────────────────────────────────────────────────────────────
class _PaymentIcon extends StatelessWidget {
  const _PaymentIcon({required this.type});

  final PaymentMethodType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.s8),
      ),
      alignment: Alignment.center,
      child: _logo(),
    );
  }

  Widget _logo() {
    switch (type) {
      case PaymentMethodType.card:
        return const Text(
          'VISA',
          style: TextStyle(
            color: Color(0xFF1A1F71),
            fontWeight: FontWeight.w900,
            fontSize: 13,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        );
      case PaymentMethodType.eSewa:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(DesignTokens.s8),
          ),
          alignment: Alignment.center,
          child: const Text(
            'e-',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        );
      case PaymentMethodType.paypal:
        return const Text(
          'Pay\nPal',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF009CDE),
            fontWeight: FontWeight.w900,
            fontSize: 11,
            height: 1.1,
          ),
        );
      case PaymentMethodType.cod:
        return const Icon(
          Icons.payments_outlined,
          color: Color(0xFF4CAF50),
          size: 24,
        );
    }
  }
}

// ─── PAYMENT METHOD LIST ──────────────────────────────────────────────────────
class _PaymentMethodList extends StatelessWidget {
  const _PaymentMethodList({
    required this.availableMethods,
    required this.selectedMethod,
    required this.onSelect,
  });

  final List<PaymentMethod> availableMethods;
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onSelect;

  String _subtitleFor(PaymentMethod m) {
    switch (m.type) {
      case PaymentMethodType.card:
        return m.lastFour != null
            ? 'Visa ending in ${m.lastFour}'
            : 'Credit / Debit card';
      case PaymentMethodType.paypal:
        return m.lastFour != null ? 'PayPal (${m.lastFour})' : 'PayPal';
      case PaymentMethodType.eSewa:
        return 'eSewa wallet';
      case PaymentMethodType.cod:
        return 'Pay on delivery';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: List.generate(availableMethods.length, (i) {
          final method = availableMethods[i];
          final isSelected = selectedMethod.id == method.id;
          final isLast = i == availableMethods.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => onSelect(method),
                borderRadius:
                BorderRadius.circular(DesignTokens.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s12),
                  child: Row(
                    children: [
                      _PaymentIcon(type: method.type),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              method.label,
                              style: DesignTokens.oneLinerSemibold
                                  .copyWith(color: DesignTokens.textWhite),
                            ),
                            Text(
                              _subtitleFor(method),
                              style: DesignTokens.smallRegular.copyWith(
                                  color: DesignTokens.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? DesignTokens.primaryGreen
                                : DesignTokens.borderDefault,
                            width: isSelected ? 5 : 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: DesignTokens.borderDefault,
                  indent: DesignTokens.s16,
                  endIndent: DesignTokens.s16,
                ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── BOTTOM BAR ───────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.hasAddress,
    required this.isProcessing,
    required this.onAddAddress,
    required this.onPlaceOrder,
  });

  final bool hasAddress;
  final bool isProcessing;
  final VoidCallback onAddAddress;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(DesignTokens.s16,
          DesignTokens.s12, DesignTokens.s16, DesignTokens.s16),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
            top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      child: SafeArea(
        child: hasAddress ? _placeOrderRow() : _addAddressButton(),
      ),
    );
  }

  Widget _addAddressButton() {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryGreen,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26)),
        ),
        onPressed: onAddAddress,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Add Shipping Address',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.add_rounded, size: 20, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _placeOrderRow() {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: ElevatedButton(
        style: DesignTokens.primaryButtonStyle(),
        onPressed: isProcessing ? null : onPlaceOrder,
        child: isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DesignTokens.buttonPrimaryText,
                ),
              )
            : const Text(
                'Place Order',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ─── CART ITEMS SHEET ─────────────────────────────────────────────────────────
// Opens when tapping Sub Total — shows all cart items with image, name,
// variant, qty badge and price. Matches Image 1.
class _CartItemsSheet extends StatelessWidget {
  const _CartItemsSheet({required this.summary});

  final CheckoutSummary summary;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Cart Items(${summary.items.length})',
                  style: DesignTokens.sectionInnerTitle,
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: DesignTokens.textWhite, size: 22),
                ),
              ],
            ),
          ),
          // Item list
          Expanded(
            child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: summary.items.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                thickness: 1,
                color: DesignTokens.borderDefault,
              ),
              itemBuilder: (_, i) =>
                  _CartItemRow(item: summary.items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({required this.item});

  final CheckoutItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Image.network(
              item.imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(Icons.image_not_supported_outlined,
                    color: DesignTokens.iconLight, size: 22),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),

          // Name + variant + from
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.variantName,
                  style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 3),
                // "From: @handle (commission%)" — derived from variantName
                // In real app this comes from item.sellerHandle etc.
                Text(
                  'From: ${item.variantName}',
                  style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),

          // Qty badge + price (right column)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Qty pill badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A5C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(
                    color: Color(0xFF4FC3F7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(item.unitPrice),
                style: DesignTokens.oneLinerSemibold.copyWith(
                  color: DesignTokens.textWhite,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PICK ADDRESS SHEET ───────────────────────────────────────────────────────
// Opens when tapping an existing address — shows current address(es) with
// "Selected" badge + "Add New Shipping Address +" button. Matches Image 2.
class _PickAddressSheet extends StatelessWidget {
  const _PickAddressSheet({
    required this.addresses,
    required this.selectedAddress,
    required this.onSelect,
    required this.onAddNew,
  });

  final List<ShippingAddress> addresses;
  final ShippingAddress selectedAddress;
  final ValueChanged<ShippingAddress> onSelect;
  final VoidCallback onAddNew;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Choose a Shipping Address',
                  style: DesignTokens.sectionInnerTitle),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close,
                    color: DesignTokens.textWhite, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // All saved addresses — tapping one selects it and closes the sheet
          ...addresses.map((addr) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _AddressPickerRow(
                  address: addr,
                  isSelected: addr.id == selectedAddress.id,
                  onTap: () => onSelect(addr),
                ),
              )),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: DesignTokens.buttonHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26)),
              ),
              onPressed: onAddNew,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add New Shipping Address',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.add_rounded, size: 20, color: Colors.black),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressPickerRow extends StatelessWidget {
  const _AddressPickerRow({
    required this.address,
    required this.isSelected,
    required this.onTap,
  });

  final ShippingAddress address;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final line = StringBuffer()..write(address.line1);
    if (address.line2 != null && address.line2!.isNotEmpty) {
      line.write(', ${address.line2}');
    }
    line.write(', ${address.city}');
    if (address.stateProvince != null) line.write(', ${address.stateProvince}');

    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location icon box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            child: const Icon(Icons.location_on_outlined,
                color: DesignTokens.textMuted, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.label,
                      style: DesignTokens.oneLinerSemibold
                          .copyWith(color: DesignTokens.textWhite),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3A5C),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Selected',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4FC3F7),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  line.toString(),
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 12,
                    height: 1.4,
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

// ─── ADD SHIPPING ADDRESS SHEET ───────────────────────────────────────────────
class _AddAddressSheet extends StatefulWidget {
  const _AddAddressSheet({required this.onSaved});

  final VoidCallback onSaved;

  @override
  State<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends State<_AddAddressSheet> {
  final _line1Ctrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  String? _selectedCountry;
  String? _selectedState;

  static const _fill = Color(0xFF2C2C2C);

  InputDecoration _dec(String hint) => InputDecoration(
    filled: true,
    fillColor: _fill,
    hintText: hint,
    hintStyle:
    const TextStyle(color: Color(0xFF666666), fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  void dispose() {
    _line1Ctrl.dispose();
    _landmarkCtrl.dispose();
    _zipCtrl.dispose();
    _cityCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: DesignTokens.textWhite, fontSize: 14);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Shipping Address',
                    style: DesignTokens.sectionInnerTitle),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: DesignTokens.textWhite, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
                controller: _line1Ctrl,
                style: style,
                decoration: _dec('Address Line 1')),
            const SizedBox(height: 12),
            TextField(
                controller: _landmarkCtrl,
                style: style,
                decoration: _dec('Nearest Landmark (Optional)')),
            const SizedBox(height: 12),
            _Dropdown(
              hint: 'Country',
              value: _selectedCountry,
              items: const ['Nepal', 'India', 'USA', 'UK'],
              onChanged: (v) => setState(() => _selectedCountry = v),
            ),
            const SizedBox(height: 12),
            _Dropdown(
              hint: 'State/Province',
              value: _selectedState,
              items: const [
                'Bagmati',
                'Gandaki',
                'Lumbini',
                'Koshi',
                'Madhesh'
              ],
              onChanged: (v) => setState(() => _selectedState = v),
            ),
            const SizedBox(height: 12),
            TextField(
                controller: _zipCtrl,
                style: style,
                keyboardType: TextInputType.number,
                decoration: _dec('Zip/Postal Code')),
            const SizedBox(height: 12),
            TextField(
                controller: _cityCtrl,
                style: style,
                decoration: _dec('City')),
            const SizedBox(height: 12),
            TextField(
                controller: _labelCtrl,
                style: style,
                decoration: _dec('Save Address As')),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                ),
                onPressed: widget.onSaved,
                child: const Text(
                  'Save Address',
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
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C2C2C),
          hint: Text(hint,
              style: const TextStyle(
                  color: Color(0xFF666666), fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF666666)),
          items: items
              .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e,
                style: const TextStyle(
                    color: DesignTokens.textWhite, fontSize: 14)),
          ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
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