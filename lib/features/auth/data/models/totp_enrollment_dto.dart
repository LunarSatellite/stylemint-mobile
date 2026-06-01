import 'package:freezed_annotation/freezed_annotation.dart';

part 'totp_enrollment_dto.freezed.dart';
part 'totp_enrollment_dto.g.dart';

@freezed
abstract class TotpEnrollmentDto with _$TotpEnrollmentDto {
  const factory TotpEnrollmentDto({
    required String secret,
    required String qrCodeUrl,
    required String uri,
    String? methodId,
  }) = _TotpEnrollmentDto;

  factory TotpEnrollmentDto.fromJson(Map<String, dynamic> json) =>
      _$TotpEnrollmentDtoFromJson(json);
}
