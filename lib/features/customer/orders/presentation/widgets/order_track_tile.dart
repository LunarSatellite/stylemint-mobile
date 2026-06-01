import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One row on the Track Orders list: package icon, order number, meta line,
/// status pill, chevron. Matches Figma "Track Orders - Order List".
class OrderTrackTile extends StatelessWidget {
  const OrderTrackTile({required this.order, required this.onTap, super.key});

  final TrackedOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta =
        '${formatMoney(order.total)} • '
        '${DateFormat('HH:mm MMM d, yyyy').format(order.placedAt)} • '
        '${order.itemCount} items';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: DesignTokens.secondaryYellow,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
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
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    meta,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  _StatusPill(label: order.status.label),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.iconLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.tagInfoFill,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Text(
        label,
        style: DesignTokens.smallRegular.copyWith(
          color: DesignTokens.tagInfoText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
