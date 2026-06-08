import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Vendor order list row — matches "Design Specification Doc - Orders Ready to
/// Ship": 48px icon tile, Order #, "{customer} • {N} items", a Shipping-Method
/// info pill, and "Ship By" (green) + "Order Date" lines.
///
/// `shippingMethod` and `shipBy` aren't on [VendorOrder] yet, so they're
/// deterministic `MOCK` values (method by order-number hash; shipBy = placedAt
/// + 4 days) until the API provides them.
class VendorOrderTile extends StatelessWidget {
  const VendorOrderTile({required this.order, required this.onTap, super.key});

  final VendorOrder order;
  final VoidCallback onTap;

  static const _methods = ['FedEx', 'DHL Express', 'UPS'];

  String get _shippingMethod =>
      _methods[order.orderNumber.hashCode.abs() % _methods.length];

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');
    final shipBy = order.placedAt.add(const Duration(days: 4));

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
                  // {customer} • {N} items
                  Row(
                    children: [
                      Flexible(
                        child: Text(order.customerName,
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
                      Text('${order.items.length} items',
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.textMuted)),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  // Shipping-method info pill.
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s8, vertical: DesignTokens.s4),
                    decoration: BoxDecoration(
                      color: DesignTokens.tagInfoFill,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('Shipping Method: $_shippingMethod',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.tagInfoText,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        )),
                  ),
                  const SizedBox(height: DesignTokens.s8),
                  Wrap(
                    spacing: DesignTokens.s12,
                    children: [
                      Text('Ship By: ${dateFmt.format(shipBy)}',
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.primaryGreen)),
                      Text('Order Date: ${dateFmt.format(order.placedAt)}',
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
