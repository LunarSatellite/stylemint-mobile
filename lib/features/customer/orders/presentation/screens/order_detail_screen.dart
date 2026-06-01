import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_badge.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderDetailNotifierProvider);

    ref.listen<OrderDetailState>(orderDetailNotifierProvider, (previous, next) {
      next.maybeWhen(
        actionFailure: (failure) => SmSnackbar.error(
          context,
          'Action failed. Please try again.',
        ),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Order Details',
          style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.textWhite),
        ),
        centerTitle: true,
      ),
      body: state.when(
        initial: () => _loader(),
        loadInProgress: () => _loader(),
        loadSuccess: (order) => _OrderDetailBody(
          order: order,
          notifier: ref.read(orderDetailNotifierProvider.notifier),
        ),
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load order details.',
          onRetry: () => ref.read(orderDetailNotifierProvider.notifier).loadOrder(orderId),
        ),
        actionInProgress: (order) => _OrderDetailBody(
          order: order,
          actionPending: true,
          notifier: ref.read(orderDetailNotifierProvider.notifier),
        ),
        actionFailure: (failure) => _loader(),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({
    required this.order,
    required this.notifier,
    this.actionPending = false,
  });

  final OrderDetail order;
  final OrderDetailNotifier notifier;
  final bool actionPending;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    final dateTimeFmt = DateFormat('MMM d, yyyy - HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: DesignTokens.titleMedium,
              ),
              OrderStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),

          // Order dates
          _DetailCard(
            children: [
              _DetailRow(
                label: 'Placed On',
                value: dateTimeFmt.format(order.placedAt),
              ),
              const SizedBox(height: DesignTokens.s8),
              _DetailRow(
                label: 'Estimated Delivery',
                value: dateFmt.format(order.estimatedDelivery),
              ),
              if (order.trackingNumber != null) ...[
                const SizedBox(height: DesignTokens.s8),
                _DetailRow(
                  label: 'Tracking Number',
                  value: order.trackingNumber!,
                  valueColor: DesignTokens.primaryGreen,
                ),
              ],
            ],
          ),
          const SizedBox(height: DesignTokens.s16),

          // Items
          Text(
            'Items (${order.items.length})',
            style: DesignTokens.sectionInnerTitle,
          ),
          const SizedBox(height: DesignTokens.s12),
          ...order.items.map((item) => _OrderItemTile(item: item)),

          const SizedBox(height: DesignTokens.s16),

          // Price breakdown
          _DetailCard(
            children: [
              _DetailRow(label: 'Subtotal', value: formatMoney(order.subtotal)),
              const SizedBox(height: DesignTokens.s8),
              _DetailRow(label: 'Shipping', value: formatMoney(order.shipping)),
              const SizedBox(height: DesignTokens.s8),
              _DetailRow(label: 'Tax', value: formatMoney(order.tax)),
              const Divider(color: DesignTokens.borderDefault, height: DesignTokens.s24),
              _DetailRow(
                label: 'Total',
                value: formatMoney(order.total),
                valueStyle: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),

          // Shipping & Payment
          _DetailCard(
            children: [
              _DetailRow(label: 'Shipping Address', value: order.shippingAddress),
              const Divider(color: DesignTokens.borderDefault, height: DesignTokens.s24),
              _DetailRow(label: 'Payment Method', value: order.paymentMethod),
            ],
          ),
          const SizedBox(height: DesignTokens.s24),

          // Action buttons
          if (order.canCancel)
            _ActionButton(
              label: 'Cancel Order',
              icon: Icons.cancel_outlined,
              color: DesignTokens.colorError,
              loading: actionPending,
              onPressed: () =>
                  context.push('/orders/${order.id}/cancel', extra: order),
            ),
          if (order.canCancel && order.canReturn)
            const SizedBox(height: DesignTokens.s12),
          if (order.canReturn)
            _ActionButton(
              label: 'Request Return',
              icon: Icons.keyboard_return_outlined,
              color: DesignTokens.colorWarning,
              loading: actionPending,
              onPressed: () => _handleRequestReturn(context),
            ),
          const SizedBox(height: DesignTokens.s32),
        ],
      ),
    );
  }

  void _handleRequestReturn(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (ctx) => _ReturnReasonDialog(),
    ).then((reason) {
      if (reason != null && reason.isNotEmpty) {
        notifier.requestReturn(reason);
      }
    });
  }
}

class _ReturnReasonDialog extends StatefulWidget {
  @override
  State<_ReturnReasonDialog> createState() => _ReturnReasonDialogState();
}

class _ReturnReasonDialogState extends State<_ReturnReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DesignTokens.bgAppBody,
      title: Text(
        'Request Return',
        style: DesignTokens.sectionInnerTitle,
      ),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        style: DesignTokens.bodyText,
        decoration: DesignTokens.inputDecoration(
          hintText: 'Reason for return',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textMuted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(
            'Submit',
            style: DesignTokens.mediumSemibold.copyWith(color: DesignTokens.primaryGreen),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: DesignTokens.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: DesignTokens.textWhite),
              )
            : Icon(icon, color: color),
        label: Text(label, style: DesignTokens.mediumSemibold.copyWith(color: color)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueStyle,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textMuted),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: (valueStyle ?? DesignTokens.mediumSemibold).copyWith(
              color: valueColor ?? DesignTokens.textWhite,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderDetailItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
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
                child: const Icon(Icons.image, color: DesignTokens.textMuted),
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
                  style: DesignTokens.mediumSemibold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  item.variantName,
                  style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                ),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Qty: ${item.qty}',
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                    ),
                    Text(
                      formatMoney(item.unitPrice),
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
