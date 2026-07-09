enum VendorReturnRequestState { submitted, approved, rejected, completed }

/// Vendor §8.1 — a customer return request awaiting (or past) the
/// vendor's accept/reject decision. Backed by `GET /v1/vendor/returns`.
class VendorReturnRequest {
  const VendorReturnRequest({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.subOrderId,
    required this.subOrderLineId,
    required this.productTitleSnapshot,
    required this.quantity,
    required this.reason,
    required this.state,
    required this.submittedUtc,
    this.variantLabelSnapshot,
    this.thumbnailUrlSnapshot,
    this.resolvedUtc,
    this.rejectionNote,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String subOrderId;
  final String subOrderLineId;
  final String productTitleSnapshot;
  final String? variantLabelSnapshot;
  final String? thumbnailUrlSnapshot;
  final int quantity;
  final String reason;
  final VendorReturnRequestState state;
  final DateTime submittedUtc;
  final DateTime? resolvedUtc;
  final String? rejectionNote;

  bool get isPending => state == VendorReturnRequestState.submitted;
}
