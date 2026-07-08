import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/data/models/earnings_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings.dart';
import 'package:stylemint_mobile_frontend/features/creator/earnings/domain/entities/earnings_breakdown.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';

class EarningsRemoteDataSource {
  EarningsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<EarningsSummaryDto> getSummary() async {
    final response = await apiClient.get('/v1/earnings/balance');
    return EarningsSummaryDto.fromJson(response as Map<String, dynamic>);
  }

  /// Month-to-date earnings breakdown for the "Earnings Breakdown This
  /// Month" card. Real figures (SM-BG-4) — sales count, average per sale,
  /// distinct reel count, and the single highest-earning reel are all
  /// computed server-side from the ledger, not approximated from the
  /// creator analytics dashboard.
  Future<EarningsBreakdown> getMonthlyBreakdown() async {
    final r = await apiClient.get('/v1/earnings/summary')
        as Map<String, dynamic>;
    final currency = r['currency'] as String? ?? 'NPR';

    return EarningsBreakdown(
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

  /// GET /v1/creator/earnings/payout-methods (creator-scoped alias,
  /// resolves accountId from the JWT — SM-BG-5).
  Future<List<PayoutMethodDto>> getPayoutMethods() async {
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

  /// POST /v1/creator/earnings/payout-methods/bank (SM-BG-5). [kind] must
  /// be nimbBank or laxmiBank.
  Future<PayoutMethodDto> addBankPayoutMethod({
    required PayoutDestinationKind kind,
    required String label,
    required String maskedAccountNumber,
    required String beneficiaryName,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/earnings/payout-methods/bank',
      data: {
        'kind': kind.code,
        'label': label,
        'maskedAccountNumber': maskedAccountNumber,
        'beneficiaryName': beneficiaryName,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return PayoutMethodDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST /v1/creator/earnings/payout-methods/external-wallet (SM-BG-5).
  /// [kind] must be paypal or esewa.
  Future<PayoutMethodDto> addExternalWalletPayoutMethod({
    required PayoutDestinationKind kind,
    required String label,
    required String externalIdentifier,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/creator/earnings/payout-methods/external-wallet',
      data: {
        'kind': kind.code,
        'label': label,
        'externalIdentifier': externalIdentifier,
      },
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': idempotencyKey,
      }),
    );
    return PayoutMethodDto.fromJson(response as Map<String, dynamic>);
  }
}
