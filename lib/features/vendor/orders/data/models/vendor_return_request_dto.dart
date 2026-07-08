import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_return_request.dart';

/// Wire shape for `GET /v1/vendor/returns` rows and the accept/reject
/// response body (both return `ReturnRequestDto`/`VendorReturnRequestListItemDto`
/// shaped payloads from the backend's `ReturnRequestState` enum, 1-4).
class VendorReturnRequestDto {
  const VendorReturnRequestDto({
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

  factory VendorReturnRequestDto.fromJson(Map<String, dynamic> json) =>
      VendorReturnRequestDto(
        id: json['id'] as String,
        orderId: json['orderId'] as String,
        orderNumber: json['orderNumber'] as String? ?? '',
        subOrderId: json['subOrderId'] as String,
        subOrderLineId: json['subOrderLineId'] as String,
        productTitleSnapshot: json['productTitleSnapshot'] as String? ?? '',
        variantLabelSnapshot: json['variantLabelSnapshot'] as String?,
        thumbnailUrlSnapshot: json['thumbnailUrlSnapshot'] as String?,
        quantity: json['quantity'] as int? ?? 0,
        reason: json['reason'] as String? ?? '',
        state: _stateFromCode(json['state'] as int? ?? 1),
        submittedUtc: DateTime.parse(json['submittedUtc'] as String),
        resolvedUtc: json['resolvedUtc'] != null
            ? DateTime.parse(json['resolvedUtc'] as String)
            : null,
        rejectionNote: json['rejectionNote'] as String?,
      );

  final String id;
  final String orderId;
  final String orderNumber;
  final String subOrderId;
  final String subOrderLineId;
  final String? variantLabelSnapshot;
  final String? thumbnailUrlSnapshot;
  final String productTitleSnapshot;
  final int quantity;
  final String reason;
  final VendorReturnRequestState state;
  final DateTime submittedUtc;
  final DateTime? resolvedUtc;
  final String? rejectionNote;

  /// Backend `ReturnRequestState`: Submitted=1, Approved=2, Rejected=3, Completed=4.
  static VendorReturnRequestState _stateFromCode(int code) => switch (code) {
    2 => VendorReturnRequestState.approved,
    3 => VendorReturnRequestState.rejected,
    4 => VendorReturnRequestState.completed,
    _ => VendorReturnRequestState.submitted,
  };

  VendorReturnRequest toDomain() => VendorReturnRequest(
    id: id,
    orderId: orderId,
    orderNumber: orderNumber,
    subOrderId: subOrderId,
    subOrderLineId: subOrderLineId,
    productTitleSnapshot: productTitleSnapshot,
    variantLabelSnapshot: variantLabelSnapshot,
    thumbnailUrlSnapshot: thumbnailUrlSnapshot,
    quantity: quantity,
    reason: reason,
    state: state,
    submittedUtc: submittedUtc,
    resolvedUtc: resolvedUtc,
    rejectionNote: rejectionNote,
  );
}
