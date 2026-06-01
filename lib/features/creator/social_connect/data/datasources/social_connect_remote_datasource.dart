import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/data/models/social_account_dto.dart';

class SocialConnectRemoteDataSource {
  SocialConnectRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  Future<List<SocialAccountDto>> getConnectedAccounts() async {
    final response = await apiClient.get('/v1/social/accounts');

    final data = response as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => SocialAccountDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return items;
  }

  Future<SocialAccountDto> connectPlatform({
    required String platform,
    required String authCode,
    required String redirectUri,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/social/connect/$platform/begin',
      data: {
        'platform': platform,
        'authCode': authCode,
        'redirectUri': redirectUri,
      },
      options: _idempotent(idempotencyKey),
    );

    return SocialAccountDto.fromJson(response as Map<String, dynamic>);
  }

  Future<void> disconnectPlatform(
    String accountId,
    String idempotencyKey,
  ) async {
    await apiClient.authDelete(
      '/v1/social/accounts/$accountId',
      options: _idempotent(idempotencyKey),
    );
  }

  Options _idempotent(String idempotencyKey) => Options(
        headers: {
          'requiresToken': true,
          'Idempotency-Key': idempotencyKey,
        },
      );
}
