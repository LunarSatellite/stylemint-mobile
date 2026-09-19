import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/packing_slip.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_order_action_bar.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_order_status_badge.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_step_sheets.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';

class VendorOrderDetailScreen extends ConsumerStatefulWidget {
  const VendorOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<VendorOrderDetailScreen> createState() =>
      _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState
    extends ConsumerState<VendorOrderDetailScreen> {
  bool _itemsExpanded = true;
  bool _revenueExpanded = true;
  bool _requested = false;

  /// The step whose request is in flight, so only its button spins.
  VendorOrderAction? _pendingAction;

  /// Runs a seller step. Reject and Hand over collect their input in a sheet
  /// first; closing the sheet cancels. Outcomes (snackbar, list refresh) are
  /// handled by the state listener in [build].
  Future<void> _onAction(VendorOrderAction action) async {
    final notifier = ref.read(vendorOrderDetailNotifierProvider.notifier);
    Future<void> Function()? run;
    switch (action) {
      case VendorOrderAction.accept:
        run = notifier.accept;
      case VendorOrderAction.reject:
        final input = await showVendorRejectSheet(context);
        if (input == null) return;
        run = () => notifier.reject(reason: input.reason, note: input.note);
      case VendorOrderAction.markPacked:
        run = notifier.markPacked;
      case VendorOrderAction.handOver:
        final input = await showVendorHandoverSheet(context);
        if (input == null) return;
        run = () => notifier.handOver(
          carrier: input.carrier,
          trackingNumber: input.trackingNumber,
          note: input.note,
        );
      case VendorOrderAction.readyToShip:
        run = notifier.markReadyToShip;
      case VendorOrderAction.markDelivered:
        run = notifier.markDelivered;
      case VendorOrderAction.markCollected:
        // A state change the buyer relies on: it ends the order, starts the
        // return window and releases the seller's earnings. It is asked
        // before it is done, and named for what it actually is.
        final confirmed = await _confirmCounterHandover();
        if (confirmed != true) return;
        run = notifier.markCollected;
    }
    if (!mounted) return;
    setState(() => _pendingAction = action);
    await run();
    if (mounted) setState(() => _pendingAction = null);
  }

  /// Whether the counter handover's refusal is worth putting on screen.
  ///
  /// It is, on a delivery sub-order that is still in a pre-shipment state —
  /// that is where a seller might reasonably reach for it and needs to be
  /// told why it is not theirs to take. Once a parcel is with a courier the
  /// question no longer arises, and a disabled button would be noise.
  static bool _handoverRefusalIsWorthSaying(VendorOrder order) =>
      !order.isCollection &&
      const {
        SubOrderStateCode.paid,
        SubOrderStateCode.awaitingFulfillment,
        SubOrderStateCode.accepted,
        SubOrderStateCode.packed,
        SubOrderStateCode.readyToShip,
        SubOrderStateCode.awaitingTracking,
      }.contains(order.stateCode);

  /// Asks before recording the handover. Not a formality: once recorded the
  /// order is Delivered, the buyer's return window opens and settlement
  /// runs, and there is no seller-side undo. The question names the
  /// irreversible part rather than asking "are you sure?".
  Future<bool?> _confirmCounterHandover() => showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('vendor-collected-confirm'),
      backgroundColor: DesignTokens.surfaceRaised,
      icon: const Icon(
        Icons.storefront_outlined,
        color: DesignTokens.primaryGreen,
      ),
      title: const Text('Has the buyer taken this order?'),
      content: const Text(
        'Record it only once the goods are across the counter. This '
        'completes the order, starts the buyer’s return window and '
        'releases your earnings — it cannot be undone from here.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Not yet'),
        ),
        FilledButton(
          key: const ValueKey('vendor-collected-confirm-yes'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Yes, handed over'),
        ),
      ],
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    if (_requested) return;
    _requested = true;
    ref
        .read(vendorOrderDetailNotifierProvider.notifier)
        .loadOrder(widget.orderId);
  }

  Future<void> _showPackingSlip() async {
    final notifier = ref.read(vendorOrderDetailNotifierProvider.notifier);
    final slip = await notifier.getPackingSlip();
    if (!mounted) return;
    if (slip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load packing slip.')),
      );
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PackingSlipSheet(slip: slip),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorOrderDetailNotifierProvider);
    ref.listen(vendorOrderDetailNotifierProvider, (previous, next) {
      next.maybeWhen(
        actionFailure: (_, failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(NetworkExceptions.getMessage(failure))),
          );
        },
        loadSuccess: (_) {
          final wasInProgress = previous?.maybeWhen(
            actionInProgress: (_) => true,
            orElse: () => false,
          );
          if (wasInProgress == true) {
            // The outcome has to be visible, and "Order updated" is not an
            // outcome — it is a shrug. A handover says what now holds.
            final collected = _pendingAction == VendorOrderAction.markCollected;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  collected
                      ? 'Handed over. This order is complete.'
                      : 'Order updated.',
                ),
              ),
            );
            // The list screens bucket by status; refetch so the row moves.
            ref.invalidate(vendorOrdersNotifierProvider);
          }
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            size: 18,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        centerTitle: true,
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (_) => _ErrorBody(
          onRetry: () {
            _requested = false;
            _load();
          },
        ),
        loadSuccess: (order) => _buildBody(order, actionInProgress: false),
        actionInProgress: (order) => _buildBody(order, actionInProgress: true),
        actionFailure: (order, _) => _buildBody(order, actionInProgress: false),
      ),
    );
  }

  Widget _loader() => const SmPageLoader();

  Widget _buildBody(VendorOrder order, {required bool actionInProgress}) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OrderSummaryCard(order: order),
                const SizedBox(height: 12),
                _CustomerCard(order: order),
                const SizedBox(height: 12),
                // A collection order has no shipping address — checkout
                // recorded an empty one because there is none — so the
                // shipping card is replaced rather than filled with a
                // stand-in. Grouped here as one swap.
                if (order.isCollection)
                  _CollectionCard(order: order)
                else
                  _ShippingCard(order: order),
                const SizedBox(height: 12),
                _OrderItemsCard(
                  order: order,
                  expanded: _itemsExpanded,
                  onToggle: () =>
                      setState(() => _itemsExpanded = !_itemsExpanded),
                ),
                const SizedBox(height: 12),
                _RevenueSummaryCard(
                  order: order,
                  expanded: _revenueExpanded,
                  onToggle: () =>
                      setState(() => _revenueExpanded = !_revenueExpanded),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),

        // Fixed bottom buttons
        Container(
          color: DesignTokens.bgAppFoundation,
          // Hardcoded 28 bottom padding sat under the Android 3-button nav
          // bar instead of clearing it — confirmed live: "Print Packing
          // Slip" was partially hidden behind the system nav bar. Add the
          // real inset on top of the design padding instead of guessing a
          // fixed value.
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            28 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Next step for the current backend state (Orders contract §1):
              // Accept/Reject, Mark packed, Hand over or Mark as Shipped, and
              // Mark as Delivered — the only route to Delivered and, from
              // there, the vendor's earnings ledger.
              VendorOrderActionBar(
                stateCode: order.stateCode,
                fulfillmentChannel: order.fulfillmentChannel,
                // On a delivery sub-order the counter handover is refused,
                // and the refusal is shown rather than the control being
                // quietly absent — but only where a seller could plausibly
                // be standing at a counter waiting to use it.
                showCollectionRefusal: _handoverRefusalIsWorthSaying(order),
                busy: actionInProgress,
                pendingAction: actionInProgress ? _pendingAction : null,
                onAction: _onAction,
              ),
              if (vendorActionsForState(
                order.stateCode,
                channel: order.fulfillmentChannel,
              ).isNotEmpty)
                const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _showPackingSlip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C2C2E),
                    foregroundColor: DesignTokens.textWhite,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Print Packing Slip',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Could not load this order.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Packing slip preview sheet
