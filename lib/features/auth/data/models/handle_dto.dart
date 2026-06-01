import 'package:freezed_annotation/freezed_annotation.dart';

part 'handle_dto.freezed.dart';
part 'handle_dto.g.dart';

@freezed
abstract class HandleDto with _$HandleDto {
  const factory HandleDto({
    required String id,
    required String accountId,
    required String handle,
    @JsonKey(name: 'isActive') bool? isActive,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
    @JsonKey(name: 'updatedUtc') DateTime? updatedUtc,
    String? rowVersion,
  }) = _HandleDto;

  factory HandleDto.fromJson(Map<String, dynamic> json) =>
      _$HandleDtoFromJson(json);
}
