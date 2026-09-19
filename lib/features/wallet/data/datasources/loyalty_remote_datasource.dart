import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/wallet/domain/entities/loyalty_wallet.dart';
import 'package:uuid/uuid.dart';

class LoyaltyRemoteDataSource {
  LoyaltyRemoteDataSource(this.apiClient);
  final ApiClient apiClient;

  Future<LoyaltyWallet> getWallet() async {
    final response = await apiClient.get(
      '/v1/customer/loyalty',
      queryParameters: const {'historySize': 30},
    );
    return LoyaltyWallet.fromJson(response as Map<String, dynamic>);
  }

  Future<LoyaltyRedemption> redeem(int points) async {
    final response = await apiClient.post(
      '/v1/customer/loyalty/redemptions',
      data: {'points': points},
      options: Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': const Uuid().v4(),
        },
      ),
    );
    return LoyaltyRedemption.fromJson(response as Map<String, dynamic>);
  }
}
