import 'package:freezed_annotation/freezed_annotation.dart';

part 'external_id_dto.freezed.dart';
part 'external_id_dto.g.dart';

@freezed
abstract class ExternalIdDto with _$ExternalIdDto {
  const factory ExternalIdDto({
    required String id,
    required String accountId,
    required String provider,
    @JsonKey(name: 'externalId') String? externalId,
    @JsonKey(name: 'displayName') String? displayName,
    @JsonKey(name: 'linkedUtc') DateTime? linkedUtc,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
    @JsonKey(name: 'updatedUtc') DateTime? updatedUtc,
    String? rowVersion,
  }) = _ExternalIdDto;

  factory ExternalIdDto.fromJson(Map<String, dynamic> json) =>
      _$ExternalIdDtoFromJson(json);
}
