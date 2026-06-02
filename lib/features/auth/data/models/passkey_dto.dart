import 'package:freezed_annotation/freezed_annotation.dart';

part 'passkey_dto.freezed.dart';
part 'passkey_dto.g.dart';

/// WebAuthn challenge returned by passkey register/authenticate `options`
/// endpoints. [optionsJson] is the raw WebAuthn options to hand to the
/// platform authenticator (e.g. via the `local_auth`/passkey plugin).
@freezed
abstract class PasskeyChallengeDto with _$PasskeyChallengeDto {
  const factory PasskeyChallengeDto({
    required String challengeId, // UUID
    required String challengeBase64Url,
    required String optionsJson,
    @JsonKey(name: 'expiresUtc') required DateTime expiresUtc,
  }) = _PasskeyChallengeDto;

  factory PasskeyChallengeDto.fromJson(Map<String, dynamic> json) =>
      _$PasskeyChallengeDtoFromJson(json);
}

/// Returned by `POST /v1/auth/passkeys/register/bootstrap/options` — a bare
/// account is created (display name only) and a WebAuthn registration challenge
/// issued in one round-trip. [accountId] is echoed back so the client can post
/// it to the matching `bootstrap/complete` call.
@freezed
abstract class PasskeyBootstrapDto with _$PasskeyBootstrapDto {
  const factory PasskeyBootstrapDto({
    required String accountId, // UUID
    required String challengeId, // UUID
    required String challengeBase64Url,
    required String optionsJson,
    @JsonKey(name: 'expiresUtc') required DateTime expiresUtc,
  }) = _PasskeyBootstrapDto;

  factory PasskeyBootstrapDto.fromJson(Map<String, dynamic> json) =>
      _$PasskeyBootstrapDtoFromJson(json);
}

/// A registered passkey credential. Returned by the passkey list/register
/// endpoints.
@freezed
abstract class PasskeyCredentialDto with _$PasskeyCredentialDto {
  const factory PasskeyCredentialDto({
    required String id, // UUID
    required String accountId, // UUID
    String? credentialId,
    int? signCount,
    String? aaguid,
    String? nickname,
    @JsonKey(name: 'lastUsedUtc') DateTime? lastUsedUtc,
    @JsonKey(name: 'revokedUtc') DateTime? revokedUtc,
    @JsonKey(name: 'createdUtc') DateTime? createdUtc,
    @JsonKey(name: 'updatedUtc') DateTime? updatedUtc,
    String? rowVersion,
    bool? isActive,
  }) = _PasskeyCredentialDto;

  factory PasskeyCredentialDto.fromJson(Map<String, dynamic> json) =>
      _$PasskeyCredentialDtoFromJson(json);
}
