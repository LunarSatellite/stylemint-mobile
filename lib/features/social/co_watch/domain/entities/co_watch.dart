enum CoWatchSessionStatus { waiting, live, ended }
enum CoWatchContentType { reel, product }

class CoWatchSession {
  const CoWatchSession({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.hostAvatarUrl,
    required this.contentType,
    required this.contentId,
    required this.contentUrl,
    required this.thumbnailUrl,
    required this.participants,
    required this.status,
    required this.startedAt,
  });

  final String id;
  final String hostId;
  final String hostName;
  final String hostAvatarUrl;
  final CoWatchContentType contentType;
  final String contentId;
  final String contentUrl;
  final String thumbnailUrl;
  final List<CoWatchParticipant> participants;
  final CoWatchSessionStatus status;
  final DateTime startedAt;

  CoWatchSession copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? hostAvatarUrl,
    CoWatchContentType? contentType,
    String? contentId,
    String? contentUrl,
    String? thumbnailUrl,
    List<CoWatchParticipant>? participants,
    CoWatchSessionStatus? status,
    DateTime? startedAt,
  }) {
    return CoWatchSession(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
      contentType: contentType ?? this.contentType,
      contentId: contentId ?? this.contentId,
      contentUrl: contentUrl ?? this.contentUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      participants: participants ?? this.participants,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

class CoWatchParticipant {
  const CoWatchParticipant({
    required this.userId,
    required this.userName,
    required this.userAvatarUrl,
    required this.joinedAt,
  });

  final String userId;
  final String userName;
  final String userAvatarUrl;
  final DateTime joinedAt;

  CoWatchParticipant copyWith({
    String? userId,
    String? userName,
    String? userAvatarUrl,
    DateTime? joinedAt,
  }) {
    return CoWatchParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}

class CoWatchReaction {
  const CoWatchReaction({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.reaction,
    required this.timestamp,
  });

  final String id;
  final String sessionId;
  final String userId;
  final String userName;
  final String reaction;
  final DateTime timestamp;

  CoWatchReaction copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? userName,
    String? reaction,
    DateTime? timestamp,
  }) {
    return CoWatchReaction(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      reaction: reaction ?? this.reaction,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
