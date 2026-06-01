import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({required this.status, super.key});

  final OrderTrackStatus status;

  Color get _backgroundColor {
    switch (status) {
      case OrderTrackStatus.preparingForShipping:
        return const Color(0xFFFFC107); // amber
      case OrderTrackStatus.inTransit:
        return const Color(0xFF2196F3); // blue
      case OrderTrackStatus.outForDelivery:
        return const Color(0xFFFF9800); // orange
      case OrderTrackStatus.delivered:
        return const Color(0xFF4CAF50); // green
      case OrderTrackStatus.cancelled:
        return const Color(0xFFF44336); // red
    }
  }

  Color get _textColor {
    switch (status) {
      case OrderTrackStatus.preparingForShipping:
        return const Color(0xFF4E342E);
      case OrderTrackStatus.inTransit:
      case OrderTrackStatus.outForDelivery:
      case OrderTrackStatus.delivered:
      case OrderTrackStatus.cancelled:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s12,
        vertical: DesignTokens.s6,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Text(
        status.label,
        style: DesignTokens.smallRegular.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
