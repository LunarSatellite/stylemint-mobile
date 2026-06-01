import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/models/checkout_dto.dart';

class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // TODO: No GET /v1/checkout endpoint — create a session first with POST /v1/checkout/sessions
  Future<CheckoutSummaryDto> getCheckoutSummary() async {
    final response = await apiClient.get('/v1/checkout/sessions');
    return CheckoutSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<ShippingAddressDto>> getShippingAddresses() async {
    final response = await apiClient.get('/v1/addresses');
    final data = response as List<dynamic>;
    return data
        .map((e) => ShippingAddressDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<PaymentMethodDto>> getPaymentMethods() async {
    final response = await apiClient.get('/v1/payments/saved-methods');
    final data = response as List<dynamic>;
    return data
        .map((e) => PaymentMethodDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // TODO: Real API requires creating a session (POST /v1/checkout/sessions),
  //       setting address (POST /v1/checkout/sessions/{sessionId}/address),
  //       setting payment (POST /v1/checkout/sessions/{sessionId}/payment-method),
  //       then placing (POST /v1/checkout/sessions/{sessionId}/place).
  Future<String> placeOrder({
    required String addressId,
    required String paymentMethodId,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/checkout/sessions/$addressId/place',
      data: {
        'addressId': addressId,
        'paymentMethodId': paymentMethodId,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    final data = response as Map<String, dynamic>;
    return data['orderId'] as String;
  }
}
