import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/data/models/vendor_earnings_dto.dart';

class VendorEarningsRemoteDataSource {
  VendorEarningsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<VendorEarningsSummaryDto> getEarningsSummary() async {
    final response = await apiClient.get('/v1/vendor/analytics/overview');
    return VendorEarningsSummaryDto.fromJson(
      response as Map<String, dynamic>,
    );
  }

  // TODO(swagger): GET /v1/vendor/earnings/ledger not found. Use GET /v1/vendor/analytics/products or GET /v1/payouts
  Future<Map<String, dynamic>> getLedger({
    int limit = 20,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/vendor/earnings/ledger',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  // TODO(swagger): GET /v1/vendor/payout-methods not found. Use GET /v1/accounts/{accountId}/payout-methods
  Future<List<VendorPayoutMethodDto>> getPayoutMethods() async {
    final response = await apiClient.get('/v1/vendor/payout-methods');
    final items = (response['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => VendorPayoutMethodDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  // TODO(swagger): POST /v1/vendor/payout-methods not found. Use POST /v1/accounts/{accountId}/payout-methods/bank or /external-wallet
  Future<VendorPayoutMethodDto> addPayoutMethod({
    required String type,
    required String label,
    required String accountInfo,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/vendor/payout-methods',
      data: {
        'type': type,
        'label': label,
        'accountInfo': accountInfo,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return VendorPayoutMethodDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> requestPayout({
    required double amount,
    required String currency,
    required String methodId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/payouts/on-demand',
      data: {
        'amount': amount,
        'currency': currency,
        'payoutMethodId': methodId,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }
}
