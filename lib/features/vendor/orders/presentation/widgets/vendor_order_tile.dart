import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorOrderTile extends StatelessWidget {
  const VendorOrderTile({required this.order, required this.onTap, super.key});

  final VendorOrder order;
  final VoidCallback onTap;

  Color _statusColor() {
    return switch (order.status) {
      VendorOrderStatus.pending => DesignTokens.colorWarning,
      VendorOrderStatus.confirmed => DesignTokens.colorInfo,
      VendorOrderStatus.processing => const Color(0xFFFF9800),
      VendorOrderStatus.shipped => const Color(0xFF9C27B0),
      VendorOrderStatus.delivered => DesignTokens.primaryGreen,
      VendorOrderStatus.cancelled => DesignTokens.colorError,
      VendorOrderStatus.returned => DesignTokens.textMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s6,
        ),
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Order #${order.orderNumber}',
                    style: DesignTokens.mediumSemibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(label: order.status.label, color: _statusColor()),
              ],
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              order.customerName,
              style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textLight),
            ),
            const SizedBox(height: DesignTokens.s4),
            Row(
              children: [
                Text(
                  '${order.items.length} item(s)',
                  style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted),
                ),
                const SizedBox(width: DesignTokens.s12),
                Text(
                  formatMoney(order.total),
                  style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              dateFmt.format(order.placedAt),
              style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Text(
        label,
        style: DesignTokens.tiny.copyWith(
            color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
