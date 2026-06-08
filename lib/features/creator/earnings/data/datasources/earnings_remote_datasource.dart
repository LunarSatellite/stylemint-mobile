import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/models/earnings_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings_breakdown.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class EarningsRemoteDataSource {
  EarningsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<EarningsSummaryDto> getSummary() async {
    final response = await apiClient.get('/v1/earnings/balance');
    return EarningsSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  /// Derives the per-reel earnings breakdown from the creator analytics
  /// dashboard. Parsed manually — the payload nests generic KPI tiles
  /// (`{current, previous, deltaPercent}`) and Money (`{amount, currency}`),
  /// which don't map cleanly to a flat freezed DTO.
  Future<EarningsBreakdown> getDashboardBreakdown() async {
    final r = await apiClient.get('/v1/creator/analytics/dashboard')
        as Map<String, dynamic>;

    final salesCount =
        ((r['totalSales'] as Map<String, dynamic>?)?['current'] as num? ?? 0)
            .toInt();

    final totalEarnings =
        (r['totalEarnings'] as Map<String, dynamic>?)?['current']
            as Map<String, dynamic>?;
    final currency = totalEarnings?['currency'] as String? ?? 'NPR';
    final totalEarningsAmount =
        (totalEarnings?['amount'] as num? ?? 0).toDouble();

    final reels = (r['topReels'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    var highest = 0.0;
    for (final reel in reels) {
      final amount = (reel['earnings'] as Map<String, dynamic>?)?['amount'];
      if (amount is num && amount.toDouble() > highest) {
        highest = amount.toDouble();
      }
    }

    return EarningsBreakdown(
      salesCount: salesCount,
      reelCount: reels.length,
      avgPerSale: Money(
        amount: salesCount > 0 ? totalEarningsAmount / salesCount : 0,
        currency: currency,
      ),
      highestReelEarnings: Money(amount: highest, currency: currency),
    );
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
