import 'package:stylemint_mobile_frontend/shared/domain/entities/return_evidence.dart';

/// Backend `ReturnRequestState` 1-5. [cancelled] (5) is the buyer cancelling
/// before the rider collected the item (return pickup contract §4).
enum VendorReturnRequestState {
  submitted,
  approved,
  rejected,
  completed,
  cancelled,
}

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
    this.evidence,
    this.reasonCategory,
    this.pickupFarePayer,
    this.pickupStage,
    this.pickupAware = false,
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

  /// What the platform already knew at submission — byte-for-byte the same
  /// snapshot the buyer is shown. Null on older returns.
  final ReturnEvidence? evidence;

  /// Return pickup contract §4, as sent (`Damaged`, `ChangedMind`, …); null
  /// on older returns.
  final String? reasonCategory;

  /// `Seller` or `Buyer`; null on older returns.
  final String? pickupFarePayer;

  /// The rider pickup's `stage` string; null when there is none.
  final String? pickupStage;

  /// The row carried the `pickupStage` key at all (even as null): the
  /// backend has rider pickups, so a return with none can be offered "Find a
  /// rider". False from an older backend, where nothing new is shown.
  final bool pickupAware;

  bool get isPending => state == VendorReturnRequestState.submitted;
}