// ---------------------------------------------------------------------------

class _PackingSlipSheet extends StatelessWidget {
  const _PackingSlipSheet({required this.slip});

  final PackingSlip slip;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Packing Slip', style: DesignTokens.mediumSemibold),
                IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: DesignTokens.textWhite,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              'Order #${slip.orderNumber}',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (slip.receiverName != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                slip.receiverName!,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
            if (slip.shippingAddress != null)
              Text(
                slip.shippingAddress!,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            if (slip.carrier != null) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Carrier: ${slip.carrier}',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
            if (slip.trackingNumber != null)
              Text(
                'Tracking: ${slip.trackingNumber}',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'Items',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            if (slip.items.isEmpty)
              Text(
                'No item detail available.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              )
            else
              ...slip.items.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          i.productName,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                        ),
                      ),
                      Text(
                        'x${i.quantity}',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: DesignTokens.s16),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order Summary card
// ---------------------------------------------------------------------------

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/vendordashboard/Order.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (order.placedAt != null)
                      _formatDateTime(order.placedAt!),
                    formatMoney(order.total),
                  ].join('  •  '),
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: Color(0xFF9F9FA9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                VendorOrderStatusBadge(status: order.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime utc) {
    final local = utc.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return 'Placed on $hh:$mm ${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}

// ---------------------------------------------------------------------------
// Customer card
// ---------------------------------------------------------------------------

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.order});

  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/vendordashboard/Customer.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Customer: ${order.customerName ?? 'Not available'}',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: DesignTokens.textWhite,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shipping Address card
// ---------------------------------------------------------------------------

/// What a collection order has instead of a shipping address: how it
/// reaches the buyer, and when it did.
///
/// Every line here is either recorded or omitted. There is no "Address not
/// available" placeholder, because there is no address to be unavailable —
/// the buyer is coming to the counter.
class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.order});

  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    final collectedAt = order.collectedAt;
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.storefront_outlined,
            size: 28,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection at your counter',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  collectedAt == null
                      ? 'The buyer is collecting this order in person. '
                            'No courier is involved.'
                      : 'Handed over ${_formatCollectedAt(collectedAt)}.',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: Color(0xFF9F9FA9),
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

  static String _formatCollectedAt(DateTime utc) {
    final local = utc.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$d/$m/${local.year} at $h:$min';
  }
}

