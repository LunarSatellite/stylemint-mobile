import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_dto.freezed.dart';
part 'account_dto.g.dart';

/// Account DTO from `/v1/accounts` endpoints
/// Represents a user account in the Style Mint platform
@freezed
abstract class AccountDto with _$AccountDto {
  const factory AccountDto({
    required String id, // UUID
    String? displayName,
    String? locale,
    String? timezone,
    String? status,
    @JsonKey(name: 'dateOfBirth') DateTime? dateOfBirth,
    String? gender,
    String? avatarUrl,
    String? countryCode,
    @JsonKey(name: 'emailVerifiedUtc') DateTime? emailVerifiedUtc,
    @JsonKey(name: 'phoneVerifiedUtc') DateTime? phoneVerifiedUtc,
    @JsonKey(name: 'lastActiveUtc') DateTime? lastActiveUtc,
    @JsonKey(name: 'createdUtc') required DateTime createdUtc,
    @JsonKey(name: 'updatedUtc') required DateTime updatedUtc,
    @JsonKey(name: 'createdById') required String createdById,
    @JsonKey(name: 'updatedById') String? updatedById,
    String? rowVersion,
  }) = _AccountDto;

  factory AccountDto.fromJson(Map<String, dynamic> json) =>
      _$AccountDtoFromJson(json);
}
