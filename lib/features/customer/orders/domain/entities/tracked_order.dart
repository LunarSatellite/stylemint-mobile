import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Fulfillment status shown on the Track Orders list.
enum OrderTrackStatus {
  preparingForShipping('Preparing for Shipping'),
  inTransit('In Transit'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  cancelled('Cancelled');

  const OrderTrackStatus(this.label);

  /// Human-readable label rendered on the status pill.
  final String label;
}

/// A single order on the Track Orders list (Figma "Track Orders - Order List").
class TrackedOrder {
  const TrackedOrder({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.placedAt,
    required this.itemCount,
    required this.status,
  });

  final String id;
  final String orderNumber; // e.g. "RC20230126" (rendered as "Order #…")
  final Money total;
  final DateTime placedAt;
  final int itemCount;
  final OrderTrackStatus status;
}
