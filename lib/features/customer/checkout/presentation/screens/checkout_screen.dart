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

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  static const _uuid = Uuid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checkoutNotifierProvider);

    ref.listen<CheckoutState>(checkoutNotifierProvider, (previous, next) {
      next.placeOrderState.maybeWhen(
        success: (orderId) {
          context.pushReplacement(
            RouteNames.orderDetail.replaceAll(':orderId', orderId),
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
        title: const Text('Checkout', style: DesignTokens.titleLarge),
        centerTitle: false,
      ),
      body: state.when(
        initial: (placeOrderState) => _loader(placeOrderState: placeOrderState),
        loadInProgress: (placeOrderState) =>
            _loader(placeOrderState: placeOrderState),
        loadSuccess: (summary, placeOrderState) {
          final isProcessing = placeOrderState.maybeWhen(
            processing: () => true,
            orElse: () => false,
          );
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(DesignTokens.s16),
                  children: [
                    const _SectionHeader(title: 'Shipping Address'),
                    const SizedBox(height: DesignTokens.s8),
                    _AddressCard(address: summary.shippingAddress),
                    const SizedBox(height: DesignTokens.s24),
                    const _SectionHeader(title: 'Payment Method'),
                    const SizedBox(height: DesignTokens.s8),
                    _PaymentCard(
                      method: summary.paymentMethod,
                      onTap: () {
                        context.push('${RouteNames.checkout}/payment-method');
                      },
                    ),
                    const SizedBox(height: DesignTokens.s24),
                    const _SectionHeader(title: 'Order Items'),
                    const SizedBox(height: DesignTokens.s8),
                    ...summary.items
                        .map((item) => _CheckoutItemTile(item: item)),
                    const SizedBox(height: DesignTokens.s24),
                    _PriceSummary(summary: summary),
                    const SizedBox(height: DesignTokens.s32),
                  ],
                ),
              ),
              _PlaceOrderBar(
                total: summary.total,
                isProcessing: isProcessing,
                onPlaceOrder: () {
                  ref.read(checkoutNotifierProvider.notifier).placeOrder(
                        addressId: summary.shippingAddress.id,
                        paymentMethodId: summary.paymentMethod.id,
                        idempotencyKey: _uuid.v4(),
                      );
                },
              ),
            ],
          );
        },
        loadFailure: (failure, _) {
          return SmErrorView(
            message: 'Failed to load checkout details.',
            onRetry: () =>
                ref.read(checkoutNotifierProvider.notifier).load(),
          );
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: DesignTokens.sectionInnerTitle);
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});

  final ShippingAddress address;

  @override
  Widget build(BuildContext context) {
    final addressLine = StringBuffer()
      ..write(address.addressLine1);
    if (address.addressLine2 != null && address.addressLine2!.isNotEmpty) {
      addressLine.write(', ${address.addressLine2}');
    }
    addressLine.write(', ${address.city}, ${address.state} ${address.zipCode}');

    return Container(
      width: double.infinity,
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
                    Text(
                      address.label,
                      style: DesignTokens.oneLinerSemibold.copyWith(
                        color: DesignTokens.textWhite,
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
                          borderRadius:
                              BorderRadius.circular(DesignTokens.buttonRadius),
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
                  '${address.fullName} • ${address.phone}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
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
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.method, required this.onTap});

  final PaymentMethod method;
  final VoidCallback onTap;

  IconData get _icon {
    switch (method.type) {
      case PaymentMethodType.card:
        return Icons.credit_card_rounded;
      case PaymentMethodType.eSewa:
        return Icons.account_balance_wallet_rounded;
      case PaymentMethodType.cod:
        return Icons.money_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: Icon(_icon, color: DesignTokens.primaryGreen),
            ),
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
                  if (method.lastFour != null)
                    Text(
                      '•••• ${method.lastFour}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (method.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryGreenLight,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                child: Text(
                  'Default',
                  style: DesignTokens.tiny.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
            const SizedBox(width: DesignTokens.s4),
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

class _CheckoutItemTile extends StatelessWidget {
  const _CheckoutItemTile({required this.item});

  final CheckoutItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Image.network(
              item.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: DesignTokens.iconLight,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
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
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '${item.variantName} • Qty: ${item.quantity}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(item.unitPrice),
            style: DesignTokens.oneLinerSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  const _PriceSummary({required this.summary});

  final CheckoutSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          _PriceRow(label: 'Sub Total', amount: summary.subtotal),
          const SizedBox(height: DesignTokens.s8),
          _PriceRow(label: 'Shipping', amount: summary.shipping),
          const SizedBox(height: DesignTokens.s8),
          _PriceRow(label: 'Tax (Estimated 13%)', amount: summary.tax),
          if (summary.discount.amount > 0) ...[
            const SizedBox(height: DesignTokens.s8),
            _PriceRow(label: 'Promo Code Discount', amount: summary.discount),
          ],
          const Divider(
            color: DesignTokens.borderDefault,
            height: DesignTokens.s24,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: DesignTokens.h3.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
              Text(
                formatMoney(summary.total),
                style: DesignTokens.h3.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        Text(
          formatMoney(amount),
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textLight,
          ),
        ),
      ],
    );
  }
}

class _PlaceOrderBar extends StatelessWidget {
  const _PlaceOrderBar({
    required this.total,
    required this.isProcessing,
    required this.onPlaceOrder,
  });

  final Money total;
  final bool isProcessing;
  final VoidCallback onPlaceOrder;

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
                  Text(
                    'Grand Total',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  Text(
                    formatMoney(total),
                    style: DesignTokens.oneLinerSemibold.copyWith(
                      color: DesignTokens.textWhite,
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
