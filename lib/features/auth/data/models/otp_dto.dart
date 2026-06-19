import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_dto.freezed.dart';
part 'otp_dto.g.dart';

/// Request model for OTP login
/// Sent to `/v1/auth/login-otp/request` endpoint
@freezed
abstract class RequestOtpLoginDto with _$RequestOtpLoginDto {
  const factory RequestOtpLoginDto({
    required String identifierType, // "email" or "phone"
    required String identifier, // email address or phone number
  }) = _RequestOtpLoginDto;

  factory RequestOtpLoginDto.fromJson(Map<String, dynamic> json) =>
      _$RequestOtpLoginDtoFromJson(json);
}

/// Response when OTP is successfully requested
/// Returned by `/v1/auth/login-otp/request` endpoint
@freezed
abstract class OtpLoginRequestedDto with _$OtpLoginRequestedDto {
  const factory OtpLoginRequestedDto({
    required String otpId, // UUID of this OTP request
    @JsonKey(name: 'expiresUtc') required DateTime expiresUtc,
    @JsonKey(name: 'devPlaintextCode')
    String? devPlaintextCode, // Only in development environment
    String? accountId, // UUID — present once smart-start resolves the account
    // True when this identifier had no account and one was just provisioned.
    // Drives showing the "Your name" field on the OTP screen. Defaults to
    // false for older responses that omit the field.
    @Default(false) bool isNewAccount,
  }) = _OtpLoginRequestedDto;

  factory OtpLoginRequestedDto.fromJson(Map<String, dynamic> json) =>
      _$OtpLoginRequestedDtoFromJson(json);
}

/// Request model for OTP verification and login
/// Sent to `/v1/auth/login-otp/verify` endpoint
@freezed
abstract class VerifyOtpLoginDto with _$VerifyOtpLoginDto {
  const factory VerifyOtpLoginDto({
    required String identifierType, // "email" or "phone"
    required String identifier, // email address or phone number
    required String code, // 5-digit OTP code from SMS/email
    String? deviceId, // Optional device ID (UUID)
    // Optional, max 64 chars. Supplied when the account was just provisioned
    // (isNewAccount). Sets the account name in this same request — no second
    // round-trip needed.
    String? displayName,
  }) = _VerifyOtpLoginDto;

  factory VerifyOtpLoginDto.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpLoginDtoFromJson(json);
}
