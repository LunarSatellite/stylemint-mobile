import 'package:freezed_annotation/freezed_annotation.dart';

part 'registration_dto.freezed.dart';
part 'registration_dto.g.dart';

@freezed
abstract class RegistrationStartResponseDto with _$RegistrationStartResponseDto {
  const factory RegistrationStartResponseDto({
    required String accountId,
    required String emailId,
    required String phoneId,
    @JsonKey(name: 'emailOtpExpiresUtc') required DateTime emailOtpExpiresUtc,
    @JsonKey(name: 'phoneOtpExpiresUtc') required DateTime phoneOtpExpiresUtc,
    @JsonKey(name: 'emailOtpCode') String? emailOtpCode,
    @JsonKey(name: 'phoneOtpCode') String? phoneOtpCode,
    @Default(false) bool resumed,
  }) = _RegistrationStartResponseDto;

  factory RegistrationStartResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RegistrationStartResponseDtoFromJson(json);
}

@freezed
abstract class RegistrationCompletionDto with _$RegistrationCompletionDto {
  const factory RegistrationCompletionDto({
    required String accountId,
    required bool emailVerified,
    required bool phoneVerified,
    required bool hasPassword,
    required bool termsAccepted,
    required bool isComplete,
    @JsonKey(name: 'termsConsentVersion') required String termsConsentVersion,
  }) = _RegistrationCompletionDto;

  factory RegistrationCompletionDto.fromJson(Map<String, dynamic> json) =>
      _$RegistrationCompletionDtoFromJson(json);
}
