import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/models/earnings_dto.dart';

class EarningsRemoteDataSource {
  EarningsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<EarningsSummaryDto> getSummary() async {
    final response = await apiClient.get('/v1/earnings/balance');
    return EarningsSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getLedger({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/earnings/entries',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<List<PayoutMethodDto>> getPayoutMethods() async {
    // TODO(swagger): needs accountId path param; Swagger: GET /v1/accounts/{accountId}/payout-methods
    final response = await apiClient.get('/v1/creator/earnings/payout-methods');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => PayoutMethodDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<void> requestPayout({
    required double amount,
    required String currency,
    required String payoutMethodId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/payouts/on-demand',
      data: {
        'amount': amount,
        'currency': currency,
        'payoutMethodId': payoutMethodId,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<PayoutMethodDto> addPayoutMethod({
    required String type,
    required String label,
    required Map<String, String> details,
    required String idempotencyKey,
  }) async {
    // TODO(swagger): needs accountId path param; Swagger: POST /v1/accounts/{accountId}/payout-methods/bank
    final response = await apiClient.post(
      '/v1/creator/earnings/payout-methods',
      data: {
        'type': type,
        'label': label,
        'details': details,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return PayoutMethodDto.fromJson(response as Map<String, dynamic>);
  }
}
