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
    required String code, // 6-digit OTP code from SMS/email
    String? deviceId, // Optional device ID (UUID)
  }) = _VerifyOtpLoginDto;

  factory VerifyOtpLoginDto.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpLoginDtoFromJson(json);
}
