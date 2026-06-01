import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

part 'social_account_dto.freezed.dart';
part 'social_account_dto.g.dart';

@freezed
abstract class SocialAccountDto with _$SocialAccountDto {
  const factory SocialAccountDto({
    required String id,
    required String platform,
    required String handle,
    required String username,
    required String displayName,
    required String avatarUrl,
    @Default(0) int followerCount,
    @Default(true) bool isConnected,
    String? accessToken,
    DateTime? connectedAt,
  }) = _SocialAccountDto;

  const SocialAccountDto._();

  factory SocialAccountDto.fromJson(Map<String, dynamic> json) =>
      _$SocialAccountDtoFromJson(json);

  SocialAccount toDomain() {
    final platformEnum = SocialPlatform.values.firstWhere(
      (p) => p.name == platform,
      orElse: () => SocialPlatform.instagram,
    );

    return SocialAccount(
      id: id,
      platform: platformEnum,
      handle: handle,
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      followerCount: followerCount,
      isConnected: isConnected,
      accessToken: accessToken,
      connectedAt: connectedAt,
    );
  }
}
