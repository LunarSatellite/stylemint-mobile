import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/customer_return.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_status_pill.dart';

/// Return state pill: Submitted (info), Approved (progress), Rejected
/// (negative), Completed (success).
///
/// Approved and Rejected are the pair a buyer must never misread, and they
/// were previously green and red and nothing else. Each state now carries its
/// own glyph too.
class ReturnStatusPill extends StatelessWidget {
  const ReturnStatusPill({required this.status, super.key, this.dense = false});

  final ReturnRequestStatus status;

  /// Tighter padding, for list rows.
  final bool dense;

  static OrderPillTone toneFor(ReturnRequestStatus status) => switch (status) {
    ReturnRequestStatus.submitted => OrderPillTone.info,
    ReturnRequestStatus.approved => OrderPillTone.progress,
    ReturnRequestStatus.rejected => OrderPillTone.negative,
    ReturnRequestStatus.completed => OrderPillTone.success,
    ReturnRequestStatus.unknown => OrderPillTone.neutral,
  };

  static IconData iconFor(ReturnRequestStatus status) => switch (status) {
    ReturnRequestStatus.submitted => Icons.assignment_outlined,
    ReturnRequestStatus.approved => Icons.thumb_up_outlined,
    ReturnRequestStatus.rejected => Icons.do_not_disturb_alt_rounded,
    ReturnRequestStatus.completed => Icons.check_circle_outline_rounded,
    ReturnRequestStatus.unknown => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) => OrderStatusPill(
    label: status.label,
    tone: toneFor(status),
    icon: iconFor(status),
    dense: dense,
  );
}
