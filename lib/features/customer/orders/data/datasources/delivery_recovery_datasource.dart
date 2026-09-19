import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_recovery_offer.dart';

/// Reads and accepts the recovery remedies attached to one delivery
/// (`/v1/deliveries/{trackingNumber}/recovery-offers`).
///
/// Acceptance is a mutation with a real-world effect (a cancellation and
/// refund, or a support ticket), so the caller owns the `Idempotency-Key`
/// and passes the *same* key for every retry of one acceptance attempt —
/// the fallback key minted by `_IdempotencyInterceptor` is per-request and
/// would let a retried tap file two tickets.
abstract class DeliveryRecoveryDataSource {
  Future<List<DeliveryRecoveryOffer>> listOffers(String trackingNumber);

  Future<DeliveryRecoveryOffer> acceptOffer({
    required String trackingNumber,
    required String offerId,
    required bool acknowledgeRefundWindow,
    required String idempotencyKey,
  });
}

class DeliveryRecoveryRemoteDataSource implements DeliveryRecoveryDataSource {
  const DeliveryRecoveryRemoteDataSource({required ApiClient apiClient})
    : _api = apiClient;

  final ApiClient _api;

  @override
  Future<List<DeliveryRecoveryOffer>> listOffers(String trackingNumber) async {
    final response = await _api.get(
      '/v1/deliveries/$trackingNumber/recovery-offers',
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(DeliveryRecoveryOffer.fromJson)
        .toList(growable: false);
  }

  @override
  Future<DeliveryRecoveryOffer> acceptOffer({
    required String trackingNumber,
    required String offerId,
    required bool acknowledgeRefundWindow,
    required String idempotencyKey,
  }) async {
    final response = await _api.post(
      '/v1/deliveries/$trackingNumber/recovery-offers/$offerId/accept',
      data: <String, dynamic>{
        'acknowledgeRefundWindow': acknowledgeRefundWindow,
      },
      options: Options(
        headers: <String, dynamic>{
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return DeliveryRecoveryOffer.fromJson(response as Map<String, dynamic>);
  }
}
