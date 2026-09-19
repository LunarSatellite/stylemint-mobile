import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
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
          onPressed: () => context.popOrHome(),
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
                      MallStatusPill(
                        label: 'Expected delivery $expectedDelivery',
                        tone: MallStatusTone.info,
                        icon: Icons.local_shipping_outlined,
                        dense: true,
                      ),
                      const SizedBox(height: 8),
                      // Tracking ID
                      Semantics(
                        button: true,
                        label: 'Copy tracking ID $tracking',
                        child: GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: tracking));
                            SmSnackbar.success(context, 'Tracking ID copied!');
                          },
                          behavior: HitTestBehavior.opaque,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: DesignTokens.minTouchTarget,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Tracking ID $tracking',
                                    style: DesignTokens.smallRegular.copyWith(
                                      color: DesignTokens.textLight,
                                      fontWeight: FontWeight.w500,
                                      fontFeatures: mallTabularFigures,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.s6),
                                const Icon(
                                  Icons.copy_outlined,
                                  size: 14,
                                  color: DesignTokens.primaryGreen,
                                ),
                              ],
                            ),
                          ),
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
                    color: DesignTokens.bgAppBodyLight,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: DesignTokens.textLight,
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
                          color: DesignTokens.primaryGreen,
                          fontFeatures: mallTabularFigures,
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
    'Shipped',
    'In transit',
    'Out for delivery',
    'Delivered',
  ];

  int get _currentIndex => switch (status) {
    OrderTrackStatus.preparingForShipping => 0,
    OrderTrackStatus.inTransit => 1,
    OrderTrackStatus.outForDelivery => 2,
    OrderTrackStatus.delivered => 4,
    OrderTrackStatus.cancelled => -1,
  };

  MallStepState _stateFor(int i) {
    if (status == OrderTrackStatus.cancelled) return MallStepState.skipped;
    if (i < _currentIndex) return MallStepState.done;
    if (i == _currentIndex) return MallStepState.current;
    return MallStepState.upcoming;
  }

  @override
  Widget build(BuildContext context) => MallStatusStepper(
    semanticLabel: 'Delivery stages',
    steps: [
      for (var i = 0; i < _stages.length; i++)
        MallTimelineStep(title: _stages[i], state: _stateFor(i)),
    ],
  );
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
