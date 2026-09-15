import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_delivery.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Delivers in 3–5 days" / "Ships in 2 days" under the price. Hidden when
/// the product carries neither shipping transit times nor a processing time.
class DeliveryEstimateLine extends StatelessWidget {
  const DeliveryEstimateLine({
    required this.delivery,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final ProductDelivery? delivery;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final label = delivery?.estimateLabel;
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            size: 18,
            color: DesignTokens.primaryGreen,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: DesignTokens.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
