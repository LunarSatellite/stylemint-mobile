import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/models/deletion_request_dto.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/models/notification_prefs_dto.dart';

class SettingsRemoteDataSource {
  SettingsRemoteDataSource({required this.apiClient, required this.tokenStorage});

  final ApiClient apiClient;
  final TokenStorage tokenStorage;

  Future<String> _accountId() async {
    final id = await tokenStorage.accountId;
    if (id == null || id.isEmpty) throw Exception('No accountId in storage');
    return id;
  }

  Future<NotificationPreferencesDto> getNotificationPreferences() async {
    final response = await apiClient.get('/v1/notifications/preferences');
    return NotificationPreferencesDto.fromJson(response as Map<String, dynamic>);
  }

  Future<NotificationPreferencesDto> updateNotificationPreferences(
    NotificationPreferencesDto prefs,
  ) async {
    final response = await apiClient.put(
      '/v1/notifications/preferences/all',
      data: prefs.toJson(),
    );
    return NotificationPreferencesDto.fromJson(response as Map<String, dynamic>);
  }

  // No dedicated language endpoint exists — locale lives on the account
  // record (`GET/PATCH /v1/accounts/{id}`), the same one profile edits use.
  Future<String> getCurrentLanguage() async {
    final accountId = await _accountId();
    final response = await apiClient.get('/v1/accounts/$accountId');
    final data = response as Map<String, dynamic>;
    return data['locale'] as String? ?? 'en-US';
  }

  /// PATCH `/v1/accounts/{accountId}` requires `displayName`, so the current
  /// profile is fetched first to carry it (and `rowVersion`) forward unchanged.
  Future<void> setLanguage(String languageCode) async {
    final accountId = await _accountId();
    final current =
        await apiClient.get('/v1/accounts/$accountId') as Map<String, dynamic>;
    await apiClient.patch(
      '/v1/accounts/$accountId',
      data: {
        'displayName': current['displayName'],
        'rowVersion': current['rowVersion'],
        'locale': languageCode,
      },
    );
  }

  /// POST `/v1/accounts/{accountId}/deletion-requests`
  Future<void> deleteAccount(String idempotencyKey, String reason) async {
    final accountId = await _accountId();
    await apiClient.authPost(
      '/v1/accounts/$accountId/deletion-requests',
      data: <String, dynamic>{'reason': reason},
      options: Options(headers: {
        'requiresToken': false,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  /// GET `/v1/accounts/{accountId}/deletion-requests/pending`
  /// Returns null if there is no pending request (404).
  Future<DeletionRequestDto?> getPendingDeletion() async {
    final accountId = await _accountId();
    try {
      final response = await apiClient.get(
        '/v1/accounts/$accountId/deletion-requests/pending',
      );
      if (response == null) return null; // 204 No Content — no pending request
      return DeletionRequestDto.fromJson(response as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST `/v1/accounts/{accountId}/deletion-requests/{requestId}/cancel`
  Future<void> cancelDeletion(String requestId) async {
    final accountId = await _accountId();
    await apiClient.post(
      '/v1/accounts/$accountId/deletion-requests/$requestId/cancel',
    );
  }

  Future<void> logout() async {
    await apiClient.post('/v1/auth/logout');
  }
}
