import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/tracked_order_dto.dart';

/// Remote datasource for customer orders. Throws on failure; the repository
/// maps exceptions to [Failure].
class OrdersRemoteDataSource {
  OrdersRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// GET `/v1/orders` — the customer's orders (most recent first).
  Future<List<TrackedOrderDto>> getTrackedOrders({
    required int limit,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/orders',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final data = response as Map<String, dynamic>;
    return (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => TrackedOrderDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// GET `/v1/orders/{orderNumber}` — full order detail.
  Future<OrderDetailDto> getOrderDetail(String orderId) async {
    final response = await apiClient.get('/v1/orders/$orderId');
    return OrderDetailDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/orders/{orderNumber}/cancel` — cancel an order.
  /// [reason] is the backend OrderCancellationReason int; [note] is required
  /// when reason == Other. The 5-7 day refund acknowledgement is mandatory.
  Future<void> cancelOrder(
    String orderId,
    String idempotencyKey, {
    required int reason,
    String? note,
  }) async {
    await apiClient.post(
      '/v1/orders/$orderId/cancel',
      data: <String, dynamic>{
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
        'acknowledgedFiveToSevenDayRefund': true,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST `/v1/orders/{orderNumber}/returns` — request a return.
  Future<void> requestReturn(
    String orderId,
    String reason,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/orders/$orderId/returns',
      data: {'reason': reason},
      options: _idempotent(idempotencyKey),
    );
  }

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
