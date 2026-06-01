import 'package:freezed_annotation/freezed_annotation.dart';

part 'mfa_method_dto.freezed.dart';
part 'mfa_method_dto.g.dart';

@freezed
abstract class MfaMethodDto with _$MfaMethodDto {
  const factory MfaMethodDto({
    required String id,
    required String accountId,
    @JsonKey(name: 'methodType') required int methodType,
    String? label,
    @JsonKey(name: 'isPrimary') bool? isPrimary,
    @JsonKey(name: 'confirmedUtc') DateTime? confirmedUtc,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
    @JsonKey(name: 'updatedUtc') DateTime? updatedUtc,
    String? rowVersion,
  }) = _MfaMethodDto;

  factory MfaMethodDto.fromJson(Map<String, dynamic> json) =>
      _$MfaMethodDtoFromJson(json);
}
