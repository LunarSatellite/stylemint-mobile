import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/wallet/data/models/wallet_balance_dto.dart';
import 'package:stylemint_mobile_frontend/features/wallet/data/models/wallet_transaction_dto.dart';
import 'package:uuid/uuid.dart';

class WalletRemoteDataSource {
  WalletRemoteDataSource({
    required this.apiClient,
    required this.tokenStorage,
  });

  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  static const _uuid = Uuid();

  Future<String> _accountId() async {
    final id = await tokenStorage.accountId;
    // ignore: only_throw_errors
    if (id == null || id.isEmpty) throw const NetworkExceptions.auth();
    return id;
  }

  Future<WalletBalanceDto> getBalance() async {
    final accountId = await _accountId();
    final response = await apiClient.get(
      '/v1/accounts/$accountId/wallet/NPR',
      options: Options(headers: {
        'requiresToken': true,
        'Idempotency-Key': _uuid.v4(),
      }),
    );
    return WalletBalanceDto.fromJson(response as Map<String, dynamic>);
  }

  Future<List<WalletTransactionDto>> getTransactions(
    String accountId,
    String walletId, {
    int take = 20,
    DateTime? untilUtc,
  }) async {
    final response = await apiClient.get(
      '/v1/accounts/$accountId/wallets/$walletId/transactions',
      queryParameters: <String, dynamic>{
        'take': take,
        if (untilUtc != null) 'untilUtc': untilUtc.toUtc().toIso8601String(),
      },
    );
    return (response as List<dynamic>)
        .map((e) => WalletTransactionDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
