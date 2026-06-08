import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor order list row — matches "Design Specification Doc - Orders Ready to
/// Ship": 48px icon tile, Order #, "{customer} • {N} items", a Shipping-Method
/// info pill, and the order date.
///
/// Shipping method (carrier) appears once the order is shipped. Customer name
/// and a "Ship By" deadline aren't on /v1/vendor/sub-orders yet (BACKEND GAP),
/// so the row falls back to the item count and the real order date.
class VendorOrderTile extends StatelessWidget {
  const VendorOrderTile({required this.order, required this.onTap, super.key});

  final VendorOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: DesignTokens.s16, vertical: DesignTokens.s6),
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 48x48 icon tile.
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(DesignTokens.s4),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBodyLight,
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.inventory_2_outlined,
                  size: 32, color: DesignTokens.secondaryYellow),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.orderNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DesignTokens.mediumSemibold
                          .copyWith(color: DesignTokens.textWhite)),
                  const SizedBox(height: DesignTokens.s4),
                  // {customer} • {N} items  (customer hidden until backend adds it)
                  Row(
                    children: [
                      if (order.customerName != null) ...[
                        Flexible(
                          child: Text(order.customerName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: DesignTokens.smallRegular
                                  .copyWith(color: DesignTokens.textWhite)),
                        ),
                        Container(
                          width: 3,
                          height: 3,
                          margin: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.s8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF71717B),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                      Text('${order.itemCount} items',
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.textMuted)),
                    ],
                  ),
                  // Shipping-method info pill — only once a carrier is set.
                  if (order.shippingMethod != null &&
                      order.shippingMethod!.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s8,
                          vertical: DesignTokens.s4),
                      decoration: BoxDecoration(
                        color: DesignTokens.tagInfoFill,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('Shipping Method: ${order.shippingMethod}',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.tagInfoText,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          )),
                    ),
                  ],
                  if (order.placedAt != null) ...[
                    const SizedBox(height: DesignTokens.s8),
                    Text('Order Date: ${dateFmt.format(order.placedAt!)}',
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.textMuted)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
