import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/presentation/notifiers/checkout_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:url_launcher/url_launcher.dart';
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
          // Re-pick the default whenever nothing real is selected yet — not
          // just on the very first load. A reload after saving a new address
          // (there were none before) must not be blocked by an earlier
          // "selected" sentinel empty address from before any existed.
          if (_selectedPayment == null || _selectedPayment!.id.isEmpty) {
            setState(() => _selectedPayment = summary.paymentMethod);
          }
          if (_selectedAddress == null || _selectedAddress!.id.isEmpty) {
            setState(() => _selectedAddress = summary.shippingAddress);
          }
        },
        loadFailure: (failure, _) {},
        orElse: () {},
      );

      next.placeOrderState.maybeWhen(
        success: (orderId) async {
          // The backend clears the cart server-side once the order is
          // placed, but the client's cart state is a singleton that's
          // never told to re-fetch — without this, the just-ordered
          // item kept showing in "Your Cart" (and the tab badge) until
          // some unrelated mutation happened to refresh it, even though
          // it was already the subject of a completed order.
          ref.read(cartNotifierProvider.notifier).fetchCart();

          // PayPal/eSewa/Card: the order exists but is NOT paid yet — the
          // customer still has to complete the provider's payment page.
          // Send them there before ever showing an order-success screen;
          // showing it unconditionally (as this app used to) falsely
          // confirmed purchases that were never actually charged, leaving
          // the vendor with an order stuck at Pending forever. The
          // provider's webhook (not this client) is what actually marks
          // the order paid, so this is a best-effort hand-off, not a wait
          // for confirmation.
          final placed = ref
              .read(checkoutNotifierProvider.notifier)
              .lastPlaceOrderResult;
          final redirectUrl = placed?.paymentRedirectUrl;
          final paymentPending = placed?.requiresPaymentAction == true;
          if (paymentPending && redirectUrl != null && redirectUrl.isNotEmpty) {
            try {
              await launchUrl(
                Uri.parse(redirectUrl),
                mode: LaunchMode.inAppBrowserView,
              );
            } catch (_) {
              // No browser available / malformed URL — fall through to the
              // order screen anyway; the order exists and is visible in
              // Order History showing its real (unpaid) status.
            }
          }

          if (!context.mounted) return;
          context.pushReplacement(
            '${RouteNames.orderSuccess.replaceAll(':orderId', orderId)}'
            '${paymentPending ? '?paymentPending=1' : ''}',
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text('Checkout', style: DesignTokens.sectionInnerTitle),
        centerTitle: false,
      ),
      body: state.when(
        initial: (p) => _loader(placeOrderState: p),
        loadInProgress: (p) => _loader(placeOrderState: p),
        loadSuccess: (summary, placeOrderState) {
          final effectiveAddress = _selectedAddress ?? summary.shippingAddress;
          // Keyed off the id: a location-captured address has no `line1`
          // at all, so the old blank-line1 test hid every new address.
          final hasAddress = !effectiveAddress.isEmpty;
          final isProcessing = placeOrderState.maybeWhen(
            processing: () => true,
            orElse: () => false,
          );
          final selectedPayment = _selectedPayment ?? summary.paymentMethod;
          final deliveryChoice = summary.selectedDeliveryChoice;
          final isPickup =
              deliveryChoice?.kind == DeliveryChoiceKind.pickupFromSeller;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  children: [
                    _DeliveryChoiceCard(
                      choices: summary.deliveryChoices,
                      selected: deliveryChoice,
                      pickupNote: summary.pickupNote,
                      preferences: summary.deliveryPreference,
                      consolidation: summary.deliveryConsolidation,
                      onPreferenceChanged: (preference) => ref
                          .read(checkoutNotifierProvider.notifier)
                          .updateDeliveryPreference(preference),
                      onSelect: (choice) => ref
                          .read(checkoutNotifierProvider.notifier)
                          .selectDeliveryChoice(choice),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    // Only when this seller has registered counters. A seller
                    // with none shows no picker at all and their collection
                    // order is placed without one, exactly as before.
                    if (isPickup && summary.pickupLocations.isNotEmpty) ...[
                      _PickupCounterPicker(
                        locations: summary.pickupLocations,
                        note: summary.pickupLocationsNote,
                        onSelect: (location) => ref
                            .read(checkoutNotifierProvider.notifier)
                            .selectPickupLocation(location),
                      ),
                      const SizedBox(height: DesignTokens.s16),
                    ],
                    if (!isPickup) ...[
                      _ShippingAddressCard(
                        address: effectiveAddress,
                        hasAddress: hasAddress || isPickup,
                        onAddAddress: () => unawaited(_openAddAddress(context)),
                        onChangeAddress: () =>
                            _showPickAddressSheet(context, summary),
                      ),
                      const SizedBox(height: DesignTokens.s16),
                    ],
                    // ── Bill details ticket card ───────────────────────
                    _BillTicketCard(
                      summary: summary,
                      onSubTotalTap: () =>
                          _showCartItemsSheet(context, summary),
                    ),
                    const SizedBox(height: DesignTokens.s24),

                    // ── Payment method list ────────────────────────────
                    Text(
                      'Payment Method',
                      style: DesignTokens.sectionInnerTitle,
                    ),
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
                hasAddress: hasAddress || isPickup,
                isProcessing: isProcessing,
                onAddAddress: () => unawaited(_openAddAddress(context)),
                onPlaceOrder: () {
                  ref
                      .read(checkoutNotifierProvider.notifier)
                      .placeOrder(
                        addressId: isPickup ? null : effectiveAddress.id,
                        paymentMethod: selectedPayment.type,
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
    PaymentMethod? savedCard;
    for (final method in summary.availablePaymentMethods) {
      if (method.type == PaymentMethodType.card) {
        savedCard = method;
        break;
      }
    }
    return checkoutPaymentMethods(savedCard: savedCard);
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
          unawaited(_openAddAddress(context));
        },
      ),
    );
  }

  // ── ADD ADDRESS ───────────────────────────────────────────────────────────
  /// Checkout no longer carries its own typed address form — the customer
  /// captures a location on the shared add-address screen (GPS, Maps link or
  /// pin) and checkout just reloads when they come back.
  Future<void> _openAddAddress(BuildContext context) async {
    final saved = await context.push<bool>(RouteNames.shippingAddEdit);
    if (!mounted) return;
    if (saved == true) {
      await ref.read(checkoutNotifierProvider.notifier).load();
    }
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
              style: DesignTokens.mediumRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
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

    // Render the customer's own directions (or the point) — never a city
    // that may be null.
    final addressLine = StringBuffer()..write(address.summaryLine);

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
              child: const Icon(
                Icons.location_on_outlined,
                color: DesignTokens.primaryGreen,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // A customer-typed label ("Mum's place, Baluwatar") next
                      // to a badge overflows a narrow row at 1.3x unless it
                      // is allowed to wrap.
                      Flexible(
                        child: Text(
                          address.label,
                          style: DesignTokens.oneLinerSemibold.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: DesignTokens.s8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryGreenLight,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.buttonRadius,
                            ),
                          ),
                          child: Text(
                            'Default',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    addressLine.toString(),
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.iconLight,
            ),
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
        vertical: DesignTokens.s12,
        horizontal: DesignTokens.s16,
      ),
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
            child: const Icon(
              Icons.local_shipping_outlined,
              size: 28,
              color: DesignTokens.secondaryYellow,
            ),
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
              child: const Icon(
                Icons.add_rounded,
                size: 20,
                color: DesignTokens.textWhite,
              ),
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
                const Text(
                  'Bill Details',
                  style: DesignTokens.oneLinerSemibold,
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

                // Same shape as the cart's checkout bar, and the same
                // failure: a 20sp amount beside a scaled-up label has no room
                // to give on a narrow screen. Wrapping drops the amount onto
                // its own line instead of overflowing. Baseline alignment is
                // given up for it — a line that fits beats a line that lines
                // up.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s4,
                  children: [
                    const Text(
                      'Grand Total',
                      style: DesignTokens.mediumSemibold,
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
                  child: const Icon(
                    Icons.favorite,
                    size: 22,
                    color: Colors.white,
                  ),
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
              color: DesignTokens.textWhite,
              decoration: labelUnderline
                  ? TextDecoration.underline
                  : TextDecoration.none,
              decorationColor: DesignTokens.textWhite,
            ),
          ),
        ),
        if (valueBadge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: DesignTokens.tagInfoFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              valueBadge!,
              style: DesignTokens.smallRegular.copyWith(
                fontWeight: FontWeight.w600,
                color: DesignTokens.tagInfoText,
              ),
            ),
          )
        else
          Text(
            value ?? '',
            style: DesignTokens.smallRegular.copyWith(
              color: valueColor ?? DesignTokens.textLight,
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
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s12,
                  ),
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
                              style: DesignTokens.oneLinerSemibold.copyWith(
                                color: DesignTokens.textWhite,
                              ),
                            ),
                            Text(
                              _subtitleFor(method),
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                              ),
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

class _DeliveryChoiceCard extends StatelessWidget {
  const _DeliveryChoiceCard({
    required this.choices,
    required this.selected,
    required this.pickupNote,
    required this.preferences,
    required this.consolidation,
    required this.onPreferenceChanged,
    required this.onSelect,
  });
  final List<DeliveryChoice> choices;
  final DeliveryChoice? selected;
  final String? pickupNote;
  final DeliveryPreference preferences;
  final DeliveryConsolidationPlan? consolidation;
  final ValueChanged<DeliveryPreference> onPreferenceChanged;
  final ValueChanged<DeliveryChoice> onSelect;

  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How you’ll get it',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s4),
          const Text(
            'Choose the handoff that fits this basket.',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
          ),
          const SizedBox(height: DesignTokens.s12),
          for (final choice in choices) ...[
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onSelect(choice),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(DesignTokens.s12),
                decoration: BoxDecoration(
                  color: choice.selected
                      ? DesignTokens.primaryGreen.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: choice.selected
                        ? DesignTokens.primaryGreen
                        : DesignTokens.borderDefault,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      choice.kind == DeliveryChoiceKind.pickupFromSeller
                          ? Icons.storefront_rounded
                          : Icons.local_shipping_outlined,
                      color: choice.selected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  choice.title,
                                  style: const TextStyle(
                                    color: DesignTokens.textWhite,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (choice.recommended)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.primaryGreen.withValues(
                                      alpha: 0.16,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Recommended',
                                    style: TextStyle(
                                      color: DesignTokens.primaryGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            choice.detail,
                            style: const TextStyle(
                              color: DesignTokens.textMuted,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      choice.selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: choice.selected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
          if (consolidation != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.textWhite.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: DesignTokens.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${consolidation!.sellerPackages} seller '
                          '${consolidation!.sellerPackages == 1 ? 'package' : 'packages'}',
                          style: const TextStyle(
                            color: DesignTokens.textWhite,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          consolidation!.explanation,
                          style: const TextStyle(
                            color: DesignTokens.textMuted,
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.s4),
          ],
          const Divider(height: 24, color: DesignTokens.borderDefault),
          const Text(
            'Delivery preferences',
            style: TextStyle(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          // Both preference tiles sit inside the card's DecoratedBox, so the
          // nearest Material is below the background and the framework
          // asserts that the tile's ink can never be seen. A transparent
          // Material paints nothing and restores the splash target.
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Prefer fewer deliveries',
                style: TextStyle(color: DesignTokens.textWhite, fontSize: 13),
              ),
              subtitle: const Text(
                'Group items from the same seller when possible',
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
              ),
              value: preferences.preferFewerDeliveries,
              activeTrackColor: DesignTokens.primaryGreen,
              onChanged: (value) => onPreferenceChanged(
                preferences.copyWith(preferFewerDeliveries: value),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text(
                'Prefer pickup',
                style: TextStyle(color: DesignTokens.textWhite, fontSize: 13),
              ),
              subtitle: const Text(
                'Recommend seller pickup when it is available',
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
              ),
              value: preferences.preferPickup,
              activeTrackColor: DesignTokens.primaryGreen,
              onChanged: (value) => onPreferenceChanged(
                preferences.copyWith(preferPickup: value),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          const Text(
            'Extra wait allowed for grouping',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 11),
          ),
          const SizedBox(height: DesignTokens.s8),
          Wrap(
            spacing: DesignTokens.s8,
            children: [0, 2, 5, 7, 14]
                .map(
                  (days) => ChoiceChip(
                    label: Text(days == 0 ? 'None' : '$days days'),
                    selected: preferences.maximumExtraWaitDays == days,
                    onSelected: (_) => onPreferenceChanged(
                      preferences.copyWith(maximumExtraWaitDays: days),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
          const SizedBox(height: DesignTokens.s12),
          if (pickupNote != null && pickupNote!.isNotEmpty)
            Text(
              pickupNote!,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── PICKUP COUNTER PICKER ───────────────────────────────────────────────────
//
// Which counter the shopper will collect from. Until this existed, checkout
// said which seller but never which counter, so every collection order recorded
// no location and the counter name was legitimately absent everywhere.
//
// What this shows is exactly what `codes.vendor_stores` records: a name, an
// address, a city, free-text opening hours and when a human last confirmed the
// record. What it deliberately does not show:
//
//   • Open / closed now. The hours are free text with no timezone, holiday or
//     break model behind them, so they can be repeated but never interpreted.
//   • Stock at a counter. The platform records none; the server reports every
//     counter as "unknown", which is not a quantity and is not zero.
//   • Distance or a map. That would need the shopper's coordinates, which this
//     screen never asks for — no location permission is requested here, because
//     nothing shown depends on where the shopper is.
//
// Nothing here is preselected, including when the seller has exactly one
// counter. See [_PickupCounterPicker.build].
class _PickupCounterPicker extends StatelessWidget {
  const _PickupCounterPicker({
    required this.locations,
    required this.note,
    required this.onSelect,
  });

  final List<PickupLocation> locations;
  final String? note;
  final ValueChanged<PickupLocation> onSelect;

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const SizedBox.shrink();

    // One counter is not preselected. The order records this as the counter the
    // shopper chose, so filling it in for them would write a choice nobody
    // made — and a lone counter is not automatically convenient, confirmed or
    // still open. The tap is one gesture; inventing it is a fabricated fact.
    final chosen = locations.where((l) => l.selected).isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where you’ll collect',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            chosen
                ? 'You’ll collect from the counter below.'
                : 'Pick a counter, or place the order without one.',
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          for (final location in locations) ...[
            _PickupCounterTile(
              location: location,
              onTap: () => onSelect(location),
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s4),
            Text(
              note!,
              style: const TextStyle(
                color: DesignTokens.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickupCounterTile extends StatelessWidget {
  const _PickupCounterTile({required this.location, required this.onTap});

  final PickupLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = location.selected;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: selected
              ? DesignTokens.primaryGreen.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.circle_outlined,
              size: 20,
              color: selected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.textMuted,
            ),
            const SizedBox(width: DesignTokens.s12),
            // Expanded, so a long counter name wraps instead of overflowing at
            // 320dp with text scaled to 1.3.
            Expanded(child: _details()),
          ],
        ),
      ),
    );
  }

  Widget _details() {
    final name = location.name;
    final address = location.addressLine;
    final city = location.city;
    final hours = location.openingHours;
    final confirmationNote = location.confirmationNote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // An unnamed counter is not "Store" and not the seller's name. When the
        // registry holds no name, no name is rendered and the address leads.
        if (name != null)
          Text(
            name,
            style: const TextStyle(
              color: DesignTokens.textWhite,
              fontWeight: FontWeight.w700,
            ),
          ),
        // When the registry holds nothing at all to identify this counter by,
        // say that, rather than render a blank tappable row that looks like a
        // rendering bug.
        if (location.hasNoRecordedDetails)
          const Text(
            'This counter’s details aren’t recorded',
            style: TextStyle(
              color: DesignTokens.textMuted,
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        // A missing address is no line at all — never an empty one.
        if (address != null) ...[
          if (name != null) const SizedBox(height: DesignTokens.s4),
          Text(
            address,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 13,
            ),
          ),
        ],
        if (city != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            city,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 13,
            ),
          ),
        ],
        // Repeated exactly as the seller typed it. "As listed" is doing real
        // work: these hours are not checked against a clock and this line never
        // claims the counter is open now.
        if (hours != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Hours as listed by the seller: $hours',
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 12,
            ),
          ),
        ],
        // The server's own sentence about how fresh this record is, carried
        // through unedited.
        if (confirmationNote != null) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            confirmationNote,
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ],
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
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 1),
        ),
      ),
      child: SafeArea(
        child: hasAddress ? _placeOrderRow() : _addAddressButton(),
      ),
    );
  }

  Widget _addAddressButton() {
    return ConstrainedBox(
      // `height` pinned the bar at 52dp however large the label grew, and the
      // label and its icon were both unflexed inside a centred Row — so
      // "Add Shipping Address" ran off the right at every width, by 36px at
      // 390dp and 195px at 320dp × 1.3. A minimum height keeps the touch
      // target and lets the button grow; the label flexes and wraps.
      constraints: const BoxConstraints(minHeight: DesignTokens.buttonHeight),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primaryGreen,
            foregroundColor: Colors.black,
            elevation: 0,
            minimumSize: const Size(0, DesignTokens.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          onPressed: onAddAddress,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Add Shipping Address',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.add_rounded,
                size: 20,
                color: DesignTokens.buttonPrimaryText,
              ),
            ],
          ),
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
                  fontWeight: FontWeight.w600,
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
      builder: (_, controller) => SafeArea(
        child: Column(
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
                  // Same shape as the address sheet's header: the title has
                  // to yield so the close button keeps its place.
                  Expanded(
                    child: Text(
                      'Your Cart Items(${summary.items.length})',
                      style: DesignTokens.sectionInnerTitle,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      color: DesignTokens.textWhite,
                      size: 22,
                    ),
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
                itemBuilder: (_, i) => _CartItemRow(item: summary.items[i]),
              ),
            ),
          ],
        ),
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
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight,
                  size: 22,
                ),
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
                    color: DesignTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                // "From: @handle (commission%)" — derived from variantName
                // In real app this comes from item.sellerHandle etc.
                Text(
                  'From: ${item.variantName}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s8),

          // Qty badge + price (right column)
          //
          // Flexible, not fixed: a scaled-up "Rs 38,900.00" beside the qty
          // pill measured wider than the space the name column left it, and
          // the row overflowed. Yielding lets the price wrap onto a second
          // line rather than run off the sheet — it still reads in full.
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Qty pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
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
                  textAlign: TextAlign.end,
                  style: DesignTokens.oneLinerSemibold.copyWith(
                    color: DesignTokens.textWhite,
                    fontSize: 13,
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // The title is the long side of this row; unflexed it pushed
                // the close button off a 320dp sheet.
                const Expanded(
                  child: Text(
                    'Choose a Shipping Address',
                    style: DesignTokens.sectionInnerTitle,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: DesignTokens.textWhite,
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // All saved addresses — tapping one selects it and closes the sheet
            ...addresses.map(
              (addr) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _AddressPickerRow(
                  address: addr,
                  isSelected: addr.id == selectedAddress.id,
                  onTap: () => onSelect(addr),
                ),
              ),
            ),

            const SizedBox(height: 8),
            ConstrainedBox(
              // Same shape as the bottom bar's add-address button: a pinned
              // 52dp height around an unflexed label that is longer still.
              constraints: const BoxConstraints(
                minHeight: DesignTokens.buttonHeight,
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    minimumSize: const Size(0, DesignTokens.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: onAddNew,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Add New Shipping Address',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ],
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
    final line = StringBuffer()..write(address.summaryLine);

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
            child: const Icon(
              Icons.location_on_outlined,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // As above: the label yields to the badge rather than
                    // pushing it off the row.
                    Flexible(
                      child: Text(
                        address.label,
                        style: DesignTokens.oneLinerSemibold.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
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
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, radius),
      Paint()..color = topColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, radius, size.width, radius),
      Paint()..color = stubColor,
    );
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
