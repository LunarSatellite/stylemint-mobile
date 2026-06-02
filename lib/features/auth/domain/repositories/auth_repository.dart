import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/index.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/role_profile_dto.dart';

/// Domain repository interface for authentication.
/// Implementations persist the session tokens on every successful auth result.
abstract interface class AuthRepository {
  // --- OTP login ---
  Future<Either<NetworkExceptions, OtpLoginRequestedDto>> requestOtpLogin({
    required String identifierType,
    required String identifier,
  });

  Future<Either<NetworkExceptions, AuthResponseDto>> verifyOtpLogin({
    required String identifierType,
    required String identifier,
    required String code,
    String? deviceId,
  });

  // --- Password login ---
  Future<Either<NetworkExceptions, AuthResponseDto>> login({
    required String identifierType,
    required String identifier,
    required String password,
    String? deviceId,
  });

  // --- Magic link login ---
  Future<Either<NetworkExceptions, MagicLoginRequestedDto>> requestMagicLogin({
    required String email,
  });

  Future<Either<NetworkExceptions, AuthResponseDto>> consumeMagicLogin({
    required String token,
    String? deviceId,
  });

  // --- Password reset ---
  Future<Either<NetworkExceptions, PasswordResetRequestedDto>> requestPasswordReset({
    required String email,
  });

  Future<Either<NetworkExceptions, Unit>> consumePasswordReset({
    required String token,
    required String newPassword,
  });

  // --- Token lifecycle ---
  Future<Either<NetworkExceptions, AuthResponseDto>> refresh({required String refreshToken});

  Future<Either<NetworkExceptions, Unit>> logout({bool allSessions});

  Future<Either<NetworkExceptions, Unit>> sessionPing();

  // --- OAuth / social ---
  Future<Either<NetworkExceptions, OAuthAuthorizeResultDto>> oauthAuthorize({
    required String provider,
    required String redirectUri,
  });

  Future<Either<NetworkExceptions, OAuthCallbackResultDto>> oauthCallback({
    required String code,
    required String state,
  });

  // --- Accounts ---
  Future<Either<NetworkExceptions, AccountDto>> getAccount(String accountId);

  Future<Either<NetworkExceptions, AccountDto>> registerAccount({
    String? displayName,
    String? locale,
    String? timezone,
  });

  Future<Either<NetworkExceptions, AccountDto>> updateProfile({
    required String accountId,
    String? displayName,
    String? locale,
    String? timezone,
    DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
    String? countryCode,
    String? rowVersion,
  });

  // --- Sessions ---
  Future<Either<NetworkExceptions, List<UserSessionDto>>> listSessions(String accountId);

  Future<Either<NetworkExceptions, Unit>> revokeSession({
    required String accountId,
    required String sessionId,
    String? reason,
  });

  Future<Either<NetworkExceptions, int>> revokeAllSessions(String accountId);

  // --- Devices ---
  Future<Either<NetworkExceptions, List<DeviceDto>>> listDevices(String accountId);

  Future<Either<NetworkExceptions, DeviceDto>> registerDevice({
    required String accountId,
    String? deviceFingerprint,
    String? platform,
    String? model,
    String? osVersion,
    String? appVersion,
    String? nickname,
  });

  // --- Passkeys ---
  Future<Either<NetworkExceptions, List<PasskeyCredentialDto>>> listPasskeys(String accountId);

  Future<Either<NetworkExceptions, PasskeyChallengeDto>> beginPasskeyRegistration({
    required String accountId,
    String? nickname,
  });

  Future<Either<NetworkExceptions, PasskeyCredentialDto>> completePasskeyRegistration({
    required String accountId,
    required String challengeBase64Url,
    required String clientResponseJson,
    String? nickname,
  });

  Future<Either<NetworkExceptions, PasskeyChallengeDto>> beginPasskeyAuthentication(
    String accountId,
  );

  Future<Either<NetworkExceptions, AuthResponseDto>> completePasskeyAuthentication({
    required String accountId,
    required String challengeBase64Url,
    required String clientResponseJson,
  });

  Future<Either<NetworkExceptions, Unit>> deletePasskey({
    required String accountId,
    required String credentialId,
  });

  // --- Usernameless passkey login (discoverable credential, no accountId) ---
  Future<Either<NetworkExceptions, PasskeyChallengeDto>>
      beginUsernamelessPasskeyAuthentication();

  Future<Either<NetworkExceptions, AuthResponseDto>>
      completeUsernamelessPasskeyAuthentication({
    required String challengeBase64Url,
    required String clientResponseJson,
    required String deviceFingerprint,
    required int devicePlatform,
    String? deviceOsVersion,
  });

  // --- Passkey-first signup (bootstrap: bare account + passkey + session) ---
  Future<Either<NetworkExceptions, PasskeyBootstrapDto>> beginPasskeyBootstrap({
    required String displayName,
    String locale,
    String timezone,
  });

  Future<Either<NetworkExceptions, AuthResponseDto>> completePasskeyBootstrap({
    required String accountId,
    required String challengeBase64Url,
    required String clientResponseJson,
    required String deviceFingerprint,
    required int devicePlatform,
    String? deviceOsVersion,
    String? nickname,
  });

