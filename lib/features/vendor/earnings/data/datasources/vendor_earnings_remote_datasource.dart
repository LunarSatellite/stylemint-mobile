import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/vendor/earnings/data/models/vendor_earnings_dto.dart';

/// The backend's `PayeeKind.Vendor` wire value — earnings/payouts are a
/// shared ledger between creators (1) and vendors (2).
const _vendorRole = 2;

class VendorEarningsRemoteDataSource {
  VendorEarningsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<VendorEarningsSummaryDto> getEarningsSummary() async {
    final response = await apiClient.get('/v1/vendor/analytics/overview');
    return VendorEarningsSummaryDto.fromJson(
      response as Map<String, dynamic>,
    );
  }

  /// `GET /v1/earnings/balance?role=2` — the true payout-eligible ledger
  /// balance (distinct from the analytics-derived summary above).
  Future<VendorEarningsBalanceDto> getBalance() async {
    final response = await apiClient.get(
      '/v1/earnings/balance',
      queryParameters: {'role': _vendorRole},
    );
    return VendorEarningsBalanceDto.fromJson(response as Map<String, dynamic>);
  }

  /// `GET /v1/earnings/entries?role=2`.
  Future<Map<String, dynamic>> getLedger({
    int pageSize = 20,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/earnings/entries',
      queryParameters: {
        'role': _vendorRole,
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  /// `POST /v1/payouts/on-demand`. `destinationId` is a
  /// `/v1/payout-destinations` id (see `PayoutDestinationsRemoteDataSource`
  /// in `features/payouts` — payout method CRUD is shared with creators,
  /// not a vendor-specific system).
  Future<void> requestPayout({
    required double amount,
    required int destinationKind,
    required String destinationId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/payouts/on-demand',
      data: {
        'role': _vendorRole,
        'destination': destinationKind,
        'destinationRef': destinationId,
        'requestedAmount': amount,
      },
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }
}
