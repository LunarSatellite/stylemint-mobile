import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_session_dto.freezed.dart';
part 'user_session_dto.g.dart';

/// An active or historical login session. Returned by
/// `GET /v1/accounts/{accountId}/sessions`.
///
/// Enum fields ([status], [revocationReason]) arrive as their string names
/// from the API's string enum serializer.
@freezed
abstract class UserSessionDto with _$UserSessionDto {
  const factory UserSessionDto({
    required String id, // UUID
    required String accountId, // UUID
    String? deviceId, // UUID
    @JsonKey(name: 'issuedUtc') DateTime? issuedUtc,
    @JsonKey(name: 'expiresUtc') DateTime? expiresUtc,
    @JsonKey(name: 'lastActivityUtc') DateTime? lastActivityUtc,
    String? ipAddress,
    String? userAgent,
    String? status,
    @JsonKey(name: 'revokedUtc') DateTime? revokedUtc,
    String? revocationReason,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
    @JsonKey(name: 'updatedUtc') DateTime? updatedUtc,
    String? rowVersion,
  }) = _UserSessionDto;

  factory UserSessionDto.fromJson(Map<String, dynamic> json) =>
      _$UserSessionDtoFromJson(json);
}
