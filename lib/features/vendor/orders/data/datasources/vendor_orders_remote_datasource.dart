import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
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

  // TODO(swagger): GET /v1/vendor/sub-orders/{subOrderId} not found. Use GET /v1/vendor/sub-orders with query filter or GET /v1/vendor/sub-orders/{subOrderId}/packing-slip
  Future<VendorOrderDto> getOrderDetail(String orderId) async {
    final response = await apiClient.get('/v1/vendor/orders/$orderId');
    return VendorOrderDto.fromJson(response as Map<String, dynamic>);
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
