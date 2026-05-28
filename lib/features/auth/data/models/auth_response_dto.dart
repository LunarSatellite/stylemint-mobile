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
  }) = _AuthResponseDto;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
}
