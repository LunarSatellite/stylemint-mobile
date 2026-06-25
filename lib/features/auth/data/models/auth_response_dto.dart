import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_response_dto.freezed.dart';
part 'auth_response_dto.g.dart';

/// Authentication response DTO from login endpoints
/// Returned by `/v1/auth/login-otp/verify`, `/v1/auth/login`, etc.
/// Contains access + refresh tokens for authenticated requests
@freezed
abstract class AuthResponseDto with _$AuthResponseDto {
  const factory AuthResponseDto({
    required String accountId, // UUID
    required String sessionId, // UUID
    String? accessToken, // JWT Bearer token
    @JsonKey(name: 'accessExpiresUtc') required DateTime accessExpiresUtc,
    String? refreshToken, // Refresh JWT
    @JsonKey(name: 'refreshExpiresUtc') required DateTime refreshExpiresUtc,
    String? tokenType, // "Bearer"
    // True when this auth bundle just provisioned the account (first-ever
    // OTP login with an unknown identifier, passkey bootstrap, or first-time
    // social sign-in). Drives whether the post-signup onboarding screens are
    // shown. Absent on refresh and older responses → defaults to false.
    @Default(false) bool isNewAccount,
    // True once the user has set/confirmed their display name. When false we
    // prompt for a name after sign-in (e.g. magic-link). Absent on refresh and
    // older responses → defaults to true so existing flows don't re-prompt.
    @Default(true) bool displayNameConfirmed,
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
}
