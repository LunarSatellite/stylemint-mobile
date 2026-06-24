import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
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
        title: Text('Orders Waiting Tracking (${_orders.length})', style: DesignTokens.oneLinerSemibold),
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
          onTap: () => context.push(
            RouteNames.vendorOrderDetail
                .replaceFirst(':orderId', _orders[index].id),
          ),
          onAssign: () => _showAssignSheet(context, _orders[index]),
        ),
      ),
    );
  }

  void _showAssignSheet(BuildContext context, _TrackingOrder order) {
    showModalBottomSheet<void>(
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
  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onAssign,
  });

  final _TrackingOrder order;
  final VoidCallback onTap;
  final VoidCallback onAssign;

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
                  order.orderNumber,
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
                      order.customerName,
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
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
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
                const SizedBox(height: DesignTokens.s8),

                // Shipping Method chip — #B8E6FE bg, #024A70 text, truck icon
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const SizedBox(height: DesignTokens.s4),

                // Ship By (green) · Order Date (muted) — 11px
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 11,
                      height: 1.2,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Ship By: ',
                        style: TextStyle(
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: order.shipBy,
                        style: const TextStyle(
                          color: DesignTokens.primaryGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(
                        text: ' • ',
                        style: TextStyle(color: Color(0xFF71717B)),
                      ),
                      TextSpan(
                        text: 'Order Date: ${order.orderDate}',
                        style: const TextStyle(color: Color(0xFF9F9FA9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Chevron — opens assign sheet
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
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String customerName;
  final int itemCount;
  final String shippingMethod;
  final String shipBy;
  final String orderDate;
}
