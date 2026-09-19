import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_pill.dart';

/// The one place a [OrderTrackStatus] becomes a visible state.
///
/// It used to be a five-colour Material palette (amber / blue / orange /
/// green / red) that existed nowhere else in the app, and Track Orders had
/// grown its own private copy with a *third* set of colours. Both now resolve
/// here, onto the kit's tones and glyphs, so a state looks the same wherever
/// the buyer meets it — and is still readable with the colour taken away.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({required this.status, super.key, this.dense = false});

  final OrderTrackStatus status;

  /// Tighter padding, for list rows.
  final bool dense;

  static OrderPillTone toneFor(OrderTrackStatus status) => switch (status) {
    OrderTrackStatus.preparingForShipping => OrderPillTone.info,
    OrderTrackStatus.inTransit => OrderPillTone.progress,
    OrderTrackStatus.outForDelivery => OrderPillTone.progress,
    OrderTrackStatus.delivered => OrderPillTone.success,
    OrderTrackStatus.cancelled => OrderPillTone.negative,
  };

  /// Each state owns a distinct mark. Out for delivery and In transit share a
  /// tone but not a glyph, because to a buyer waiting at home they are the
  /// difference between today and next week.
  static IconData iconFor(OrderTrackStatus status) => switch (status) {
    OrderTrackStatus.preparingForShipping => Icons.inventory_2_outlined,
    OrderTrackStatus.inTransit => Icons.local_shipping_outlined,
    OrderTrackStatus.outForDelivery => Icons.directions_run_rounded,
    OrderTrackStatus.delivered => Icons.check_circle_outline_rounded,
    OrderTrackStatus.cancelled => Icons.cancel_outlined,
  };

  @override
  Widget build(BuildContext context) => OrderStatusPill(
    label: status.label,
    tone: toneFor(status),
    icon: iconFor(status),
    dense: dense,
  );
}
