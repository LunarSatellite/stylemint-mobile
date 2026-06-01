import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/friends/domain/entities/friend.dart';

part 'friend_dto.freezed.dart';
part 'friend_dto.g.dart';

@freezed
abstract class FriendDto with _$FriendDto {
  const factory FriendDto({
    required String id,
    required String userId,
    required String displayName,
    required String avatarUrl,
    required String handle,
    @Default(0) int mutualFriends,
    @Default(false) bool isFollowing,
    required DateTime followedAt,
  }) = _FriendDto;

  const FriendDto._();

  factory FriendDto.fromJson(Map<String, dynamic> json) =>
      _$FriendDtoFromJson(json);

  Friend toDomain() => Friend(
    id: id,
    userId: userId,
    displayName: displayName,
    avatarUrl: avatarUrl,
    handle: handle,
    mutualFriends: mutualFriends,
    isFollowing: isFollowing,
    followedAt: followedAt,
  );
}

@freezed
abstract class FriendRequestDto with _$FriendRequestDto {
  const factory FriendRequestDto({
    required String id,
    required String senderId,
    required String senderName,
    required String senderAvatarUrl,
    required String senderHandle,
    @Default(0) int mutualFriends,
    required DateTime createdAt,
    @Default('pending') String status,
  }) = _FriendRequestDto;

  const FriendRequestDto._();

  factory FriendRequestDto.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestDtoFromJson(json);

  FriendRequest toDomain() => FriendRequest(
    id: id,
    senderId: senderId,
    senderName: senderName,
    senderAvatarUrl: senderAvatarUrl,
    senderHandle: senderHandle,
    mutualFriends: mutualFriends,
    createdAt: createdAt,
    status: status,
  );
}
