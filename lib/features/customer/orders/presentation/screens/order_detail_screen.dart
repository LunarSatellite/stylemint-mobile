import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
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
        actionFailure: (failure) =>
            SmSnackbar.error(context, 'Action failed. Please try again.'),
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
        title: const Text('Track Order', style: DesignTokens.sectionInnerTitle),
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
          onRetry: () =>
              ref.read(orderDetailNotifierProvider.notifier).loadOrder(orderId),
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

class _OrderDetailBody extends StatefulWidget {
  const _OrderDetailBody({
    required this.order,
    required this.notifier,
    this.actionPending = false,
  });

  final OrderDetail order;
  final OrderDetailNotifier notifier;
  final bool actionPending;

  @override
  State<_OrderDetailBody> createState() => _OrderDetailBodyState();
}

class _OrderDetailBodyState extends State<_OrderDetailBody> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrackSummaryCard(
            order: order,
            expanded: _expanded,
            onToggle: () => setState(() => _expanded = !_expanded),
          ),
          const SizedBox(height: DesignTokens.s24),

          if (order.status == OrderTrackStatus.cancelled)
            _CancelledNote()
          else
            _TrackingTimeline(status: order.status),

          // "View Other Details" reveals the full order breakdown + actions.
          _ViewOtherDetails(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),

          if (_expanded)
            _OtherDetails(
              order: order,
              actionPending: widget.actionPending,
              notifier: widget.notifier,
            ),

          const SizedBox(height: DesignTokens.s32),
        ],
      ),
    );
  }
}

// ── Track Order summary card ──────────────────────────────────────────────────
class _TrackSummaryCard extends StatelessWidget {
  const _TrackSummaryCard({
    required this.order,
    required this.expanded,
    required this.onToggle,
  });

  final OrderDetail order;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final placed = DateFormat('HH:mm MMM d, yyyy').format(order.placedAt);
    // MOCK — spec shows a delivery RANGE; the payload has a single date, so
    // render a +2-day window from it.
    final start = order.estimatedDelivery;
    final end = start.add(const Duration(days: 2));
    final expected =
        '${DateFormat('MMM dd').format(start)}-${DateFormat('dd').format(end)} ${start.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: DesignTokens.s16, horizontal: DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 48x48 order-box illustration.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(DesignTokens.s12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.inventory_2_rounded,
                    color: DesignTokens.secondaryYellow, size: 26),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${order.orderNumber}',
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.textWhite)),
                    const SizedBox(height: DesignTokens.s4),
                    Row(
                      children: [
                        Flexible(
                          child: Text('Placed on $placed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DesignTokens.smallRegular
                                  .copyWith(color: DesignTokens.textLight)),
                        ),
                        const _Dot(),
                        Text(formatMoney(order.total),
                            style: DesignTokens.smallRegular
                                .copyWith(color: DesignTokens.textLight)),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.chevron_right_rounded,
                  size: 16,
                  color: DesignTokens.iconLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          // Expected Delivery info-tag pill.
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
            decoration: BoxDecoration(
              color: DesignTokens.tagInfoFill,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 12, color: DesignTokens.tagInfoText),
                const SizedBox(width: DesignTokens.s4),
                Text('Expected Delivery: $expected',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.tagInfoText,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    )),
              ],
            ),
          ),
          if (order.trackingNumber != null) ...[
            const SizedBox(height: DesignTokens.s8),
            Text('Tracking ID: ${order.trackingNumber}',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: Color(0xFF00BCFF),
                )),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
        width: 3,
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.s8),
        decoration: const BoxDecoration(
          color: Color(0xFF71717B),
          shape: BoxShape.circle,
        ),
      );
}

// ── Tracking timeline ─────────────────────────────────────────────────────────
enum _StageState { completed, ongoing, remaining }

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({required this.status});

  final OrderTrackStatus status;

  static const _stages = [
    'Shipped',
    'In Transit',
    'Out for Delivery',
    'Delivered'
  ];
  static const _icons = [
    Icons.inventory_2_outlined,
    Icons.local_shipping_outlined,
    Icons.moped_outlined,
    Icons.check_rounded,
  ];

  // Index of the in-progress stage; lower stages are completed, higher remain.
  int get _current => switch (status) {
        OrderTrackStatus.preparingForShipping => 0,
        OrderTrackStatus.inTransit => 1,
        OrderTrackStatus.outForDelivery => 2,
        OrderTrackStatus.delivered => 4, // all complete
        OrderTrackStatus.cancelled => -1,
      };

  _StageState _stateFor(int i) {
    if (i < _current) return _StageState.completed;
    if (i == _current) return _StageState.ongoing;
    return _StageState.remaining;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tracking Timeline', style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s16),
        Row(
          children: [
            for (var i = 0; i < _stages.length; i++) ...[
              _StageIndicator(
                state: _stateFor(i),
                icon: _icons[i],
                label: _stages[i],
              ),
              if (i < _stages.length - 1)
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Divider(
                        color: DesignTokens.borderDefault,
                        height: 1,
                        thickness: 1),
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
      ],
    );
  }
}

