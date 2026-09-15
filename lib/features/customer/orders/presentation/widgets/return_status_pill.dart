import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_pill.dart';

/// Return state pill: Submitted (info), Approved (progress), Rejected
/// (negative), Completed (success).
class ReturnStatusPill extends StatelessWidget {
  const ReturnStatusPill({required this.status, super.key});

  final ReturnRequestStatus status;

  static OrderPillTone toneFor(ReturnRequestStatus status) => switch (status) {
    ReturnRequestStatus.submitted => OrderPillTone.info,
    ReturnRequestStatus.approved => OrderPillTone.progress,
    ReturnRequestStatus.rejected => OrderPillTone.negative,
    ReturnRequestStatus.completed => OrderPillTone.success,
    ReturnRequestStatus.unknown => OrderPillTone.neutral,
  };

  @override
  Widget build(BuildContext context) =>
      OrderStatusPill(label: status.label, tone: toneFor(status));
}
