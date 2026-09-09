import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrderWaitingTrackingScreen extends ConsumerStatefulWidget {
  const OrderWaitingTrackingScreen({super.key});

  @override
  ConsumerState<OrderWaitingTrackingScreen> createState() =>
      _OrderWaitingTrackingScreenState();
}

class _OrderWaitingTrackingScreenState
    extends ConsumerState<OrderWaitingTrackingScreen> {
  // Fallback shown while there are genuinely no real orders awaiting
  // tracking yet — same pattern used on Ready to Ship / Recent Activity.
  // Disappears automatically once real orders exist. Actions are disabled
  // on these rows since the ids aren't real sub-orders.
  static final _sampleOrders = [
    VendorOrder(
      id: '_sample-1',
      orderNumber: 'RC20230126',
      itemCount: 3,
      total: const Money(amount: 10000, currency: 'NPR'),
      status: VendorOrderStatus.processing,
      placedAt: DateTime.utc(2024, 12, 15),
      customerName: 'Balendra Shah',
    ),
    VendorOrder(
      id: '_sample-2',
      orderNumber: 'RC20230125',
      itemCount: 2,
      total: const Money(amount: 41000, currency: 'NPR'),
      status: VendorOrderStatus.processing,
      placedAt: DateTime.utc(2024, 12, 15),
      customerName: 'Summendra Pandey',
    ),
  ];

  bool _busy = false;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _assignTracking(
    String orderId,
    String carrier,
    String trackingNumber,
  ) async {
    setState(() => _busy = true);
    final ok = await ref
        .read(vendorOrdersNotifierProvider.notifier)
        .addTracking(orderId, carrier: carrier, trackingNumber: trackingNumber);
    if (!mounted) return;
    setState(() => _busy = false);
    _showSnack(
      ok
          ? 'Tracking number assigned and customer notified.'
          : 'Failed to assign tracking number.',
    );
  }

  void _showAssignSheet(VendorOrder order) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AssignTrackingSheet(
        order: order,
        onAssign: (carrier, trackingNumber) =>
            _assignTracking(order.id, carrier, trackingNumber),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorOrdersNotifierProvider);
    final orders = state.maybeWhen(
      loadSuccess: (orders, nextCursor, hasMore, activeFilter) => orders,
      orElse: () => const <VendorOrder>[],
    );
    final realWaiting = orders
        .where((o) => o.isWaitingTracking)
        .toList(growable: false);
    final noRealOrdersYet = state.maybeWhen(
      loadSuccess: (orders, nextCursor, hasMore, activeFilter) =>
          orders.isEmpty,
      orElse: () => false,
    );
    final isSample = noRealOrdersYet && realWaiting.isEmpty;
    final waiting = isSample ? _sampleOrders : realWaiting;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Orders Waiting Tracking (${waiting.length})',
          style: DesignTokens.oneLinerSemibold,
        ),
      ),
      body: Stack(
        children: [
          state.maybeWhen(
            loadInProgress: () => const Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
              ),
            ),
            orElse: () => Column(
              children: [
                if (isSample)
                  Container(
                    width: double.infinity,
                    color: const Color(0xFF2C2C2E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s8,
                    ),
                    child: Text(
                      'Sample preview — no real orders yet. This will switch to live orders automatically once you have some.',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                Expanded(
                  child: waiting.isEmpty
                      ? Center(
                          child: Text(
                            'No orders waiting for tracking.',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s16,
                            vertical: DesignTokens.s12,
                          ),
                          itemCount: waiting.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: DesignTokens.s4),
                          itemBuilder: (context, index) {
                            final order = waiting[index];
                            return _OrderCard(
                              order: order,
                              actionsEnabled: !isSample,
                              onTap: () => context.push(
                                RouteNames.vendorOrderDetail.replaceFirst(
                                  ':orderId',
                                  order.id,
                                ),
                              ),
                              onAssign: () => _showAssignSheet(order),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          if (_busy)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onAssign,
    this.actionsEnabled = true,
  });

  final VendorOrder order;
  final VoidCallback onTap;
  final VoidCallback onAssign;
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 48×48 icon container
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
            const SizedBox(width: DesignTokens.s12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order number — white 14px semibold
                  Text(
                    'Order #${order.orderNumber}',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Customer name (white) · item count (muted)
                  Row(
                    children: [
                      Text(
                        order.customerName ?? 'Unknown customer',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: DesignTokens.textWhite,
                          height: 1.3,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFF71717B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        '${order.itemCount} items',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9F9FA9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                  if (order.placedAt != null) ...[
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      'Order Date: ${_formatDate(order.placedAt!)}',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 11,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Chevron — opens assign sheet
            if (actionsEnabled)
              GestureDetector(
                onTap: onAssign,
                child: const Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF9F9FA9),
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime utc) {
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
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}

class _AssignTrackingSheet extends StatefulWidget {
  const _AssignTrackingSheet({required this.order, required this.onAssign});

  final VendorOrder order;
  final void Function(String carrier, String trackingNumber) onAssign;

  @override
  State<_AssignTrackingSheet> createState() => _AssignTrackingSheetState();
}

class _AssignTrackingSheetState extends State<_AssignTrackingSheet> {
  static const _carriers = [
    'FedEx',
    'DHL Express',
    'UPS',
    'USPS',
    'Blue Dart',
    'Other',
  ];
  String? _selectedCarrier;
  final _trackingController = TextEditingController();

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _submit() {
    final carrier = _selectedCarrier;
    final trackingNumber = _trackingController.text.trim();
    if (carrier == null || trackingNumber.isEmpty) return;
    Navigator.pop(context);
    widget.onAssign(carrier, trackingNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s16,
            DesignTokens.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle + header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Assign Tracking No.',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
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
              const SizedBox(height: DesignTokens.s16),
              // Order ID
              Text(
                'Order ID',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '#${widget.order.orderNumber}',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              // Carrier dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCarrier,
                    hint: Text(
                      'Carrier',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF2C2C2E),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: DesignTokens.textMuted,
                    ),
                    items: _carriers
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              c,
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textWhite,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCarrier = val),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s12),
              // Tracking number field
              TextField(
                controller: _trackingController,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
                decoration: InputDecoration(
                  hintText: 'Add Tracking No.',
                  hintStyle: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      DesignTokens.inputRadius,
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s12,
                    vertical: DesignTokens.s12,
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s20),
              // Assign button
              SizedBox(
                width: double.infinity,
                height: DesignTokens.buttonHeight,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Assign No. & Notify Customer',
                    style: DesignTokens.smallRegular.copyWith(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
