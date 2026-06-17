import 'package:dio/dio.dart' show Options;
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/data/models/social_account_dto.dart';

class SocialConnectRemoteDataSource {
  SocialConnectRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/social/accounts` → bare JSON array of SocialAccountDto.
  Future<List<SocialAccountDto>> getConnectedAccounts() async {
    final response = await apiClient.get('/v1/social/accounts');
    final list = (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => SocialAccountDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    return list;
  }

  /// OAuth leg 1 — `POST /v1/social/connect/{providerSlug}/begin` returns the
  /// provider authorize URL + state (`SocialAuthorizeUrlDto { url, state }`).
  ///
  /// `redirectUri` is intentionally omitted so the backend uses its own
  /// server-side callback (`GET .../callback`) — the provider must redirect to
  /// the backend, not the app, so the server can exchange the code.
  Future<({String url, String state})> beginConnect({
    required String providerSlug,
    required String idempotencyKey,
  }) async {
    final response = await apiClient.post(
      '/v1/social/connect/$providerSlug/begin',
      data: const <String, dynamic>{},
      options: _idempotent(idempotencyKey),
    );

    final data = response as Map<String, dynamic>;
    return (
      url: data['url'] as String? ?? '',
      state: data['state'] as String? ?? '',
    );
  }

  /// `DELETE /v1/social/accounts/{providerSlug}` — disconnect a linked account.
  Future<void> disconnectPlatform(
    String providerSlug,
    String idempotencyKey,
  ) async {
    await apiClient.authDelete(
      '/v1/social/accounts/$providerSlug',
      data: const <String, dynamic>{},
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
