import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

/// `POST /v1/customer/deliveries/confirm` (delivery-complete contract).
///
/// Throws the raw [DioException]; the repository reads the `errorCode` out of
/// it, because the generic mapper turns every 403 into "sign in again" and
/// this endpoint's 403 means "this parcel is not yours".
class DeliveryConfirmationRemoteDataSource {
  DeliveryConfirmationRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// Body is `{ qrPayload }` or `{ packageNumber, code }`.
  Future<Map<String, dynamic>> confirm({
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/customer/deliveries/confirm',
      data: body,
      options: Options(
        headers: {'requiresToken': true, 'Idempotency-Key': idempotencyKey},
      ),
    );
    return response is Map
        ? response.cast<String, dynamic>()
        : const <String, dynamic>{};
  }
}