class _ShippingCard extends StatelessWidget {
  const _ShippingCard({required this.order});

  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/vendordashboard/Shipping Address.png',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Shipping Address',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                if (order.shippingMethod != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8E6FE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 12,
                          color: Color(0xFF024A70),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Shipping Method: ${order.shippingMethod}',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF024A70),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  order.shippingAddress ?? 'Address not available',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: Color(0xFF9F9FA9),
                    height: 1.3,
                  ),
                ),
                if (order.trackingNumber != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Tracking ID: ${order.trackingNumber}',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primaryGreen,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order Items card (expandable)
// ---------------------------------------------------------------------------

class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({
    required this.order,
    required this.expanded,
    required this.onToggle,
  });

  final VendorOrder order;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
          Text(
            'No. of items: ${order.itemCount}',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: Color(0xFF9F9FA9),
              height: 1.3,
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            if (order.items.isEmpty)
              Text(
                'Item detail not available for this order.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              )
            else ...[
              for (int i = 0; i < order.items.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: 14),
                  const _DashedDivider(),
                  const SizedBox(height: 14),
                ],
                _ItemRow(item: order.items[i]),
                // Per-unit tagging, offered only when this build knows the
                // line's id. An empty id means the payload did not carry one,
                // and no id is never guessed at.
                if (order.items[i].subOrderLineId.isNotEmpty)
                  _TagUnitAction(order: order, item: order.items[i]),
              ],
              const SizedBox(height: 14),
              const _DashedDivider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  Text(
                    formatMoney(order.total),
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final VendorOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 56,
            height: 64,
            color: const Color(0xFF2C2C2E),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF9F9FA9),
                      size: 28,
                    ),
                  )
                : const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF9F9FA9),
                    size: 28,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.productName,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.textWhite,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: DesignTokens.primaryGreen,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      'Qty: ${item.quantity}',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formatMoney(item.unitPrice),
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Revenue summary card (expandable) — simplified: the vendor sub-order
// endpoints don't expose a platform-fee/commission breakdown, so this only
// shows the order total rather than fabricating numbers.
// ---------------------------------------------------------------------------

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({
    required this.order,
    required this.expanded,
    required this.onToggle,
  });

  final VendorOrder order;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Revenue',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
              ],
            ),
          ),
          Text(
            'Order Total: ${formatMoney(order.total)}',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: Color(0xFF9F9FA9),
              height: 1.3,
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            Text(
              'Detailed platform-fee / commission breakdown isn\'t available from this endpoint yet.',
              style: DesignTokens.smallRegular.copyWith(
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

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: child,
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const dashW = 6.0;
        const gap = 4.0;
        final count = (constraints.maxWidth / (dashW + gap)).floor();
        return Row(
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 1,
              margin: const EdgeInsets.only(right: gap),
              color: const Color(0xFF3A3A3C),
            ),
          ),
        );
      },
    );
  }
}

/// "Tag this unit" for one order line.
///
/// Always shown, at every stage. What changes is the wording underneath: at
/// Packed or Handed over it opens the bind screen, and at every other stage
/// it opens the same screen with its controls closed and the reason on
/// display. A control that disappears at Delivered would leave a packer
/// looking for something that is no longer there and never told why.
class _TagUnitAction extends StatelessWidget {
  const _TagUnitAction({required this.order, required this.item});

  final VendorOrder order;
  final VendorOrderItem item;

  @override
  Widget build(BuildContext context) {
    final stage = orderLineStageFromSubOrderState(order.stateCode);
    final closed = stage.bindingClosedReason;
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.push(
              RouteNames.vendorUnitMarkerBind.replaceFirst(
                ':lineId',
                item.subOrderLineId,
              ),
              extra: (
                subOrderLineId: item.subOrderLineId,
                stage: stage,
                lineLabel: item.productName,
              ),
            ),
            icon: const Icon(
              Icons.local_offer_outlined,
              size: DesignTokens.s20,
              color: DesignTokens.textLight,
            ),
            label: Text(
              'Tag this unit',
              style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textLight,
              ),
            ),
          ),
          if (closed != null)
            Padding(
              padding: const EdgeInsets.only(left: DesignTokens.s12),
              child: Text(
                closed,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
