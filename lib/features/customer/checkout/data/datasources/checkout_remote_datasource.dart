import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/data/models/checkout_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';

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
    // CheckoutSessionDto's id field is `id`, not `sessionId` — using the
    // wrong key here meant _sessionId was always null, so placeOrder()
    // silently created and operated on a second, different session every
    // time instead of the one the customer was actually looking at.
    _sessionId = data['id'] as String?;
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

  Future<ShippingAddressDto> addAddress({
    required String label,
    required String receiverName,
    required String receiverPhone,
    required String addressLine1,
    String? landmark,
    required String country,
    required String state,
    required String city,
    required String zipCode,
    bool makeDefault = false,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/addresses',
      data: {
        'label': label,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'addressLine1': addressLine1,
        'landmark': landmark,
        'country': country,
        'state': state,
        'city': city,
        'zipCode': zipCode,
        'makeDefault': makeDefault,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return ShippingAddressDto.fromJson(response as Map<String, dynamic>);
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

  // Backend CheckoutSession.PaymentMethod enum (StyleMint.Modules.CartCheckout
  // .Enums.PaymentMethod) — CardVisaMastercard=1, PayPal=2, Esewa=3,
  // CashOnDelivery=4. Values are locked, never renumbered.
  static int _paymentMethodCode(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.card:
        return 1;
      case PaymentMethodType.paypal:
        return 2;
      case PaymentMethodType.eSewa:
        return 3;
      case PaymentMethodType.cod:
        return 4;
    }
  }

  // Multi-step checkout session flow:
  //   1. Ensure a session exists (create one if _sessionId is null)
  //   2. PATCH address onto the session
  //   3. PATCH payment method onto the session
  //   4. POST place — returns the order number (e.g. "NK2026-00001").
  //      Every downstream order route (detail/invoice/cancel — see
  //      OrdersRemoteDataSource, track_orders_screen.dart) is keyed by this
  //      human-readable order number, not the internal orderId GUID that
  //      also comes back on this response — returning the GUID here caused
  //      the post-purchase "View Order" button to 404 while the exact same
  //      order loaded fine from the Track Order list moments later.
  Future<PlaceOrderResult> placeOrder({
    required String addressId,
    required PaymentMethodType paymentMethod,
    required String idempotencyKey,
  }) async {
    final sessionId = _sessionId ?? await _createSession();

    await apiClient.post(
      '/v1/checkout/sessions/$sessionId/address',
      data: {'addressId': addressId},
      options: Options(headers: {'requiresToken': true}),
    );

    // Backend wants which payment TYPE was chosen (a closed enum), not a
    // saved payment-instrument id — SetCheckoutPaymentMethodVm.PaymentMethod.
    await apiClient.post(
      '/v1/checkout/sessions/$sessionId/payment-method',
      data: {'paymentMethod': _paymentMethodCode(paymentMethod)},
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
    // Cash on Delivery has nothing further for the customer to do — the
    // order is paid-on-fulfillment. PayPal/eSewa/Card come back with
    // paymentRequiresAction=true and a paymentRedirectUrl the customer
    // must complete before the payment is actually captured (the provider's
    // webhook, not this response, is what marks the order paid).
    return PlaceOrderResult(
      orderNumber: data['orderNumber'] as String,
      requiresPaymentAction: data['paymentRequiresAction'] as bool? ?? false,
      paymentRedirectUrl: data['paymentRedirectUrl'] as String?,
    );
  }

  Future<String> _createSession() async {
    final response = await apiClient.post(
      '/v1/checkout/sessions',
      options: Options(headers: {'requiresToken': true}),
    );
    final data = response as Map<String, dynamic>;
    final id = data['id'] as String?;
    if (id == null) throw Exception('Checkout session creation returned no sessionId');
    _sessionId = id;
    return id;
  }
}
