import 'package:freezed_annotation/freezed_annotation.dart';

part 'password_reset_dto.freezed.dart';
part 'password_reset_dto.g.dart';

/// Returned by `POST /v1/auth/password-reset/request`.
@freezed
abstract class PasswordResetRequestedDto with _$PasswordResetRequestedDto {
  const factory PasswordResetRequestedDto({
    @JsonKey(name: 'expiresUtc') DateTime? expiresUtc,
    required bool emailMatched,
    @JsonKey(name: 'devPlaintextToken')
    String? devPlaintextToken, // Only in development environment
  }) = _PasswordResetRequestedDto;

  factory PasswordResetRequestedDto.fromJson(Map<String, dynamic> json) =>
      _$PasswordResetRequestedDtoFromJson(json);
}
