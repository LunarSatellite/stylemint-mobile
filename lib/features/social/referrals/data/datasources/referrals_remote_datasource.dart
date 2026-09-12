import 'package:dio/dio.dart' show Options;
import 'package:uuid/uuid.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';

class ReferralsRemoteDataSource {
  ReferralsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  static const _uuid = Uuid();

  Future<Map<String, dynamic>> listMyLinks({String? cursor, int pageSize = 20}) async {
    final response = await apiClient.get(
      '/v1/invite-links',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createLink({int? redemptionCap}) async {
    final response = await apiClient.post(
      '/v1/invite-links',
      data: {'redemptionCap': redemptionCap},
      options: _idempotent(),
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listRedemptions(
    String linkId, {
    String? cursor,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/v1/invite-links/$linkId/redemptions',
      queryParameters: {
        'pageSize': pageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<void> redeem(String code) async {
    await apiClient.post(
      '/v1/invite-redemptions',
      data: {'code': code},
      options: _idempotent(),
    );
  }

  Options _idempotent() => Options(
    headers: {
      'requiresToken': true,
      'Idempotency-Key': _uuid.v4(),
    },
  );
}
