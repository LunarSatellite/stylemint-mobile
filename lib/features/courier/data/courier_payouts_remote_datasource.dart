import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

/// The rider's payout surface — rider-payout contract v1 §3, base
/// `/v1/courier/payouts`. Destinations reuse `/v1/payout-destinations` with
/// `role=3` and live in the shared payouts feature.
///
/// Every endpoint here 404s until the payout ledger is deployed; screens
/// read that as "being set up", never as "nothing".
class CourierPayoutsRemoteDataSource {
  CourierPayoutsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _base = '/v1/courier/payouts';

  /// GET `/v1/courier/payouts/balance` — `CourierBalanceDto`.
  Future<Map<String, dynamic>> getBalance() async {
    final response = await apiClient.get(
      '$_base/balance',
      options: _auth(),
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// GET `/v1/courier/payouts/earnings` — one row per completed leg.
  Future<Map<String, dynamic>> listEarnings({
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '$_base/earnings',
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'pageSize': pageSize,
      },
      options: _auth(),
    );
    return _page(response);
  }

  /// GET `/v1/courier/payouts` — the rider's payouts, newest first.
  Future<Map<String, dynamic>> listPayouts({
    String? cursor,
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      _base,
      queryParameters: {
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'pageSize': pageSize,
      },
      options: _auth(),
    );
    return _page(response);
  }

  /// POST `/v1/courier/payouts/request` — `amount` null pays the whole net
  /// payable.
  Future<Map<String, dynamic>> requestPayout({
    required String destinationId,
    double? amount,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.authPost(
      '$_base/request',
      data: {
        'destinationId': destinationId,
        if (amount != null) 'amount': amount,
      },
      options: _idempotent(idempotencyKey),
    );
    return (response as Map).cast<String, dynamic>();
  }

  /// POST `/v1/courier/payouts/{id}/cancel` — only while Requested. 204.
  Future<void> cancelPayout({
    required String payoutId,
    required String idempotencyKey,
  }) async {
    await apiClient.authPost(
      '$_base/${Uri.encodeComponent(payoutId)}/cancel',
      options: _idempotent(idempotencyKey),
    );
  }

  Options _auth() => Options(headers: {'requiresToken': true});

  Options _idempotent(String key) => Options(
    headers: {'requiresToken': true, 'Idempotency-Key': key},
  );

  /// `PagedResult<T>`; a bare list is read as one page too.
  static Map<String, dynamic> _page(dynamic response) {
    if (response is Map) return response.cast<String, dynamic>();
    if (response is List) return {'items': response, 'hasMore': false};
    return const {'items': <dynamic>[]};
  }
}