class _StageIndicator extends StatelessWidget {
  const _StageIndicator(
      {required this.state, required this.icon, required this.label});

  final _StageState state;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (state) {
      _StageState.completed => (
          DesignTokens.primaryGreenDark,
          DesignTokens.primaryGreen
        ),
      _StageState.ongoing => (DesignTokens.infoFillDark, const Color(0xFF00A6F4)),
      _StageState.remaining => (
          DesignTokens.inputFieldFill,
          DesignTokens.iconLight
        ),
    };
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: fg),
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                height: 1.2,
                color: DesignTokens.textWhite,
              )),
        ],
      ),
    );
  }
}

class _CancelledNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined,
              color: DesignTokens.colorError, size: 20),
          const SizedBox(width: DesignTokens.s8),
          Text('This order was cancelled.',
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textLight)),
        ],
      ),
    );
  }
}

class _ViewOtherDetails extends StatelessWidget {
  const _ViewOtherDetails({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(0, DesignTokens.s16, 0, DesignTokens.s12),
        child: Row(
          children: [
            Text(expanded ? 'Hide Other Details' : 'View Other Details',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(width: DesignTokens.s4),
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
              size: 12,
              color: DesignTokens.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expanded "other details" (price, shipping, items, actions) ────────────────
class _OtherDetails extends StatelessWidget {
  const _OtherDetails({
    required this.order,
    required this.actionPending,
    required this.notifier,
  });

  final OrderDetail order;
  final bool actionPending;
  final OrderDetailNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items (${order.items.length})',
            style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s12),
        ...order.items.map((item) => _OrderItemTile(item: item)),
        const SizedBox(height: DesignTokens.s16),
        _DetailCard(
          children: [
            _DetailRow(label: 'Subtotal', value: formatMoney(order.subtotal)),
            const SizedBox(height: DesignTokens.s8),
            _DetailRow(label: 'Shipping', value: formatMoney(order.shipping)),
            const SizedBox(height: DesignTokens.s8),
            _DetailRow(label: 'Tax', value: formatMoney(order.tax)),
            const Divider(
                color: DesignTokens.borderDefault, height: DesignTokens.s24),
            _DetailRow(
              label: 'Total',
              value: formatMoney(order.total),
              valueStyle: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),
        _DetailCard(
          children: [
            _DetailRow(label: 'Shipping Address', value: order.shippingAddress),
            const Divider(
                color: DesignTokens.borderDefault, height: DesignTokens.s24),
            _DetailRow(label: 'Payment Method', value: order.paymentMethod),
          ],
        ),
        const SizedBox(height: DesignTokens.s24),
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
      ],
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
      title: Text('Request Return', style: DesignTokens.sectionInnerTitle),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        style: DesignTokens.bodyText,
        decoration: DesignTokens.inputDecoration(hintText: 'Reason for return'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel',
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textMuted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text('Submit',
              style: DesignTokens.mediumSemibold
                  .copyWith(color: DesignTokens.primaryGreen)),
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
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: DesignTokens.textWhite),
              )
            : Icon(icon, color: color),
        label: Text(label,
            style: DesignTokens.mediumSemibold.copyWith(color: color)),
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
          child: Text(label,
              style: DesignTokens.mediumRegular
                  .copyWith(color: DesignTokens.textMuted)),
        ),
        Expanded(
          flex: 3,
          child: Text(value,
              textAlign: TextAlign.end,
              style: (valueStyle ?? DesignTokens.mediumSemibold).copyWith(
                color: valueColor ?? DesignTokens.textWhite,
              )),
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
                Text(item.productName,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: DesignTokens.s4),
                Text(item.variantName,
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.textMuted)),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Qty: ${item.qty}',
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.textMuted)),
                    Text(formatMoney(item.unitPrice),
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.primaryGreen)),
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
