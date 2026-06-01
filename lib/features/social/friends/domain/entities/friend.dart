class Friend {
  const Friend({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.handle,
    required this.mutualFriends,
    required this.isFollowing,
    required this.followedAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String avatarUrl;
  final String handle;
  final int mutualFriends;
  final bool isFollowing;
  final DateTime followedAt;

  Friend copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? avatarUrl,
    String? handle,
    int? mutualFriends,
    bool? isFollowing,
    DateTime? followedAt,
  }) {
    return Friend(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      handle: handle ?? this.handle,
      mutualFriends: mutualFriends ?? this.mutualFriends,
      isFollowing: isFollowing ?? this.isFollowing,
      followedAt: followedAt ?? this.followedAt,
    );
  }
}

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatarUrl,
    required this.senderHandle,
    required this.mutualFriends,
    required this.createdAt,
    required this.status,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatarUrl;
  final String senderHandle;
  final int mutualFriends;
  final DateTime createdAt;
  final String status; // pending, accepted, declined

  FriendRequest copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? senderHandle,
    int? mutualFriends,
    DateTime? createdAt,
    String? status,
  }) {
    return FriendRequest(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      senderHandle: senderHandle ?? this.senderHandle,
      mutualFriends: mutualFriends ?? this.mutualFriends,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }
}
