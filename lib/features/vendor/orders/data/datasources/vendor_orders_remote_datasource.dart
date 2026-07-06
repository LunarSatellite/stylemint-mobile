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
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/sub-orders',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
        if (status != null) 'status': status,
      },
    );
    return response as Map<String, dynamic>;
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
  /// TODO(swagger): body field names (carrier/trackingNumber) are guessed —
  /// confirm against the real request schema.
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
  /// read-only projection. Shape isn't in Swagger yet; returned raw so the
  /// repository can parse defensively.
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
  /// TODO(swagger): request/response field names are guessed — confirm
  /// against the real schema once published.
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
  /// TODO(swagger): request/response field names are guessed.
  Future<Map<String, dynamic>> bulkPackingSlips(List<String> orderIds) async {
    final response = await apiClient.post(
      '/v1/vendor/sub-orders/bulk/packing-slips',
      data: {'subOrderIds': orderIds},
      options: Options(headers: {'requiresToken': true}),
    );
    return response as Map<String, dynamic>;
  }

  // TODO(swagger): POST /v1/vendor/orders/{orderId}/return not found in Swagger
  Future<Map<String, dynamic>> handleReturn(
    String orderId,
    String action,
    String idempotencyKey,
  ) async {
    final response = await apiClient.post(
      '/v1/vendor/orders/$orderId/return',
      data: {'action': action},
      options: _idempotent(idempotencyKey),
    );
    return response as Map<String, dynamic>;
  }
}
