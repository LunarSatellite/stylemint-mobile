import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

part 'social_account_dto.freezed.dart';
part 'social_account_dto.g.dart';

/// Matches the backend `SocialAccountDto`. `provider` is the SocialProvider
/// integer enum (1 Instagram, 2 TikTok, 3 YouTube, 4 Facebook); `state` is the
/// SocialAccountState enum (1 Connecting, 2 Active, 3 Expired, 4 Revoked,
/// 5 RateLimited).
@freezed
abstract class SocialAccountDto with _$SocialAccountDto {
  const factory SocialAccountDto({
    required String id,
    required int provider,
    @Default(2) int state,
    String? providerUserId,
    String? handle,
    String? displayName,
    String? avatarUrl,
    int? followerCount,
    DateTime? lastSyncedUtc,
  }) = _SocialAccountDto;

  const SocialAccountDto._();

  factory SocialAccountDto.fromJson(Map<String, dynamic> json) =>
      _$SocialAccountDtoFromJson(json);

  SocialAccount toDomain() {
    // SocialProvider ints (1..4) map to the SocialPlatform enum order.
    final platformEnum = (provider >= 1 && provider <= SocialPlatform.values.length)
        ? SocialPlatform.values[provider - 1]
        : SocialPlatform.instagram;

    return SocialAccount(
      id: id,
      platform: platformEnum,
      handle: handle ?? '',
      username: providerUserId ?? handle ?? '',
      displayName: displayName ?? '',
      avatarUrl: avatarUrl ?? '',
      followerCount: followerCount ?? 0,
      // SocialAccountState.Active == 2.
      isConnected: state == 2,
      connectedAt: lastSyncedUtc,
    );
  }
}
