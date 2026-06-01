import 'package:freezed_annotation/freezed_annotation.dart';

part 'marketing_consent_dto.freezed.dart';
part 'marketing_consent_dto.g.dart';

@freezed
abstract class MarketingConsentDto with _$MarketingConsentDto {
  const factory MarketingConsentDto({
    required String category,
    required bool consented,
    @JsonKey(name: 'updatedUtc') DateTime? updatedUtc,
  }) = _MarketingConsentDto;

  factory MarketingConsentDto.fromJson(Map<String, dynamic> json) =>
      _$MarketingConsentDtoFromJson(json);
}
