import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrdersReadyToShipScreen extends StatefulWidget {
  const OrdersReadyToShipScreen({super.key});

  @override
  State<OrdersReadyToShipScreen> createState() => _OrdersReadyToShipScreenState();
}

class _OrdersReadyToShipScreenState extends State<OrdersReadyToShipScreen> {
  static final _orders = [
    _ShipOrder(
      id: '1',
      orderNumber: 'Order #RC20230126',
      customerName: 'Balendra Shah',
      itemCount: 3,
      shippingMethod: 'FedEx',
      shipBy: 'Dec 20, 2024',
      orderDate: 'Dec 16, 2024',
      assetTag: null,
    ),
    _ShipOrder(
      id: '2',
      orderNumber: 'Order #RC20230125',
      customerName: 'Summendra Pandey',
      itemCount: 2,
      shippingMethod: 'DHL Express',
      shipBy: 'Dec 17, 2024',
      orderDate: 'Dec 15, 2024',
      assetTag: null,
    ),
  ];

  bool _isSelectMode = false;
  final Set<String> _selectedIds = {};

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

  void _showBulkActions() {
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
              onTap: () => Navigator.pop(context),
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
          'Orders Ready to Ship(${_orders.length})',
          style: DesignTokens.oneLinerSemibold,
        ),
        actions: [
          if (!_isSelectMode)
            IconButton(
              icon: const Icon(Icons.more_vert, color: DesignTokens.textWhite, size: 22),
              onPressed: _showBulkActions,
            ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s4),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _OrderCard(
            order: order,
            isSelectMode: _isSelectMode,
            isSelected: _selectedIds.contains(order.id),
            onToggle: () => _toggleSelection(order.id),
          );
        },
      ),
      bottomNavigationBar: _isSelectMode ? _buildSelectBar() : null,
    );
  }

  Widget _buildSelectBar() {
    return Container(
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, DesignTokens.s24,
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
                onPressed: _selectedIds.isEmpty ? null : () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  disabledBackgroundColor: DesignTokens.primaryGreen.withOpacity(0.4),
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
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.isSelectMode,
    required this.isSelected,
    required this.onToggle,
  });

  final _ShipOrder order;
  final bool isSelectMode;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSelectMode ? onToggle : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox (select mode) or nothing
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
            // Package icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.asset('assets/images/vendordashboard/icon_ship_box.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.orderNumber,
                    style: DesignTokens.smallRegular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order.customerName} • ${order.itemCount} items',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8E6FE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.shippingMethod,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D1B2A),
                      ),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 11),
                      children: [
                        TextSpan(
                          text: 'Ship By: ${order.shipBy}',
                          style: const TextStyle(color: DesignTokens.primaryGreen, fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: ' • Order Date: ${order.orderDate}',
                          style: TextStyle(color: DesignTokens.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 3-dot (hidden in select mode)
            if (!isSelectMode)
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
            _MenuItem(icon: Icons.print_outlined, label: 'Print Packing Slip', onTap: () => Navigator.pop(context)),
            const Divider(color: Color(0xFF2C2C2E), height: 1, indent: 16, endIndent: 16),
            _MenuItem(icon: Icons.local_shipping_outlined, label: 'Mark as Shipped', onTap: () => Navigator.pop(context)),
            const Divider(color: Color(0xFF2C2C2E), height: 1, indent: 16, endIndent: 16),
            _MenuItem(icon: Icons.remove_red_eye_outlined, label: 'View Details', onTap: () => Navigator.pop(context)),
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

class _ShipOrder {
  const _ShipOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.itemCount,
    required this.shippingMethod,
    required this.shipBy,
    required this.orderDate,
    this.assetTag,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final int itemCount;
  final String shippingMethod;
  final String shipBy;
  final String orderDate;
  final String? assetTag;
}
