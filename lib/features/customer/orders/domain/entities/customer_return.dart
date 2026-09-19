import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

/// Backend `ReturnRequestState`: 1 Submitted, 2 Approved, 3 Rejected,
/// 4 Completed. [unknown] keeps a newer backend value from crashing.
enum ReturnRequestStatus {
  submitted(1, 'Submitted'),
  approved(2, 'Approved'),
  rejected(3, 'Rejected'),
  completed(4, 'Completed'),
  unknown(0, 'In review');

  const ReturnRequestStatus(this.value, this.label);

  final int value;
  final String label;

  static ReturnRequestStatus fromValue(int value) => ReturnRequestStatus.values
      .firstWhere((s) => s.value == value, orElse: () => unknown);
}

enum CustomerReturnResolution {
  refund,
  replacement;

  static CustomerReturnResolution fromCode(int code) => code == 2
      ? CustomerReturnResolution.replacement
      : CustomerReturnResolution.refund;
}

enum CustomerReplacementState {
  none,
  inventoryHeld,
  awaitingReturnedItem,
  readyToShip,
  shipped,
  delivered,
  cancelled,
  awaitingBalancePayment;

  static CustomerReplacementState fromCode(int code) => switch (code) {
    1 => CustomerReplacementState.inventoryHeld,
    2 => CustomerReplacementState.awaitingReturnedItem,
    3 => CustomerReplacementState.readyToShip,
    4 => CustomerReplacementState.shipped,
    5 => CustomerReplacementState.delivered,
    6 => CustomerReplacementState.cancelled,
    7 => CustomerReplacementState.awaitingBalancePayment,
    _ => CustomerReplacementState.none,
  };
}

/// Frozen line snapshot captured at order placement.
class ReturnProductSnapshot {
  const ReturnProductSnapshot({
    required this.productVariantId,
    required this.title,
    required this.unitPrice,
    this.variantLabel,
    this.thumbnailUrl,
  });

  final String productVariantId;
  final String title;
  final String? variantLabel;
  final String? thumbnailUrl;
  final Money unitPrice;
}

/// One return state change; [occurredUtc] is null when no time was stored.
class ReturnTimelineEntry {
  const ReturnTimelineEntry({required this.status, this.occurredUtc});

  final ReturnRequestStatus status;
  final DateTime? occurredUtc;
}

/// Buyer view of a return request (`GET /v1/orders/returns[/{id}]`).
class CustomerReturn {
  const CustomerReturn({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.subOrderId,
    required this.subOrderLineId,
    required this.product,
    required this.quantity,
    required this.reason,
    required this.photoUrls,
    required this.status,
    required this.submittedUtc,
    required this.timeline,
    this.resolvedUtc,
    this.rejectionNote,
    this.refundStatus,
    this.resolution = CustomerReturnResolution.refund,
    this.replacementVariantId,
    this.replacementUnitPrice,
    this.replacementPriceDifferenceAmount,
    this.replacementState = CustomerReplacementState.none,
    this.replacementPaymentStatus,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String subOrderId;
  final String subOrderLineId;
  final ReturnProductSnapshot product;
  final int quantity;
  final String reason;
  final List<String> photoUrls;
  final ReturnRequestStatus status;
  final DateTime submittedUtc;
  final DateTime? resolvedUtc;
  final String? rejectionNote;
  final List<ReturnTimelineEntry> timeline;

  /// Always null today (contract §4); the UI shows a placeholder.
  final String? refundStatus;
  final CustomerReturnResolution resolution;
  final String? replacementVariantId;
  final Money? replacementUnitPrice;
  final double? replacementPriceDifferenceAmount;
  final CustomerReplacementState replacementState;
  final String? replacementPaymentStatus;
}
