import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/models/vendor_order_dto.dart';

class VendorOrdersRemoteDataSource {
  VendorOrdersRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );

  Future<Map<String, dynamic>> getOrders({
    required int limit,
    String? cursor,
    String? status,
    DateTime? placedFromUtc,
    DateTime? placedToUtc,
    String? productVariantId,
    double? minSubtotal,
    double? maxSubtotal,
    String? carrier,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders',
      queryParameters: {
        'pageSize': limit,
        if (cursor != null) 'cursor': cursor,
        if (status != null) 'state': status,
        if (placedFromUtc != null)
          'placedFromUtc': placedFromUtc.toUtc().toIso8601String(),
        if (placedToUtc != null)
          'placedToUtc': placedToUtc.toUtc().toIso8601String(),
        if (productVariantId != null) 'productVariantId': productVariantId,
        if (minSubtotal != null) 'minSubtotal': minSubtotal,
        if (maxSubtotal != null) 'maxSubtotal': maxSubtotal,
        if (carrier != null) 'carrier': carrier,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// `totalCount` for a single `SubOrderState` — used for dashboard tile
  /// counts. Filters server-side via the (correctly-named) `state` int
  /// query param; `pageSize: 1` keeps the payload minimal since only the
  /// count is read.
  Future<int> getSubOrderCount(int state) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders',
      queryParameters: {'state': state, 'pageSize': 1},
    );
    return (response as Map<String, dynamic>)['totalCount'] as int? ?? 0;
  }

  /// GET /v1/vendor/sub-orders/{subOrderId} — vendor sub-order detail
  /// (SM-BG-2). `orderId` here is the sub-order id (the list row's `id`).
  /// Requires backend PR #53 deployed.
  Future<VendorOrderDetailDto> getOrderDetail(String orderId) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders/$orderId',
      options: Options(headers: {'requiresToken': true}),
    );
    return VendorOrderDetailDto.fromJson(response as Map<String, dynamic>);
  }

  Future<VendorOrderDto> updateOrderStatus(
    String orderId,
    String newStatus,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/$newStatus',
      options: _idempotent(idempotencyKey),
    );
    return VendorOrderDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/vendor/sub-orders/{subOrderId}/ready-to-ship — Vendor §3B
  /// single-id variant. "Mark as Shipped" in the UI maps to this transition.
  Future<VendorOrderDto> markReadyToShip(
    String orderId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/ready-to-ship',
      options: _idempotent(idempotencyKey),
    );
    return VendorOrderDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/vendor/sub-orders/{subOrderId}/tracking — "Assign Tracking No."
  /// The backend SetTrackingVm contract requires `carrier` and
  /// `trackingNumber` (maximum lengths 100 and 200 respectively).
  Future<VendorOrderDto> addTracking(
    String orderId,
    String carrier,
    String trackingNumber,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/tracking',
      data: {'carrier': carrier, 'trackingNumber': trackingNumber},
      options: _idempotent(idempotencyKey),
    );
    return VendorOrderDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/vendor/sub-orders/{subOrderId}/delivered
  Future<VendorOrderDto> markDelivered(
    String orderId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/$orderId/delivered',
      options: _idempotent(idempotencyKey),
    );
    return VendorOrderDto.fromJson(response as Map<String, dynamic>);
  }

  /// GET /v1/vendor/sub-orders/{subOrderId}/packing-slip — Vendor §3D,
  /// read-only PackingSlipDto projection. Returned raw so the repository can
  /// translate the backend DTO into the presentation entity.
  Future<Map<String, dynamic>> getPackingSlip(String orderId) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders/$orderId/packing-slip',
      options: Options(headers: {'requiresToken': true}),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/sub-orders/bulk/ready-to-ship — Vendor §3B "Mark
  /// Multiple as Shipped". Outer 200 with a per-row BulkResult even if some
  /// ids fail individually.
  /// The backend BulkSubOrderIdsVm request field is `subOrderIds`.
  Future<Map<String, dynamic>> bulkReadyToShip(
    List<String> orderIds,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/bulk/ready-to-ship',
      data: {'subOrderIds': orderIds},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/sub-orders/bulk/packing-slips — Vendor §3C "Print All
  /// Packing Slips". Pure read; no state change.
  /// The backend BulkSubOrderIdsVm request field is `subOrderIds`.
  Future<Map<String, dynamic>> bulkPackingSlips(List<String> orderIds) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/bulk/packing-slips',
      data: {'subOrderIds': orderIds},
      options: Options(headers: {'requiresToken': true}),
    );
    return response as Map<String, dynamic>;
  }

  /// GET /v1/vendor/returns — Vendor §8.1 paged list of return requests
  /// awaiting (or past) the vendor's accept/reject decision.
  Future<Map<String, dynamic>> listReturns({
    int? state,
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/returns',
      queryParameters: {
        'pageSize': pageSize,
        if (state != null) 'state': state,
        if (cursor != null) 'cursor': cursor,
      },
      options: Options(headers: {'requiresToken': true}),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/returns/{id}/accept — Submitted -> Approved.
  Future<Map<String, dynamic>> acceptReturn(
    String returnRequestId,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/returns/$returnRequestId/accept',
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }

  /// POST /v1/vendor/returns/{id}/reject — Submitted -> Rejected (terminal).
  Future<Map<String, dynamic>> rejectReturn(
    String returnRequestId,
    String reason,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/returns/$returnRequestId/reject',
      data: {'reason': reason},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }
}