  // --- Registration ---
  Future<Either<NetworkExceptions, RegistrationStartResponseDto>> startRegistration({
    required String displayName,
    required String locale,
    required String timezone,
    required String email,
    required String phoneE164,
    required String countryDialCode,
  });

  Future<Either<NetworkExceptions, Unit>> verifyRegistrationEmail(
    String accountId,
    String email,
    String code,
  );

  Future<Either<NetworkExceptions, Unit>> verifyRegistrationPhone(
    String accountId,
    String phoneE164,
    String code,
  );

  Future<Either<NetworkExceptions, Unit>> setRegistrationPassword(
    String accountId,
    String password,
  );

  Future<Either<NetworkExceptions, RegistrationCompletionDto>> acceptRegistrationTerms(
    String accountId, {
    required String consentVersion,
    String? ipAddress,
    String? userAgent,
  });

  // --- Devices (extended) ---
  Future<Either<NetworkExceptions, Unit>> trustDevice({
    required String accountId,
    required String deviceId,
  });

  Future<Either<NetworkExceptions, Unit>> untrustDevice({
    required String accountId,
    required String deviceId,
  });

  Future<Either<NetworkExceptions, Unit>> revokeDevice({
    required String accountId,
    required String deviceId,
  });

  Future<Either<NetworkExceptions, Unit>> renameDevice({
    required String accountId,
    required String deviceId,
    required String nickname,
  });

  // --- MFA / TOTP ---
  Future<Either<NetworkExceptions, List<MfaMethodDto>>> listMfaMethods(String accountId);

  Future<Either<NetworkExceptions, TotpEnrollmentDto>> beginTotpEnrollment(
    String accountId,
  );

  Future<Either<NetworkExceptions, MfaMethodDto>> confirmTotp({
    required String accountId,
    required String methodId,
    required String code,
  });

  Future<Either<NetworkExceptions, Unit>> disableMfa({
    required String accountId,
    required String methodId,
  });

  Future<Either<NetworkExceptions, Unit>> setPrimaryMfa({
    required String accountId,
    required String methodId,
  });

  Future<Either<NetworkExceptions, Unit>> renameMfa({
    required String accountId,
    required String methodId,
    required String label,
  });

  // --- Handles ---
  Future<Either<NetworkExceptions, List<HandleDto>>> listHandles(String accountId);

  Future<Either<NetworkExceptions, HandleDto>> registerHandle({
    required String accountId,
    required String handle,
  });

  Future<Either<NetworkExceptions, Unit>> activateHandle({
    required String accountId,
    required String handleId,
  });

  Future<Either<NetworkExceptions, Unit>> deactivateHandle({
    required String accountId,
    required String handleId,
  });

  // --- Interests (account-level) ---
  Future<Either<NetworkExceptions, List<InterestDto>>> listInterests(String accountId);

  Future<Either<NetworkExceptions, List<InterestDto>>> listPublicInterests();

  Future<Either<NetworkExceptions, Unit>> addInterest({
    required String accountId,
    required String categoryId,
  });

  Future<Either<NetworkExceptions, Unit>> removeInterest({
    required String accountId,
    required String categoryId,
  });

  // --- Blocked users ---
  Future<Either<NetworkExceptions, List<BlockedUserDto>>> listBlockedUsers(
    String accountId,
  );

  Future<Either<NetworkExceptions, BlockedUserDto>> blockUser({
    required String accountId,
    required String blockedAccountId,
  });

  Future<Either<NetworkExceptions, Unit>> unblockUser({
    required String accountId,
    required String blockedAccountId,
  });

  // --- External IDs ---
  Future<Either<NetworkExceptions, List<ExternalIdDto>>> listExternalIds(
    String accountId,
  );

  Future<Either<NetworkExceptions, ExternalIdDto>> linkExternalId({
    required String accountId,
    required String provider,
    Map<String, dynamic>? additionalData,
  });

  Future<Either<NetworkExceptions, Unit>> unlinkExternalId({
    required String accountId,
    required String provider,
  });

  // --- Marketing consents ---
  Future<Either<NetworkExceptions, List<MarketingConsentDto>>> listMarketingConsents(
    String accountId,
  );

  Future<Either<NetworkExceptions, List<MarketingConsentDto>>> getCurrentMarketingConsents(
    String accountId,
  );

  Future<Either<NetworkExceptions, Unit>> toggleMarketingConsent({
    required String accountId,
    required String category,
    required bool consented,
  });

  // --- Account pause ---
  Future<Either<NetworkExceptions, AccountPauseDto>> getPause();

  Future<Either<NetworkExceptions, Unit>> pause({required int days});

  Future<Either<NetworkExceptions, Unit>> resume();

  // --- Roles ---
  Future<Either<NetworkExceptions, List<RoleProfileDto>>> getRoles(String accountId);

  Future<Either<NetworkExceptions, RoleProfileDto>> requestRole(
    String accountId,
    int role,
  );

  Future<Either<NetworkExceptions, Unit>> activateRole(String accountId, int role);

  // --- Password management ---
  Future<Either<NetworkExceptions, Unit>> changePassword({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  });

  Future<Either<NetworkExceptions, bool>> verifyPassword(
    String accountId,
    String password,
  );

  // --- Account deletion ---
  Future<Either<NetworkExceptions, Unit>> deleteAccount(
    String accountId,
    String idempotencyKey,
  );
}
