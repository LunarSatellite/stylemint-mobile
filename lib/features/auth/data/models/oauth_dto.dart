import 'package:freezed_annotation/freezed_annotation.dart';

part 'oauth_dto.freezed.dart';
part 'oauth_dto.g.dart';

/// Returned by `POST /v1/auth/oauth/{provider}/authorize`. The app opens
/// [authorizationUrl] in a browser/custom tab and round-trips [state] back
/// through the callback.
@freezed
abstract class OAuthAuthorizeResultDto with _$OAuthAuthorizeResultDto {
  const factory OAuthAuthorizeResultDto({
    String? authorizationUrl,
    String? state,
  }) = _OAuthAuthorizeResultDto;

  factory OAuthAuthorizeResultDto.fromJson(Map<String, dynamic> json) =>
      _$OAuthAuthorizeResultDtoFromJson(json);
}

/// Returned by `POST /v1/auth/oauth/callback`. [provider] arrives as its
/// string name.
@freezed
abstract class OAuthCallbackResultDto with _$OAuthCallbackResultDto {
  const factory OAuthCallbackResultDto({
    String? provider,
    String? providerUserId,
    String? email,
    bool? emailVerified,
    String? displayName,
    String? avatarUrl,
    bool? isNewExternalLink,
  }) = _OAuthCallbackResultDto;

  factory OAuthCallbackResultDto.fromJson(Map<String, dynamic> json) =>
      _$OAuthCallbackResultDtoFromJson(json);
}
