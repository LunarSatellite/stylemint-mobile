import 'package:dio/dio.dart';
import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/index.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/role_profile_dto.dart';

/// Remote datasource for authentication API calls.
/// Maps 1:1 onto the Identity module's `/v1/auth` and `/v1/accounts` endpoints.
class AuthRemoteDataSource {
  AuthRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  // Server OtpDestinationType enum: 1 = Email, 2 = Phone.
  static int _otpDestType(String identifierType) =>
      identifierType.toLowerCase() == 'email' ? 1 : 2;

  // ==========================================================================
  // OTP login
  // ==========================================================================

  /// POST `/v1/auth/login-otp/request`
  Future<OtpLoginRequestedDto> requestOtpLogin({
    required String identifierType,
    required String identifier,
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/login-otp/request',
      data: {
        'identifierType': _otpDestType(identifierType),
        'identifier': identifier,
      },
    );
    return OtpLoginRequestedDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/auth/login-otp/verify`
  Future<AuthResponseDto> verifyOtpLogin({
    required String identifierType,
    required String identifier,
    required String code,
    String? deviceId,
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/login-otp/verify',
      data: {
        'identifierType': _otpDestType(identifierType),
        'identifier': identifier,
        'code': code,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
    return AuthResponseDto.fromJson(response as Map<String, dynamic>);
  }

  // ==========================================================================
  // Password login
  // ==========================================================================

  /// POST `/v1/auth/login`
  Future<AuthResponseDto> login({
    required String identifierType,
    required String identifier,
    required String password,
    String? deviceId,
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/login',
      data: {
        'identifierType': _otpDestType(identifierType),
        'identifier': identifier,
        'password': password,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
    return AuthResponseDto.fromJson(response as Map<String, dynamic>);
  }

  // ==========================================================================
  // Magic link login
  // ==========================================================================

  /// POST `/v1/auth/login-magic/request`
  Future<MagicLoginRequestedDto> requestMagicLogin(
      {required String email}) async {
    final response = await apiClient.authPost(
      '/v1/auth/login-magic/request',
      data: {'email': email},
    );
    return MagicLoginRequestedDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/auth/login-magic/consume`
  Future<AuthResponseDto> consumeMagicLogin({
    required String token,
    String? deviceId,
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/login-magic/consume',
      data: {'token': token, if (deviceId != null) 'deviceId': deviceId},
    );
    return AuthResponseDto.fromJson(response as Map<String, dynamic>);
  }

  // ==========================================================================
  // Password reset
  // ==========================================================================

  /// POST `/v1/auth/password-reset/request`
  Future<PasswordResetRequestedDto> requestPasswordReset({
    required String email,
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/password-reset/request',
      data: {'email': email},
    );
    return PasswordResetRequestedDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/auth/password-reset/consume`
  Future<void> consumePasswordReset({
    required String token,
    required String newPassword,
  }) async {
    await apiClient.authPost(
      '/v1/auth/password-reset/consume',
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  // ==========================================================================
  // Token lifecycle
  // ==========================================================================

  /// POST `/v1/auth/refresh`
  Future<AuthResponseDto> refresh({required String refreshToken}) async {
    final response = await apiClient.authPost(
      '/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return AuthResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/auth/logout`
  Future<void> logout({String? refreshToken, bool allSessions = false}) async {
    await apiClient.post(
      '/v1/auth/logout',
      data: {
        if (refreshToken != null) 'refreshToken': refreshToken,
        'allSessions': allSessions,
      },
    );
  }

  /// POST `/v1/auth/session/ping` — keeps the current session marked active.
  Future<void> sessionPing() async {
    await apiClient.post('/v1/auth/session/ping');
  }

  // ==========================================================================
  // OAuth / social login
  // ==========================================================================

  /// POST `/v1/auth/oauth/{provider}/authorize`
  Future<OAuthAuthorizeResultDto> oauthAuthorize({
    required String provider,
    required String redirectUri,
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/oauth/$provider/authorize',
      data: {'redirectUri': redirectUri},
    );
    return OAuthAuthorizeResultDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/auth/oauth/callback`
  Future<OAuthCallbackResultDto> oauthCallback({
    required String code,
    required String state,
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/oauth/callback',
      data: {'code': code, 'state': state},
    );
    return OAuthCallbackResultDto.fromJson(response as Map<String, dynamic>);
  }

  // ==========================================================================
  // Accounts
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}`
  Future<AccountDto> getAccount(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId');
    return AccountDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/accounts` — register new account.
  Future<AccountDto> registerAccount({
    String? displayName,
    String? locale,
    String? timezone,
  }) async {
    final response = await apiClient.authPost(
      '/v1/accounts',
      data: {
        if (displayName != null) 'displayName': displayName,
        if (locale != null) 'locale': locale,
        if (timezone != null) 'timezone': timezone,
      },
    );
    return AccountDto.fromJson(response as Map<String, dynamic>);
  }

  /// PATCH `/v1/accounts/{accountId}` — update profile.
  Future<AccountDto> updateProfile({
    required String accountId,
    String? displayName,
    String? locale,
    String? timezone,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
    String? countryCode,
    String? rowVersion,
  }) async {
    final response = await apiClient.patch(
      '/v1/accounts/$accountId',
      data: {
        if (displayName != null) 'displayName': displayName,
        if (locale != null) 'locale': locale,
        if (timezone != null) 'timezone': timezone,
        if (dateOfBirth != null)
          'dateOfBirth': dateOfBirth
              .toIso8601String()
              .split('T')
              .first,
        if (gender != null) 'gender': gender,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        if (countryCode != null) 'countryCode': countryCode,
        if (rowVersion != null) 'rowVersion': rowVersion,
      },
    );
    return AccountDto.fromJson(response as Map<String, dynamic>);
  }

  // ==========================================================================
  // Sessions
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/sessions`
  Future<List<UserSessionDto>> listSessions(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId/sessions');
    return (response as List)
        .map((e) => UserSessionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/sessions/{sessionId}/revoke`
  Future<void> revokeSession({
    required String accountId,
    required String sessionId,
    String? reason,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/sessions/$sessionId/revoke',
      data: {if (reason != null) 'reason': reason},
    );
  }

  /// POST `/v1/accounts/{accountId}/sessions/revoke-all` — returns count revoked.
  Future<int> revokeAllSessions(String accountId) async {
    final response =
    await apiClient.post('/v1/accounts/$accountId/sessions/revoke-all');
    return response is int ? response : int.tryParse('$response') ?? 0;
  }

  // ==========================================================================
  // Devices
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/devices`
  Future<List<DeviceDto>> listDevices(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId/devices');
    return (response as List)
        .map((e) => DeviceDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/devices`
  Future<DeviceDto> registerDevice({
    required String accountId,
    String? deviceFingerprint,
    String? platform,
    String? model,
    String? osVersion,
    String? appVersion,
    String? nickname,
  }) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/devices',
      data: {
        if (deviceFingerprint != null) 'deviceFingerprint': deviceFingerprint,
        if (platform != null) 'platform': platform,
        if (model != null) 'model': model,
        if (osVersion != null) 'osVersion': osVersion,
        if (appVersion != null) 'appVersion': appVersion,
        if (nickname != null) 'nickname': nickname,
      },
    );
    return DeviceDto.fromJson(response as Map<String, dynamic>);
  }

  // ==========================================================================
  // Passkeys (WebAuthn)
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/passkeys`
  Future<List<PasskeyCredentialDto>> listPasskeys(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId/passkeys');
    return (response as List)
        .map((e) => PasskeyCredentialDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/passkeys/register/options`
  Future<PasskeyChallengeDto> beginPasskeyRegistration({
    required String accountId,
    String? nickname,
  }) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/passkeys/register/options',
      data: {if (nickname != null) 'nickname': nickname},
    );
    return PasskeyChallengeDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/accounts/{accountId}/passkeys/register/complete`
  Future<PasskeyCredentialDto> completePasskeyRegistration({
    required String accountId,
    required String challengeBase64Url,
    required String clientResponseJson,
    String? nickname,
  }) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/passkeys/register/complete',
      data: {
        'challengeBase64Url': challengeBase64Url,
        'clientResponseJson': clientResponseJson,
        if (nickname != null) 'nickname': nickname,
      },
    );
    return PasskeyCredentialDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/accounts/{accountId}/passkeys/authenticate/options`
  Future<PasskeyChallengeDto> beginPasskeyAuthentication(
      String accountId) async {
    final response = await apiClient
        .authPost('/v1/accounts/$accountId/passkeys/authenticate/options');
    return PasskeyChallengeDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/accounts/{accountId}/passkeys/authenticate/complete`
  ///
  /// Returns the raw response body: depending on environment this is either an
  /// [AuthResponseDto] payload or an empty 204. Callers parse as needed.
  Future<Map<String, dynamic>?> completePasskeyAuthentication({
    required String accountId,
    required String challengeBase64Url,
    required String clientResponseJson,
  }) async {
    final response = await apiClient.authPost(
      '/v1/accounts/$accountId/passkeys/authenticate/complete',
      data: {
        'challengeBase64Url': challengeBase64Url,
        'clientResponseJson': clientResponseJson,
      },
    );
    return response is Map<String, dynamic> ? response : null;
  }

  /// DELETE `/v1/accounts/{accountId}/passkeys/{credentialId}`
  Future<void> deletePasskey({
    required String accountId,
    required String credentialId,
  }) async {
    await apiClient.authDelete(
        '/v1/accounts/$accountId/passkeys/$credentialId');
  }

  // ==========================================================================
  // Registration
  // ==========================================================================

  /// POST `/v1/registration/start`
  Future<RegistrationStartResponseDto> startRegistration({
    required String displayName,
    required String locale,
    required String timezone,
    required String email,
    required String phoneE164,
    required String countryDialCode,
  }) async {
    final response = await apiClient.authPost(
      '/v1/registration/start',
      data: {
        'displayName': displayName,
        'locale': locale,
        'timezone': timezone,
        'email': email,
        'phoneE164': phoneE164,
        'countryDialCode': countryDialCode,
      },
    );
    return RegistrationStartResponseDto.fromJson(
        response as Map<String, dynamic>);
  }

  /// POST `/v1/registration/{accountId}/verify-email` → 204
  Future<void> verifyRegistrationEmail(String accountId,
      String email,
      String code,) async {
    await apiClient.authPost(
      '/v1/registration/$accountId/verify-email',
      data: {'email': email, 'code': code},
    );
  }

  /// POST `/v1/registration/{accountId}/verify-phone` → 204
  Future<void> verifyRegistrationPhone(String accountId,
      String phoneE164,
      String code,) async {
    await apiClient.authPost(
      '/v1/registration/$accountId/verify-phone',
      data: {'phoneE164': phoneE164, 'code': code},
    );
  }

  /// POST `/v1/registration/{accountId}/set-password` → 204
  Future<void> setRegistrationPassword(String accountId,
      String password) async {
    await apiClient.authPost(
      '/v1/registration/$accountId/set-password',
      data: {'password': password},
    );
  }

  /// POST `/v1/registration/{accountId}/accept-terms`
  Future<RegistrationCompletionDto> acceptRegistrationTerms(String accountId, {
    required String consentVersion,
    String? ipAddress,
    String? userAgent,
  }) async {
    final response = await apiClient.authPost(
      '/v1/registration/$accountId/accept-terms',
      data: {
        'consentVersion': consentVersion,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
      },
    );
    return RegistrationCompletionDto.fromJson(response as Map<String, dynamic>);
  }

  // ==========================================================================
  // Devices (extended)
  // ==========================================================================

  /// POST `/v1/accounts/{accountId}/devices/{deviceId}/trust`
  Future<void> trustDevice({
    required String accountId,
    required String deviceId,
  }) async {
    await apiClient.post('/v1/accounts/$accountId/devices/$deviceId/trust');
  }

  /// POST `/v1/accounts/{accountId}/devices/{deviceId}/untrust`
  Future<void> untrustDevice({
    required String accountId,
    required String deviceId,
  }) async {
    await apiClient.post('/v1/accounts/$accountId/devices/$deviceId/untrust');
  }

  /// POST `/v1/accounts/{accountId}/devices/{deviceId}/revoke`
  Future<void> revokeDevice({
    required String accountId,
    required String deviceId,
  }) async {
    await apiClient.post('/v1/accounts/$accountId/devices/$deviceId/revoke');
  }

  /// POST `/v1/accounts/{accountId}/devices/{deviceId}/name`
  Future<void> renameDevice({
    required String accountId,
    required String deviceId,
    required String nickname,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/devices/$deviceId/name',
      data: {'nickname': nickname},
    );
  }

  // ==========================================================================
  // MFA / TOTP
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/mfa-methods`
  Future<List<MfaMethodDto>> listMfaMethods(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId/mfa-methods');
    return (response as List)
        .map((e) => MfaMethodDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/mfa-methods/totp`
  Future<TotpEnrollmentDto> beginTotpEnrollment(String accountId) async {
    final response =
    await apiClient.post('/v1/accounts/$accountId/mfa-methods/totp');
    return TotpEnrollmentDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/accounts/{accountId}/mfa-methods/{methodId}/confirm`
  Future<MfaMethodDto> confirmTotp({
    required String accountId,
    required String methodId,
    required String code,
  }) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/mfa-methods/$methodId/confirm',
      data: {'code': code},
    );
    return MfaMethodDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/accounts/{accountId}/mfa-methods/{methodId}/disable`
  Future<void> disableMfa({
    required String accountId,
    required String methodId,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/mfa-methods/$methodId/disable',
    );
  }

  /// POST `/v1/accounts/{accountId}/mfa-methods/{methodId}/primary`
  Future<void> setPrimaryMfa({
    required String accountId,
    required String methodId,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/mfa-methods/$methodId/primary',
    );
  }

  /// POST `/v1/accounts/{accountId}/mfa-methods/{methodId}/label`
  Future<void> renameMfa({
    required String accountId,
    required String methodId,
    required String label,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/mfa-methods/$methodId/label',
      data: {'label': label},
    );
  }

  // ==========================================================================
  // Handles
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/handles`
  Future<List<HandleDto>> listHandles(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId/handles');
    return (response as List)
        .map((e) => HandleDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/handles`
  Future<HandleDto> registerHandle({
    required String accountId,
    required String handle,
  }) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/handles',
      data: {'handle': handle},
    );
    return HandleDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/accounts/{accountId}/handles/{handleId}/activate`
  Future<void> activateHandle({
    required String accountId,
    required String handleId,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/handles/$handleId/activate',
    );
  }

  /// POST `/v1/accounts/{accountId}/handles/{handleId}/deactivate`
  Future<void> deactivateHandle({
    required String accountId,
    required String handleId,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/handles/$handleId/deactivate',
    );
  }

  // ==========================================================================
  // Interests (account-level, API-backed)
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/interests`
  Future<List<InterestDto>> listInterests(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId/interests');
    return (response as List)
        .map((e) => InterestDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET `/v1/public/interests` — available interests for onboarding.
  Future<List<InterestDto>> listPublicInterests() async {
    final response = await apiClient.authGet('/v1/public/interests');
    return (response as List)
        .map((e) => InterestDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/interests`
  Future<void> addInterest({
    required String accountId,
    required String categoryId,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/interests',
      data: {'categoryId': categoryId},
    );
  }

  /// DELETE `/v1/accounts/{accountId}/interests/{categoryId}`
  Future<void> removeInterest({
    required String accountId,
    required String categoryId,
  }) async {
    await apiClient.authDelete(
      '/v1/accounts/$accountId/interests/$categoryId',
    );
  }

  // ==========================================================================
  // Blocked users
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/blocked`
  Future<List<BlockedUserDto>> listBlockedUsers(String accountId) async {
    final response = await apiClient.get('/v1/accounts/$accountId/blocked');
    return (response as List)
        .map((e) => BlockedUserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/blocked`
  Future<BlockedUserDto> blockUser({
    required String accountId,
    required String blockedAccountId,
  }) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/blocked',
      data: {'blockedAccountId': blockedAccountId},
    );
    return BlockedUserDto.fromJson(response as Map<String, dynamic>);
  }

  /// DELETE `/v1/accounts/{accountId}/blocked/{blockedAccountId}`
  Future<void> unblockUser({
    required String accountId,
    required String blockedAccountId,
  }) async {
    await apiClient.authDelete(
      '/v1/accounts/$accountId/blocked/$blockedAccountId',
    );
  }

  // ==========================================================================
  // External IDs (linked social accounts)
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/external-ids`
  Future<List<ExternalIdDto>> listExternalIds(String accountId) async {
    final response =
    await apiClient.get('/v1/accounts/$accountId/external-ids');
    return (response as List)
        .map((e) => ExternalIdDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/external-ids`
  Future<ExternalIdDto> linkExternalId({
    required String accountId,
    required String provider,
    Map<String, dynamic>? additionalData,
  }) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/external-ids',
      data: {
        'provider': provider,
        if (additionalData != null) ...additionalData,
      },
    );
    return ExternalIdDto.fromJson(response as Map<String, dynamic>);
  }

  /// DELETE `/v1/accounts/{accountId}/external-ids/{provider}`
  Future<void> unlinkExternalId({
    required String accountId,
    required String provider,
  }) async {
    await apiClient.authDelete(
      '/v1/accounts/$accountId/external-ids/$provider',
    );
  }

  // ==========================================================================
  // Marketing consents
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/marketing-consents`
  Future<List<MarketingConsentDto>> listMarketingConsents(
      String accountId,) async {
    final response =
    await apiClient.get('/v1/accounts/$accountId/marketing-consents');
    return (response as List)
        .map((e) => MarketingConsentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET `/v1/accounts/{accountId}/marketing-consents/current`
  Future<List<MarketingConsentDto>> getCurrentMarketingConsents(
      String accountId,) async {
    final response =
    await apiClient.get(
      '/v1/accounts/$accountId/marketing-consents/current',
    );
    return (response as List)
        .map((e) => MarketingConsentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/marketing-consents/current/{category}`
  Future<void> toggleMarketingConsent({
    required String accountId,
    required String category,
    required bool consented,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/marketing-consents/current/$category',
      data: {'consented': consented},
    );
  }

  // ==========================================================================
  // Account pause (Quiet Hours / break)
  // ==========================================================================

  /// GET `/v1/auth/pause`
  Future<AccountPauseDto> getPause() async {
    final response = await apiClient.get('/v1/auth/pause');
    return AccountPauseDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/auth/pause`
  Future<void> pause({required int days}) async {
    await apiClient.post('/v1/auth/pause', data: {'days': days});
  }

  /// DELETE `/v1/auth/pause` — resume a paused account.
  Future<void> resume() async {
    await apiClient.authDelete('/v1/auth/pause');
  }

  // ==========================================================================
  // Roles
  // ==========================================================================

  /// GET `/v1/accounts/{accountId}/roles`
  Future<List<RoleProfileDto>> getRoles(String accountId) async {
    final response =
    await apiClient.authGet('/v1/accounts/$accountId/roles');
    return (response as List)
        .map((e) => RoleProfileDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST `/v1/accounts/{accountId}/roles`
  Future<RoleProfileDto> requestRole(String accountId, int role) async {
    final response = await apiClient.authPost(
      '/v1/accounts/$accountId/roles',
      data: {'role': role},
    );
    return RoleProfileDto.fromJson(response as Map<String, dynamic>);
  }

  /// POST `/v1/accounts/{accountId}/roles/{role}/activate`
  Future<void> activateRole(String accountId, int role) async {
    await apiClient.authPost(
      '/v1/accounts/$accountId/roles/$role/activate',
    );
  }

  // ==========================================================================
  // Password management
  // ==========================================================================

  /// POST `/v1/accounts/{accountId}/password/change`
  Future<void> changePassword({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await apiClient.post(
      '/v1/accounts/$accountId/password/change',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// POST `/v1/accounts/{accountId}/password/verify`
  Future<bool> verifyPassword(String accountId, String password) async {
    final response = await apiClient.post(
      '/v1/accounts/$accountId/password/verify',
      data: {'password': password},
    );
    return response is bool ? response : false;
  }

  // ==========================================================================
  // Account deletion
  // ==========================================================================

  /// POST `/v1/accounts/{accountId}/deletion-requests`
  Future<void> deleteAccount({
    required String accountId,
    required String idempotencyKey,
  }) async {
    await apiClient.authPost(
      '/v1/accounts/$accountId/deletion-requests',
      data: {},
      options: Options(headers: {
        'requiresToken': false,
        'Idempotency-Key': idempotencyKey,
      }),
    );
  }
}
