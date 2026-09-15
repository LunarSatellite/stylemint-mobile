import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Status pill for a vendor sub-order, coloured by stage: neutral before
/// payment, info while confirming, green tint through the seller steps and
/// transit, solid green when delivered, red when cancelled, warning when
/// returned.
class VendorOrderStatusBadge extends StatelessWidget {
  const VendorOrderStatusBadge({required this.status, super.key});

  final VendorOrderStatus status;

  static (Color, Color) colorsFor(VendorOrderStatus status) => switch (status) {
    VendorOrderStatus.pending => (
      DesignTokens.bgAppBodyLight,
      DesignTokens.textLight,
    ),
    VendorOrderStatus.confirmed || VendorOrderStatus.processing => (
      DesignTokens.infoFillDark,
      DesignTokens.infoTextLight,
    ),
    VendorOrderStatus.accepted ||
    VendorOrderStatus.packed ||
    VendorOrderStatus.handedOver ||
    VendorOrderStatus.shipped => (
      DesignTokens.primaryGreen.withValues(alpha: 0.16),
      DesignTokens.primaryGreen,
    ),
    VendorOrderStatus.delivered => (
      DesignTokens.primaryGreen,
      DesignTokens.buttonPrimaryText,
    ),
    VendorOrderStatus.cancelled => (
      DesignTokens.colorError.withValues(alpha: 0.16),
      DesignTokens.colorError,
    ),
    VendorOrderStatus.returned => (
      DesignTokens.warningFillDark,
      DesignTokens.warningTextLight,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = colorsFor(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 4),
        child: Text(
          status.label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
