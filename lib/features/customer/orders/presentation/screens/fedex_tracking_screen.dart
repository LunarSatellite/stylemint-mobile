import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FedExTrackingScreen extends StatelessWidget {
  const FedExTrackingScreen({required this.order, super.key});

  final OrderDetail order;

  @override
  Widget build(BuildContext context) {
    final tracking = order.trackingNumber ?? 'Pending';
    final start = order.estimatedDelivery;
    final end = start.add(const Duration(days: 2));
    final expectedDelivery =
        '${DateFormat('MMM dd').format(start)}-${DateFormat('dd').format(end)} ${start.year}';

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'FedEx Tracking',
          style: DesignTokens.sectionInnerTitle,
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          // ── Order Card ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DesignTokens.cardDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  'assets/icons/OrderImage.svg',
                  width: 52,
                  height: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Carrier: FedEx Express',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Expected delivery pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1F38),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_shipping_outlined,
                              size: 12,
                              color: Color(0xFF4FC3F7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Expected Delivery: $expectedDelivery',
                              style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4FC3F7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tracking ID
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: tracking));
                          SmSnackbar.success(context, 'Tracking ID copied!');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tracking ID: $tracking',
                              style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF00BCFF),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.copy_outlined,
                              size: 14,
                              color: Color(0xFF00BCFF),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Tracking History ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tracking History',
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 16),
                _HorizontalTimeline(status: order.status),
                const SizedBox(height: 12),
                const Center(
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Shipping Address Card ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: DesignTokens.cardDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A1800),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFFF5A623),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shipping Address',
                        style: DesignTokens.mediumSemibold.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '+977 9840065322  •  customer@stylemint.com',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF00BCFF),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.shippingAddress,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── 3 action cards ───────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Contact\nFedEx',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Contact\nStyleMint',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionCard(
                  icon: Icons.location_on_outlined,
                  label: 'Change\nAddress',
                ),
              ),
            ],
          ),
        ],
      ),

      // ── View on FedEx Website button ─────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () =>
                  SmSnackbar.info(context, 'Opening FedEx website...'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View on FedEx Website',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.black,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Horizontal 4-step timeline ────────────────────────────────────────────────

class _HorizontalTimeline extends StatelessWidget {
  const _HorizontalTimeline({required this.status});

  final OrderTrackStatus status;

  static const _stages = [
    ('Shipped', Icons.inventory_2_outlined),
    ('In Transit', Icons.local_shipping_outlined),
    ('Out for\nDelivery', Icons.airport_shuttle_rounded),
    ('Delivered', Icons.done_all_rounded),
  ];

  int get _currentIndex => switch (status) {
    OrderTrackStatus.preparingForShipping => 0,
    OrderTrackStatus.inTransit => 1,
    OrderTrackStatus.outForDelivery => 2,
    OrderTrackStatus.delivered => 4,
    OrderTrackStatus.cancelled => -1,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _stages.length; i++) ...[
          _TimelineStep(
            icon: _stages[i].$2,
            label: _stages[i].$1,
            isDone: i < _currentIndex,
            isCurrent: i == _currentIndex,
          ),
          if (i < _stages.length - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: LayoutBuilder(
                  builder: (_, c) => CustomPaint(
                    size: Size(c.maxWidth, 1.5),
                    painter: _DashedLine(),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isCurrent,
  });

  final IconData icon;
  final String label;
  final bool isDone;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final Color bg = (isDone || isCurrent)
        ? const Color(0xFF052E16)
        : DesignTokens.bgAppBodyLight;
    final Color fg = (isDone || isCurrent)
        ? DesignTokens.primaryGreen
        : DesignTokens.iconLight;

    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: fg, size: 24),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 16,
            child: isDone
                ? const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: DesignTokens.primaryGreen,
                  )
                : isCurrent
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4FC3F7),
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              height: 1.2,
              color: DesignTokens.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = DesignTokens.borderDefault
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Action card ───────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: DesignTokens.cardDecoration(),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: DesignTokens.iconLight),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
