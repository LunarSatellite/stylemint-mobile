import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_detail_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/order_invoice_dto.dart';
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

  /// GET `/v1/orders/{orderNumber}/invoice` — immutable receipt projection.
  Future<OrderInvoiceDto> getOrderInvoice(String orderNumber) async {
    final response = await apiClient.get('/v1/orders/$orderNumber/invoice');
    return OrderInvoiceDto.fromJson(response as Map<String, dynamic>);
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
  /// Backend `SubmitReturnVm` requires subOrderId/subOrderLineId/quantity/
  /// reason/photoUrls (skill §5 + §13.7) — a bare reason always 400s.
  Future<void> requestReturn(
    String orderId,
    String subOrderId,
    String subOrderLineId,
    int quantity,
    String reason,
    List<String> photoUrls,
    String idempotencyKey,
  ) async {
    await apiClient.post(
      '/v1/orders/$orderId/returns',
      data: {
        'subOrderId': subOrderId,
        'subOrderLineId': subOrderLineId,
        'quantity': quantity,
        'reason': reason,
        'photoUrls': photoUrls,
      },
      options: _idempotent(idempotencyKey),
    );
  }

  /// POST `/v1/orders/returns/images` — multipart upload, returns the CDN
  /// URL to submit via `requestReturn`'s `photoUrls`.
  Future<String> uploadReturnPhoto(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: 'return.jpg'),
    });
    final response = await apiClient.rawPost(
      '/v1/orders/returns/images',
      data: formData,
      options: _authed(),
    );
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String;
  }

  Options _authed() => Options(headers: {'requiresToken': true});

  Options _idempotent(String idempotencyKey) => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': idempotencyKey,
    },
  );
}
