import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrderWaitingTrackingScreen extends StatefulWidget {
  const OrderWaitingTrackingScreen({super.key});

  @override
  State<OrderWaitingTrackingScreen> createState() => _OrderWaitingTrackingScreenState();
}

class _OrderWaitingTrackingScreenState extends State<OrderWaitingTrackingScreen> {
  static final _orders = [
    _TrackingOrder(
      id: '1',
      orderId: '#RC20230126',
      orderNumber: 'Order #RC20230126',
      customerName: 'Balendra Shah',
      itemCount: 3,
      shippingMethod: 'FedEx',
      shipBy: 'Dec 20, 2024',
      orderDate: 'Dec 15, 2024',
      assetTag: 'assets/images/tag_fedex.png',
    ),
    _TrackingOrder(
      id: '2',
      orderId: '#RC20230125',
      orderNumber: 'Order #RC20230125',
      customerName: 'Summendra Pandey',
      itemCount: 2,
      shippingMethod: 'DHL Express',
      shipBy: 'Dec 17, 2024',
      orderDate: 'Dec 15, 2024',
      assetTag: 'assets/images/tag_dhl.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text('Order Waiting Tracking...', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: DesignTokens.textWhite, size: 22),
            onPressed: () {},
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
        itemBuilder: (context, index) => _OrderCard(
          order: _orders[index],
          onAssign: () => _showAssignSheet(context, _orders[index]),
        ),
      ),
    );
  }

  void _showAssignSheet(BuildContext context, _TrackingOrder order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AssignTrackingSheet(order: order),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onAssign});

  final _TrackingOrder order;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              child: Image.asset('assets/images/icon_ship_box.png', fit: BoxFit.contain),
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
                if (order.assetTag != null)
                  Image.asset(order.assetTag!, height: 26, fit: BoxFit.contain),
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
          // Chevron
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: DesignTokens.textMuted, size: 16),
            onPressed: onAssign,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _AssignTrackingSheet extends StatefulWidget {
  const _AssignTrackingSheet({required this.order});

  final _TrackingOrder order;

  @override
  State<_AssignTrackingSheet> createState() => _AssignTrackingSheetState();
}

class _AssignTrackingSheetState extends State<_AssignTrackingSheet> {
  static const _carriers = ['FedEx', 'DHL Express', 'UPS', 'USPS', 'Blue Dart', 'Other'];
  String? _selectedCarrier;
  final _trackingController = TextEditingController();

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle + header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assign Tracking No.', style: DesignTokens.mediumSemibold),
                IconButton(
                  icon: const Icon(Icons.close, color: DesignTokens.textWhite, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
            // Order ID
            Text('Order ID', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(widget.order.orderId, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600)),
            const SizedBox(height: DesignTokens.s16),
            // Carrier dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCarrier,
                  hint: Text('Carrier', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
                  isExpanded: true,
                  dropdownColor: const Color(0xFF2C2C2E),
                  icon: const Icon(Icons.keyboard_arrow_down, color: DesignTokens.textMuted),
                  items: _carriers.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedCarrier = val),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            // Tracking number field
            TextField(
              controller: _trackingController,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite),
              decoration: InputDecoration(
                hintText: 'Add Tracking No.',
                hintStyle: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: DesignTokens.s12),
              ),
            ),
            const SizedBox(height: DesignTokens.s20),
            // Assign button
            SizedBox(
              width: double.infinity,
              height: DesignTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Text(
                  'Assign No. & Notify Customer',
                  style: DesignTokens.smallRegular.copyWith(color: Colors.black, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingOrder {
  const _TrackingOrder({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.itemCount,
    required this.shippingMethod,
    required this.shipBy,
    required this.orderDate,
    this.assetTag,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final int itemCount;
  final String shippingMethod;
  final String shipBy;
  final String orderDate;
  final String? assetTag;
}
