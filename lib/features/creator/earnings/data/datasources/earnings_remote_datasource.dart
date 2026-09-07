import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/models/earnings_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings_breakdown.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class EarningsRemoteDataSource {
  EarningsRemoteDataSource({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<String> _accountId() async {
    final id = await tokenStorage.accountId;
    if (id == null || id.isEmpty) throw const NetworkExceptions.auth();
    return id;
  }

  Future<EarningsSummaryDto> getSummary() async {
    final response = await apiClient.get('/v1/earnings/balance');
    return EarningsSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  /// Month-to-date earnings summary: total, sales count, avg per sale,
  /// highest reel earnings. Source: GET /v1/earnings/summary.
  Future<MonthlySummary> getMonthlySummary() async {
    final r =
        await apiClient.get('/v1/earnings/summary') as Map<String, dynamic>;
    final currency = r['currency'] as String? ?? 'NPR';
    return MonthlySummary(
      thisMonthEarnings: Money(
        amount: (r['thisMonthEarningsAmount'] as num? ?? 0).toDouble(),
        currency: currency,
      ),
      salesCount: r['thisMonthSalesCount'] as int? ?? 0,
      reelCount: r['thisMonthReelCount'] as int? ?? 0,
      avgPerSale: Money(
        amount: (r['avgEarningsPerSaleAmount'] as num? ?? 0).toDouble(),
        currency: currency,
      ),
      highestReelEarnings: Money(
        amount: (r['highestReelEarningsAmount'] as num? ?? 0).toDouble(),
        currency: currency,
      ),
    );
  }

  /// Derives the per-reel earnings breakdown from the creator analytics
  /// dashboard. Parsed manually because KPI tiles and Money are nested.
  Future<EarningsBreakdown> getDashboardBreakdown() async {
    final r =
        await apiClient.get('/v1/creator/analytics/dashboard')
            as Map<String, dynamic>;
    final salesCount =
        ((r['totalSales'] as Map<String, dynamic>?)?['current'] as num? ?? 0)
            .toInt();
    final totalEarnings =
        (r['totalEarnings'] as Map<String, dynamic>?)?['current']
            as Map<String, dynamic>?;
    final currency = totalEarnings?['currency'] as String? ?? 'NPR';
    final totalEarningsAmount = (totalEarnings?['amount'] as num? ?? 0)
        .toDouble();
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
    final accountId = await _accountId();
    final response = await apiClient.get(
      '/v1/accounts/$accountId/payout-methods',
    );
    return (response as List<dynamic>)
        .map((e) => PayoutMethodDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
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
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }

  Future<PayoutMethodDto> addBankPayoutMethod({
    required int kind,
    required String label,
    required String idempotencyKey,
    String? maskedAccountNumber,
    String? beneficiaryName,
    String? processorReference,
  }) async {
    final accountId = await _accountId();
    final response = await apiClient.post(
      '/v1/accounts/$accountId/payout-methods/bank',
      data: {
        'kind': kind,
        'label': label,
        if (maskedAccountNumber != null)
          'maskedAccountNumber': maskedAccountNumber,
        if (beneficiaryName != null) 'beneficiaryName': beneficiaryName,
        if (processorReference != null)
          'processorReference': processorReference,
      },
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return PayoutMethodDto.fromJson(response as Map<String, dynamic>);
  }

  Future<PayoutMethodDto> addExternalWalletPayoutMethod({
    required int kind,
    required String label,
    required String idempotencyKey,
    String? externalIdentifier,
    String? processorReference,
  }) async {
    final accountId = await _accountId();
    final response = await apiClient.post(
      '/v1/accounts/$accountId/payout-methods/external-wallet',
      data: {
        'kind': kind,
        'label': label,
        if (externalIdentifier != null)
          'externalIdentifier': externalIdentifier,
        if (processorReference != null)
          'processorReference': processorReference,
      },
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return PayoutMethodDto.fromJson(response as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getPayouts({
    int pageSize = 25,
    String? cursor,
  }) async {
    final response = await apiClient.get(
      '/v1/payouts',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<void> removePayoutMethod(String methodId) async {
    final accountId = await _accountId();
    await apiClient.authDelete(
      '/v1/accounts/$accountId/payout-methods/$methodId',
    );
  }

  Future<Map<String, dynamic>> getPayoutInvoice(String payoutId) async {
    final response = await apiClient.get('/v1/payouts/$payoutId/invoice');
    return response as Map<String, dynamic>;
  }

  Future<void> cancelPayout({
    required String payoutId,
    required String idempotencyKey,
  }) async {
    await apiClient.post(
      '/v1/payouts/$payoutId/cancel',
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
  }
}
