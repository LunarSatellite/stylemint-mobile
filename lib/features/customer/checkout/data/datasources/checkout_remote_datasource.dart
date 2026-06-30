import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/models/checkout_dto.dart';

class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // Stores the session ID created by getCheckoutSummary for reuse in placeOrder.
  String? _sessionId;

  // POST /v1/checkout/sessions — creates (or resumes) a checkout session from
  // the current cart. The response carries the same shape as the old GET, plus
  // a `sessionId` field needed for subsequent session-scoped calls.
  Future<CheckoutSummaryDto> getCheckoutSummary() async {
    final response = await apiClient.post(
      '/v1/checkout/sessions',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as Map<String, dynamic>;
    _sessionId = data['sessionId'] as String?;
    return CheckoutSummaryDto.fromJson(data);
  }

  Future<List<ShippingAddressDto>> getShippingAddresses() async {
    final response = await apiClient.get(
      '/v1/addresses',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as List<dynamic>;
    return data
        .map((e) => ShippingAddressDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<PaymentMethodDto>> getPaymentMethods() async {
    final response = await apiClient.get(
      '/v1/payments/saved-methods',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as List<dynamic>;
    return data
        .map((e) => PaymentMethodDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  // Multi-step checkout session flow:
  //   1. Ensure a session exists (create one if _sessionId is null)
  //   2. PATCH address onto the session
  //   3. PATCH payment method onto the session
  //   4. POST place — returns orderId
  Future<String> placeOrder({
    required String addressId,
    required String paymentMethodId,
    required String idempotencyKey,
  }) async {
    final sessionId = _sessionId ?? await _createSession();

    await apiClient.post(
      '/v1/checkout/sessions/$sessionId/address',
      data: {'addressId': addressId},
      options: Options(headers: {'requiresToken': true}),
    );

    await apiClient.post(
      '/v1/checkout/sessions/$sessionId/payment-method',
      data: {'paymentMethodId': paymentMethodId},
      options: Options(headers: {'requiresToken': true}),
    );

    final response = await apiClient.post(
      '/v1/checkout/sessions/$sessionId/place',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );

    _sessionId = null; // clear after successful placement
    final data = response as Map<String, dynamic>;
    return data['orderId'] as String;
  }

  Future<String> _createSession() async {
    final response = await apiClient.post(
      '/v1/checkout/sessions',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as Map<String, dynamic>;
    final id = data['sessionId'] as String?;
    if (id == null) throw Exception('Checkout session creation returned no sessionId');
    _sessionId = id;
    return id;
  }
}
