import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorOrderDetailScreen extends ConsumerWidget {
  const VendorOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorOrderDetailNotifierProvider);

    ref.listen<OrderDetailState>(vendorOrderDetailNotifierProvider, (prev, next) {
      next.maybeWhen(
        actionFailure: (_, __) {
          SmSnackbar.error(context, 'Action failed. Please try again.');
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text('Order Details',
            style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite)),
        centerTitle: true,
      ),
      body: state.when(
        initial: () => _loader(),
        loadInProgress: () => _loader(),
        loadSuccess: (order) => _OrderDetailBody(
          order: order,
          notifier: ref.read(vendorOrderDetailNotifierProvider.notifier),
        ),
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load order details.',
          onRetry: () => ref
              .read(vendorOrderDetailNotifierProvider.notifier)
              .loadOrder(orderId),
        ),
        actionInProgress: (order) => _OrderDetailBody(
          order: order,
          notifier: ref.read(vendorOrderDetailNotifierProvider.notifier),
          actionPending: true,
        ),
        actionFailure: (order, _) => _OrderDetailBody(
          order: order,
          notifier: ref.read(vendorOrderDetailNotifierProvider.notifier),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
        child:
            CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({
    required this.order,
    required this.notifier,
    this.actionPending = false,
  });

  final VendorOrder order;
  final VendorOrderDetailNotifier notifier;
  final bool actionPending;

  Color _statusColor(VendorOrderStatus s) {
    return switch (s) {
      VendorOrderStatus.pending => DesignTokens.colorWarning,
      VendorOrderStatus.confirmed => DesignTokens.colorInfo,
      VendorOrderStatus.processing => const Color(0xFFFF9800),
      VendorOrderStatus.shipped => const Color(0xFF9C27B0),
      VendorOrderStatus.delivered => DesignTokens.primaryGreen,
      VendorOrderStatus.cancelled => DesignTokens.colorError,
      VendorOrderStatus.returned => DesignTokens.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy - HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderNumber}',
                  style: DesignTokens.titleMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                  vertical: DesignTokens.s6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.15),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.buttonRadius),
                ),
                child: Text(
                  order.status.label,
                  style: DesignTokens.smallRegular.copyWith(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          _SectionCard(children: [
            if (order.customerName != null) ...[
              _DetailRow(label: 'Customer', value: order.customerName!),
              const SizedBox(height: DesignTokens.s8),
            ],
            _DetailRow(
                label: 'Placed On',
                value: order.placedAt != null
                    ? dateFmt.format(order.placedAt!)
                    : '—'),
            if (order.trackingNumber != null) ...[
              const SizedBox(height: DesignTokens.s8),
              _DetailRow(label: 'Tracking', value: order.trackingNumber!),
            ],
          ]),
          const SizedBox(height: DesignTokens.s16),
          Text('Items (${order.itemCount})',
              style: DesignTokens.sectionInnerTitle),
          const SizedBox(height: DesignTokens.s12),
          ...order.items.map((item) => _OrderItemTile(item: item)),
          const SizedBox(height: DesignTokens.s16),
          _SectionCard(children: [
            _DetailRow(label: 'Total', value: formatMoney(order.total)),
          ]),
          if (order.shippingAddress != null) ...[
            const SizedBox(height: DesignTokens.s16),
            _SectionCard(children: [
              _DetailRow(
                  label: 'Shipping Address', value: order.shippingAddress!),
            ]),
          ],
          const SizedBox(height: DesignTokens.s24),
          ..._buildActions(context),
          const SizedBox(height: DesignTokens.s32),
        ],
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final actions = <Widget>[];

    void addButton(String label, IconData icon, Color color, VoidCallback fn) {
      actions.add(
        SizedBox(
          width: double.infinity,
          height: DesignTokens.buttonHeight,
          child: OutlinedButton.icon(
            onPressed: actionPending ? null : fn,
            icon: actionPending
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DesignTokens.textWhite))
                : Icon(icon, color: color),
            label: Text(label,
                style: DesignTokens.mediumSemibold.copyWith(color: color)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.buttonRadius)),
            ),
          ),
        ),
      );
      actions.add(const SizedBox(height: DesignTokens.s12));
    }

    switch (order.status) {
      case VendorOrderStatus.pending:
        addButton('Confirm Order', Icons.check_circle_outline,
            DesignTokens.colorInfo,
            () => notifier.updateStatus(VendorOrderStatus.confirmed));
        addButton('Cancel Order', Icons.cancel_outlined,
            DesignTokens.colorError,
            () => notifier.updateStatus(VendorOrderStatus.cancelled));
      case VendorOrderStatus.confirmed:
        addButton('Process Order', Icons.engineering_outlined,
            const Color(0xFFFF9800),
            () => notifier.updateStatus(VendorOrderStatus.processing));
      case VendorOrderStatus.processing:
        addButton('Mark as Shipped', Icons.local_shipping_outlined,
            const Color(0xFF9C27B0),
            () => notifier.updateStatus(VendorOrderStatus.shipped));
      case VendorOrderStatus.shipped:
        addButton('Mark as Delivered', Icons.check_circle,
            DesignTokens.primaryGreen,
            () => notifier.updateStatus(VendorOrderStatus.delivered));
      case VendorOrderStatus.delivered:
        addButton('Accept Return', Icons.keyboard_return_outlined,
            DesignTokens.colorInfo, () => notifier.handleReturn('accept'));
        addButton('Decline Return', Icons.cancel_outlined,
            DesignTokens.colorError, () => notifier.handleReturn('decline'));
      default:
        break;
    }
    return actions;
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

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
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(label,
              style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textMuted)),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: DesignTokens.mediumSemibold,
          ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final VendorOrderItem item;

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
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(Icons.image,
                    color: DesignTokens.textMuted),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: DesignTokens.mediumSemibold, maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Qty: ${item.quantity}',
                        style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted)),
                    Text(formatMoney(item.unitPrice),
                        style: DesignTokens.mediumSemibold.copyWith(
                            color: DesignTokens.primaryGreen)),
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
