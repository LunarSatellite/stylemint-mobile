import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/bulk_action_result.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/packing_slip.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrdersReadyToShipScreen extends ConsumerStatefulWidget {
  const OrdersReadyToShipScreen({super.key});

  @override
  ConsumerState<OrdersReadyToShipScreen> createState() => _OrdersReadyToShipScreenState();
}

class _OrdersReadyToShipScreenState extends ConsumerState<OrdersReadyToShipScreen> {
  // Fallback shown while there are genuinely no real orders yet (new/testing
  // vendor account) — same pattern used on the dashboard's Recent Activity
  // card. Disappears automatically once real orders exist. Actions are
  // disabled on these rows since the ids aren't real sub-orders.
  static final _sampleOrders = [
    VendorOrder(
      id: '_sample-1',
      orderNumber: 'RC20230126',
      itemCount: 3,
      total: const Money(amount: 10000, currency: 'NPR'),
      status: VendorOrderStatus.pending,
      placedAt: DateTime.utc(2024, 12, 16),
      shippingMethod: 'FedEx',
      customerName: 'Balendra Shah',
    ),
    VendorOrder(
      id: '_sample-2',
      orderNumber: 'RC20230125',
      itemCount: 2,
      total: const Money(amount: 41000, currency: 'NPR'),
      status: VendorOrderStatus.confirmed,
      placedAt: DateTime.utc(2024, 12, 15),
      shippingMethod: 'DHL Express',
      customerName: 'Summendra Pandey',
    ),
  ];

  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};
  bool _busy = false;

  void _enterSelectMode() {
    setState(() {
      _isSelectMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _reportBulk(BulkActionResult? result, {required String verb}) {
    if (result == null) {
      _showSnack('Failed to $verb. Please try again.');
      return;
    }
    if (result.failureCount == 0) {
      _showSnack('${result.successCount} order(s) ${verb}ed.');
    } else {
      _showSnack('${result.successCount} succeeded, ${result.failureCount} failed.');
    }
  }

  Future<void> _markSingleShipped(String orderId) async {
    setState(() => _busy = true);
    final ok = await ref.read(vendorOrdersNotifierProvider.notifier).markReadyToShip(orderId);
    if (!mounted) return;
    setState(() => _busy = false);
    _showSnack(ok ? 'Order marked as shipped.' : 'Failed to update order.');
  }

  Future<void> _bulkMarkShipped() async {
    if (_selectedIds.isEmpty) return;
    setState(() => _busy = true);
    final result = await ref
        .read(vendorOrdersNotifierProvider.notifier)
        .bulkMarkReadyToShip(_selectedIds.toList(growable: false));
    if (!mounted) return;
    setState(() => _busy = false);
    _reportBulk(result, verb: 'mark');
    _exitSelectMode();
  }

  Future<void> _printAll(List<VendorOrder> orders) async {
    if (orders.isEmpty) return;
    setState(() => _busy = true);
    final result = await ref
        .read(vendorOrdersNotifierProvider.notifier)
        .bulkPackingSlips(orders.map((o) => o.id).toList(growable: false));
    if (!mounted) return;
    setState(() => _busy = false);
    _reportBulk(result, verb: 'fetch');
  }

  Future<void> _showPackingSlip(String orderId) async {
    setState(() => _busy = true);
    final slip = await ref.read(vendorOrdersNotifierProvider.notifier).getPackingSlip(orderId);
    if (!mounted) return;
    setState(() => _busy = false);
    if (slip == null) {
      _showSnack('Could not load packing slip.');
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

  void _showBulkActions(List<VendorOrder> orders) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: DesignTokens.s8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            _BulkMenuItem(
              icon: Icons.print_outlined,
              label: 'Print All',
              onTap: () {
                Navigator.pop(context);
                _printAll(orders);
              },
            ),
            const Divider(color: Color(0xFF2C2C2E), height: 1, indent: 16, endIndent: 16),
            _BulkMenuItem(
              icon: Icons.check_box_outlined,
              label: 'Select Multiple as Orders Ready to Ship',
              onTap: () {
                Navigator.pop(context);
                _enterSelectMode();
              },
            ),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
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
    final realToShip = orders.where((o) => o.status.isToShip).toList(growable: false);
    final noRealOrdersYet = state.maybeWhen(
      loadSuccess: (orders, nextCursor, hasMore, activeFilter) => orders.isEmpty,
      orElse: () => false,
    );
    final isSample = noRealOrdersYet && realToShip.isEmpty;
    final toShip = isSample ? _sampleOrders : realToShip;

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => _isSelectMode ? _exitSelectMode() : context.pop(),
        ),
        title: Text(
          'Orders Ready to Ship(${toShip.length})',
          style: DesignTokens.oneLinerSemibold,
        ),
        actions: [
          if (!_isSelectMode && toShip.isNotEmpty && !isSample)
            IconButton(
              icon: const Icon(Icons.more_vert, color: DesignTokens.textWhite, size: 22),
              onPressed: _busy ? null : () => _showBulkActions(toShip),
            ),
        ],
      ),
      body: Stack(
        children: [
          state.maybeWhen(
            loadInProgress: () => const Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
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
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.s16,
                      vertical: DesignTokens.s12,
                    ),
                    itemCount: toShip.length,
                    separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s4),
                    itemBuilder: (context, index) {
                      final order = toShip[index];
                      return _OrderCard(
                        order: order,
                        isSelectMode: _isSelectMode,
                        isSelected: _selectedIds.contains(order.id),
                        actionsEnabled: !isSample,
                        onToggle: () => _toggleSelection(order.id),
                        onPrintSlip: () => _showPackingSlip(order.id),
                        onMarkShipped: () => _markSingleShipped(order.id),
                        onViewDetails: () => context.push(
                          RouteNames.vendorOrderDetail.replaceFirst(':orderId', order.id),
                        ),
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
                child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isSelectMode ? _buildSelectBar() : null,
    );
  }

  Widget _buildSelectBar() {
    return Container(
      color: const Color(0xFF1C1C1E),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, DesignTokens.s12,
          ),
          child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _exitSelectMode,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3A3A3C)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  backgroundColor: const Color(0xFF2C2C2E),
                ),
                child: Text(
                  'Cancel',
                  style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedIds.isEmpty || _busy ? null : _bulkMarkShipped,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  disabledBackgroundColor: DesignTokens.primaryGreen.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  'Mark as Shipped',
                  style: DesignTokens.smallRegular.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
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
                  icon: const Icon(Icons.close, color: DesignTokens.textWhite, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            Text('Order #${slip.orderNumber}', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600)),
            if (slip.receiverName != null) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(slip.receiverName!, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite)),
            ],
            if (slip.shippingAddress != null)
              Text(slip.shippingAddress!, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
            const SizedBox(height: DesignTokens.s16),
            Text('Items', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600)),
            const SizedBox(height: DesignTokens.s8),
            if (slip.items.isEmpty)
              Text('No item detail available.', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted))
            else
              ...slip.items.map((i) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(i.productName, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite))),
                        Text('x${i.quantity}', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
                      ],
                    ),
                  )),
            const SizedBox(height: DesignTokens.s16),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isSelectMode,
    required this.isSelected,
    required this.onToggle,
    required this.onPrintSlip,
    required this.onMarkShipped,
    required this.onViewDetails,
    this.actionsEnabled = true,
  });

  final VendorOrder order;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onPrintSlip;
  final VoidCallback onMarkShipped;
  final VoidCallback onViewDetails;

  /// False for sample/fallback rows — hides the 3-dot menu and selection so
  /// a user can't trigger a real API call against a fake id.
  final bool actionsEnabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectMode && actionsEnabled ? onToggle : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelectMode) ...[
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 10, right: DesignTokens.s8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? DesignTokens.primaryGreen : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? DesignTokens.primaryGreen : const Color(0xFF5A5A5E),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.black, size: 14)
                      : null,
                ),
              ),
            ],
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/vendordashboard/icon_ship_box.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: DesignTokens.mediumSemibold,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.customerName ?? 'Unknown customer'} • ${order.itemCount} items',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  if (order.shippingMethod != null) ...[
                    const SizedBox(height: DesignTokens.s6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8E6FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.shippingMethod!,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF024A70),
                        ),
                      ),
                    ),
                  ],
                  if (order.placedAt != null) ...[
                    const SizedBox(height: DesignTokens.s6),
                    Text(
                      'Order Date: ${_formatDate(order.placedAt!)}',
                      style: const TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 11, color: DesignTokens.textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (!isSelectMode && actionsEnabled)
              IconButton(
                icon: const Icon(Icons.more_vert, color: DesignTokens.textMuted, size: 18),
                onPressed: () => _showOrderMenu(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime utc) {
    final local = utc.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  void _showOrderMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: DesignTokens.s8),
            Container(width: 36, height: 4, decoration: BoxDecoration(color: DesignTokens.borderDefault, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: DesignTokens.s12),
            _MenuItem(icon: Icons.print_outlined, label: 'Print Packing Slip', onTap: () {
              Navigator.pop(context);
              onPrintSlip();
            }),
            const Divider(color: Color(0xFF2C2C2E), height: 1, indent: 16, endIndent: 16),
            _MenuItem(icon: Icons.local_shipping_outlined, label: 'Mark as Shipped', onTap: () {
              Navigator.pop(context);
              onMarkShipped();
            }),
            const Divider(color: Color(0xFF2C2C2E), height: 1, indent: 16, endIndent: 16),
            _MenuItem(icon: Icons.remove_red_eye_outlined, label: 'View Details', onTap: () {
              Navigator.pop(context);
              onViewDetails();
            }),
            const SizedBox(height: DesignTokens.s8),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: DesignTokens.textWhite, size: 20),
      title: Text(label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite)),
      trailing: const Icon(Icons.arrow_forward_ios, color: DesignTokens.textMuted, size: 14),
      onTap: onTap,
    );
  }
}

class _BulkMenuItem extends StatelessWidget {
  const _BulkMenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: DesignTokens.textWhite, size: 20),
      title: Text(label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite)),
      trailing: const Icon(Icons.arrow_forward_ios, color: DesignTokens.textMuted, size: 14),
      onTap: onTap,
    );
  }
}
