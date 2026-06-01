import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/following_user.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/entities/user_profile.dart';

part 'user_profile_dto.freezed.dart';
part 'user_profile_dto.g.dart';

@freezed
abstract class UserProfileDto with _$UserProfileDto {
  const factory UserProfileDto({
    required String id,
    required String displayName,
    required String email,
    required String phone,
    @Default('') String avatarUrl,
    @Default('') String bio,
    @Default('') String website,
    String? gender,
    DateTime? dateOfBirth,
    required DateTime dateJoined,
    @Default('en') String language,
  }) = _UserProfileDto;

  const UserProfileDto._();

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  UserProfile toDomain() => UserProfile(
    id: id,
    displayName: displayName,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    bio: bio,
    website: website,
    gender: gender,
    dateOfBirth: dateOfBirth,
    language: language,
    dateJoined: dateJoined,
  );
}

@freezed
abstract class FollowingUserDto with _$FollowingUserDto {
  const factory FollowingUserDto({
    required String id,
    required String displayName,
    @Default('') String avatarUrl,
    @Default('') String handle,
    @Default(false) bool isFollowing,
    @Default(0) int followerCount,
  }) = _FollowingUserDto;

  const FollowingUserDto._();

  factory FollowingUserDto.fromJson(Map<String, dynamic> json) =>
      _$FollowingUserDtoFromJson(json);

  FollowingUser toDomain() => FollowingUser(
    id: id,
    displayName: displayName,
    avatarUrl: avatarUrl,
    handle: handle,
    isFollowing: isFollowing,
    followerCount: followerCount,
  );
}
