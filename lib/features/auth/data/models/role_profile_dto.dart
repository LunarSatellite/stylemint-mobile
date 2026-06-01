import 'package:freezed_annotation/freezed_annotation.dart';

part 'role_profile_dto.freezed.dart';
part 'role_profile_dto.g.dart';

@freezed
abstract class RoleProfileDto with _$RoleProfileDto {
  const factory RoleProfileDto({
    required String id,
    required String accountId,
    required int role,
    required int status,
    @JsonKey(name: 'activatedUtc') DateTime? activatedUtc,
    String? rowVersion,
  }) = _RoleProfileDto;

  const RoleProfileDto._();

  factory RoleProfileDto.fromJson(Map<String, dynamic> json) =>
      _$RoleProfileDtoFromJson(json);

  bool get isActivated => status >= 2;
}
