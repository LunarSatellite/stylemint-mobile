import 'package:freezed_annotation/freezed_annotation.dart';

part 'magic_link_dto.freezed.dart';
part 'magic_link_dto.g.dart';

/// Returned by `POST /v1/auth/login-magic/request`.
@freezed
abstract class MagicLoginRequestedDto with _$MagicLoginRequestedDto {
  const factory MagicLoginRequestedDto({
    required String tokenId, // UUID
    @JsonKey(name: 'expiresUtc') required DateTime expiresUtc,
    @JsonKey(name: 'devPlaintextToken')
    String? devPlaintextToken, // Only in development environment
  }) = _MagicLoginRequestedDto;

  factory MagicLoginRequestedDto.fromJson(Map<String, dynamic> json) =>
      _$MagicLoginRequestedDtoFromJson(json);
}
