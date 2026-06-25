import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorOrderDetailScreen extends StatefulWidget {
  const VendorOrderDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  State<VendorOrderDetailScreen> createState() =>
      _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends State<VendorOrderDetailScreen> {
  bool _itemsExpanded = true;
  bool _revenueExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: DesignTokens.textWhite, size: 18),
          onPressed: () => context.pop(),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline,
                color: DesignTokens.textWhite, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline,
                color: DesignTokens.textWhite, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OrderSummaryCard(),
                  const SizedBox(height: 12),
                  _CustomerCard(),
                  const SizedBox(height: 12),
                  _ShippingCard(),
                  const SizedBox(height: 12),
                  _OrderItemsCard(
                    expanded: _itemsExpanded,
                    onToggle: () =>
                        setState(() => _itemsExpanded = !_itemsExpanded),
                  ),
                  const SizedBox(height: 12),
                  _RevenueBreakdownCard(
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryGreen,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Mark as Shipped',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C2C2E),
                      foregroundColor: DesignTokens.textWhite,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Print Shipping Label',
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order Summary card
// ---------------------------------------------------------------------------

class _OrderSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order box icon
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
                const Text(
                  'Order #RC20230126',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Placed on 17:52 Dec 16, 2024  •  Rs 10,000',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: Color(0xFF9F9FA9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8E6FE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'Ready to Ship',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF024A70),
                      height: 1.0,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ship By: Dec 20, 2024',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: Color(0xFF9F9FA9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Customer card
// ---------------------------------------------------------------------------

class _CustomerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer icon
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer: John Doe',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '+977 9840065322  •  johndoe@gmail.com',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: Color(0xFF9F9FA9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Special Message',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Please call before delivery',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          color: Color(0xFF9F9FA9),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

class _ShippingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shipping address icon
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8E6FE),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.local_shipping_outlined,
                          size: 12, color: Color(0xFF024A70)),
                      SizedBox(width: 4),
                      Text(
                        'Shipping Method: DHL Express',
                        style: TextStyle(
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
                const Text(
                  'Mandala Street, Thamel  •  Kathmandu, Nepal',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    color: Color(0xFF9F9FA9),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tracking ID: FDX12358947',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.primaryGreen,
                    height: 1.3,
                  ),
                ),
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
    required this.expanded,
    required this.onToggle,
  });

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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
          const Text(
            'No. of items: 2',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: Color(0xFF9F9FA9),
              height: 1.3,
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),

            // Product row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 80,
                    color: const Color(0xFF2C2C2E),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=200',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFF9F9FA9),
                        size: 36,
                      ),
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
                          const Expanded(
                            child: Text(
                              'Nike Air Jordan Travis Scott Limited Edition',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: DesignTokens.textWhite,
                                height: 1.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Qty chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: DesignTokens.primaryGreen,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'Qty: 2',
                              style: TextStyle(
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
                      const Text(
                        'Coffee Brown Color  •  42 Size',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          color: Color(0xFF9F9FA9),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'From: @aileen.ace43 (15% Commission)',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          color: Color(0xFF9F9FA9),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Rs 9,000',
                          style: TextStyle(
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
            ),
            const SizedBox(height: 14),

            const _DashedDivider(),
            const SizedBox(height: 12),

            // Pricing rows
            _PricingRow(
              icon: Icons.inventory_2_outlined,
              label: 'Subtotal',
              value: 'Rs 18,000',
            ),
            const SizedBox(height: 10),
            _PricingRow(
              icon: Icons.local_shipping_outlined,
              label: 'Shipping',
              value: 'Free',
            ),
            const SizedBox(height: 10),
            _PricingRow(
              icon: Icons.percent,
              label: 'Tax',
              value: '1,800',
            ),
            const SizedBox(height: 10),
            _PricingRow(
              icon: Icons.credit_card_outlined,
              label: 'Payment Method',
              value: 'Visa ****4532',
            ),
            const SizedBox(height: 14),

            const _DashedDivider(),
            const SizedBox(height: 12),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Total',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
                Text(
                  'Rs 19,800',
                  style: TextStyle(
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Revenue Breakdown card (expandable)
// ---------------------------------------------------------------------------

class _RevenueBreakdownCard extends StatelessWidget {
  const _RevenueBreakdownCard({
    required this.expanded,
    required this.onToggle,
  });

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
                  'Revenue Breakdown',
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
          const Text(
            'Net Revenue: Rs 18,200',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: Color(0xFF9F9FA9),
              height: 1.3,
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            _PricingRow(
              icon: Icons.inventory_2_outlined,
              label: 'Order Total',
              value: 'Rs 19,800',
            ),
            const SizedBox(height: 10),
            _PricingRow(
              icon: Icons.percent,
              label: 'Platform Fee (5%)',
              value: '-Rs 300',
              valueColor: const Color(0xFFE74C3C),
            ),
            const SizedBox(height: 10),
            _PricingRow(
              icon: Icons.percent,
              label: 'Payment Processing',
              value: '-Rs 300',
              valueColor: const Color(0xFFE74C3C),
            ),
            const SizedBox(height: 10),
            _PricingRow(
              icon: Icons.local_offer_outlined,
              label: 'Creator Commission (15%)',
              value: '-Rs 1,200',
              valueColor: const Color(0xFFE74C3C),
            ),
            const SizedBox(height: 14),

            const _DashedDivider(),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Net Revenue',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
                Text(
                  'Rs 18,200',
                  style: TextStyle(
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

class _PricingRow extends StatelessWidget {
  const _PricingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9F9FA9)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              color: Color(0xFF9F9FA9),
              height: 1.3,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: valueColor ?? DesignTokens.textWhite,
            height: 1.3,
          ),
        ),
      ],
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
