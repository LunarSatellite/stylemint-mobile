import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/auth/data/models/index.dart';

/// Remote datasource for authentication API calls
/// Handles communication with backend authentication endpoints
class AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSource({required this.apiClient});

  /// Request OTP for phone/email login
  /// POST `/v1/auth/login-otp/request`
  ///
  /// Returns [OtpLoginRequestedDto] with otpId and expiration time
  /// In development, [OtpLoginRequestedDto.devPlaintextCode] contains the OTP code
  Future<OtpLoginRequestedDto> requestOtpLogin({
    required String identifierType, // "phone" or "email"
    required String identifier, // phone number or email
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/login-otp/request',
      data: {
        'identifierType': identifierType,
        'identifier': identifier,
      },
    );
    return OtpLoginRequestedDto.fromJson(response as Map<String, dynamic>);
  }

  /// Verify OTP code and login
  /// POST `/v1/auth/login-otp/verify`
  ///
  /// Returns [AuthResponseDto] with access/refresh tokens
  Future<AuthResponseDto> verifyOtpLogin({
    required String identifierType, // "phone" or "email"
    required String identifier, // phone number or email
    required String code, // 6-digit OTP code
    String? deviceId, // optional device ID
  }) async {
    final response = await apiClient.authPost(
      '/v1/auth/login-otp/verify',
      data: {
        'identifierType': identifierType,
        'identifier': identifier,
        'code': code,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
    return AuthResponseDto.fromJson(response as Map<String, dynamic>);
  }

  /// Get current account details
  /// GET `/v1/accounts/{accountId}`
  ///
  /// Returns [AccountDto] with full account information
  Future<AccountDto> getAccount(String accountId) async {
    final response = await apiClient.authGet('/v1/accounts/$accountId');
    return AccountDto.fromJson(response as Map<String, dynamic>);
  }

  /// Register new account
  /// POST `/v1/accounts`
  ///
  /// Returns [AccountDto] with newly created account details
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
}
