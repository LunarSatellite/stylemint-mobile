import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/settings/data/models/notification_prefs_dto.dart';

class SettingsRemoteDataSource {
  SettingsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

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
  Future<void> deleteAccount(String accountId, String idempotencyKey) async {
    await apiClient.authPost(
      '/v1/accounts/$accountId/deletion-requests',
      data: {},
      options: Options(headers: {
        'requiresToken': false,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }

  Future<void> logout() async {
    await apiClient.post('/v1/auth/logout');
  }
}
