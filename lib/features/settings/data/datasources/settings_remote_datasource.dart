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
    final response = await apiClient.patch(
      '/v1/notifications/preferences',
      data: prefs.toJson(),
    );
    return NotificationPreferencesDto.fromJson(response as Map<String, dynamic>);
  }

  /// TODO(swagger): No settings/language endpoint found — keep as-is.
  Future<String> getCurrentLanguage() async {
    final response = await apiClient.get('/v1/settings/language');
    final data = response as Map<String, dynamic>;
    return data['languageCode'] as String? ?? 'en';
  }

  /// TODO(swagger): No settings/language endpoint found — keep as-is.
  Future<void> setLanguage(String languageCode) async {
    await apiClient.put(
      '/v1/settings/language',
      data: {'languageCode': languageCode},
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
