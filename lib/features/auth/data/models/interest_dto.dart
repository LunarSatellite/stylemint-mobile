import 'package:freezed_annotation/freezed_annotation.dart';

part 'interest_dto.freezed.dart';
part 'interest_dto.g.dart';

@freezed
abstract class InterestDto with _$InterestDto {
  const factory InterestDto({
    required String categoryId,
    required String name,
    String? icon,
    String? description,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
  }) = _InterestDto;

  factory InterestDto.fromJson(Map<String, dynamic> json) =>
      _$InterestDtoFromJson(json);
}
