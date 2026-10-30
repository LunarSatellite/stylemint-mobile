import 'package:stylemint_mobile_frontend/shared/domain/entities/return_evidence.dart';

/// Backend `ReturnRequestState` 1-5. [cancelled] (5) is a return that ended
/// before the item reached the seller — see [VendorReturnCancelReason] for
/// who ended it (return pickup contract §4, return fixes contract B).
enum VendorReturnRequestState {
  submitted,
  approved,
  rejected,
  completed,
  cancelled,
}

/// Backend `ReturnResolution`: Refund=1, Replacement=2.
enum VendorReturnResolution {
  refund,
  replacement;

  /// Accepts the number the API sends and the enum name; anything else is a
  /// refund, the backend's default.
  static VendorReturnResolution fromWire(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        '2' || 'replacement' => VendorReturnResolution.replacement,
        _ => VendorReturnResolution.refund,
      };
}

/// Why a return was cancelled (`cancelReason`, return pickup contract §5
/// and return fixes contract B).
enum VendorReturnCancelReason {
  /// `buyer_cancelled` — the buyer withdrew it.
  buyer,

  /// `buyer_unavailable` — the rider could not reach the buyer for good.
  buyerUnavailable,

  /// `handover_refused` — the buyer would not hand the item over.
  handoverRefused,

  /// `support` — StyleMint support cancelled it.
  support,

  /// Absent (an older server or row) or a value this app does not know.
  unknown;

  static VendorReturnCancelReason fromWire(Object? value) =>
      switch (value?.toString().trim().toLowerCase()) {
        'buyer_cancelled' || 'buyer' => VendorReturnCancelReason.buyer,
        'buyer_unavailable' => VendorReturnCancelReason.buyerUnavailable,
        'handover_refused' => VendorReturnCancelReason.handoverRefused,
        'support' => VendorReturnCancelReason.support,
        _ => VendorReturnCancelReason.unknown,
      };
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
    this.restocked,
    this.reasonCategory,
    this.pickupFarePayer,
    this.pickupStage,
    this.pickupAware = false,
    this.resolution = VendorReturnResolution.refund,
    this.cancelReason = VendorReturnCancelReason.unknown,
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

  /// Set once the return is completed: true when the item went back in
  /// stock, false when it was recorded as not resellable. Null before that,
  /// or when the server does not send it.
  final bool? restocked;
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

  /// What the buyer asked for: their money back, or the item replaced.
  final VendorReturnResolution resolution;

  /// Why a [VendorReturnRequestState.cancelled] return was cancelled.
  final VendorReturnCancelReason cancelReason;

  bool get isPending => state == VendorReturnRequestState.submitted;
}
