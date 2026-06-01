import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/customer/payment/data/models/payment_method_dto.dart';

class PaymentRemoteDataSource {
  PaymentRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<PaymentMethodDto>> getPaymentMethods() async {
    final response = await apiClient.get('/v1/payments/saved-methods');
    final data = response as List<dynamic>;
    return data
        .map((e) => PaymentMethodDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PaymentMethodDto> addCard({
    required String cardNumber,
    required String expiry,
    required String cvv,
    required String cardholderName,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/payments/saved-methods',
      data: {
        'cardNumber': cardNumber,
        'expiry': expiry,
        'cvv': cvv,
        'cardholderName': cardholderName,
      },
      options: _idempotent(idempotencyKey),
    );
    return PaymentMethodDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deletePaymentMethod(String id) async {
    await apiClient.authDelete('/v1/payments/saved-methods/$id');
  }

  Future<void> setDefault(String id, String idempotencyKey) async {
    await apiClient.patch(
      '/v1/payments/saved-methods/$id/default',
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
