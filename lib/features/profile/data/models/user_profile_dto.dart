import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/user_profile.dart';

part 'user_profile_dto.freezed.dart';
part 'user_profile_dto.g.dart';

/// DTO for the account entity from `GET /v1/accounts/{accountId}`.
/// `primaryEmail` and `primaryPhone` are returned by the API and mapped here.
@freezed
abstract class UserProfileDto with _$UserProfileDto {
  const factory UserProfileDto({
    required String id,
    required String displayName,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    String? primaryEmail,
    String? primaryPhone,
    @Default('en-US') String locale,
    String? timezone,
    String? countryCode,
    DateTime? createdUtc,
    @Default('') String rowVersion,
    @Default('') String bio,
  }) = _UserProfileDto;

  const UserProfileDto._();

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  UserProfile toDomain() => UserProfile(
    id: id,
    displayName: displayName,
    email: primaryEmail ?? '',
    phone: primaryPhone ?? '',
    avatarUrl: avatarUrl ?? '',
    bio: bio,
    gender: gender,
    dateOfBirth: dateOfBirth,
    language: locale,
    dateJoined: createdUtc ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    rowVersion: rowVersion,
  );
}

/// Maps `GET /v1/follows/me`'s real response shape — backend
/// `FollowingListItemDto` (StyleMint.Modules.SocialGraph). Field is
/// `accountId`, not `id`; there is no `handle`/`category`/`bio` on the
/// wire (AccountSummaryDto doesn't carry a handle yet).
@freezed
abstract class FollowingUserDto with _$FollowingUserDto {
  const factory FollowingUserDto({
    required String accountId,
    @Default('') String displayName,
    @Default('') String avatarUrl,
    @Default(true) bool isFollowing,
    @Default(0) int followerCount,
  }) = _FollowingUserDto;

  const FollowingUserDto._();

  factory FollowingUserDto.fromJson(Map<String, dynamic> json) =>
      _$FollowingUserDtoFromJson(json);

  FollowingUser toDomain() => FollowingUser(
    id: accountId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    handle: '',
    isFollowing: isFollowing,
    followerCount: followerCount,
  );
}
