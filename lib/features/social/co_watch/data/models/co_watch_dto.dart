import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/social/co_watch/domain/entities/co_watch.dart';

part 'co_watch_dto.freezed.dart';
part 'co_watch_dto.g.dart';

@freezed
abstract class CoWatchParticipantDto with _$CoWatchParticipantDto {
  const factory CoWatchParticipantDto({
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required DateTime joinedAt,
  }) = _CoWatchParticipantDto;

  const CoWatchParticipantDto._();

  factory CoWatchParticipantDto.fromJson(Map<String, dynamic> json) =>
      _$CoWatchParticipantDtoFromJson(json);

  CoWatchParticipant toDomain() => CoWatchParticipant(
    userId: userId,
    userName: userName,
    userAvatarUrl: userAvatarUrl,
    joinedAt: joinedAt,
  );
}

@freezed
abstract class CoWatchSessionDto with _$CoWatchSessionDto {
  const factory CoWatchSessionDto({
    required String id,
    required String hostId,
    required String hostName,
    required String hostAvatarUrl,
    required String contentType,
    required String contentId,
    required String contentUrl,
    required String thumbnailUrl,
    @Default(<CoWatchParticipantDto>[])
    List<CoWatchParticipantDto> participants,
    required String status,
    required DateTime startedAt,
  }) = _CoWatchSessionDto;

  const CoWatchSessionDto._();

  factory CoWatchSessionDto.fromJson(Map<String, dynamic> json) =>
      _$CoWatchSessionDtoFromJson(json);

  factory CoWatchSessionDto.fromSessionJson(Map<String, dynamic> json) {
    final hostId = (json['hostId'] ?? json['hostAccountId']).toString();
    final guestId = json['guestAccountId']?.toString();
    final createdAt = DateTime.parse(
      (json['startedAt'] ?? json['createdUtc']).toString(),
    );
    final joinedAt = json['joinedUtc'] == null
        ? createdAt
        : DateTime.parse(json['joinedUtc'].toString());
    final rawState = json['status'] ?? json['state'];
    final stateText = rawState.toString().toLowerCase();
    final status = rawState == 2 || stateText == 'active' || stateText == 'live'
        ? 'live'
        : rawState == 1 || stateText == 'pending' || stateText == 'waiting'
        ? 'waiting'
        : 'ended';

    return CoWatchSessionDto(
      id: json['id'].toString(),
      hostId: hostId,
      hostName: (json['hostName'] ?? 'Host').toString(),
      hostAvatarUrl: (json['hostAvatarUrl'] ?? '').toString(),
      contentType: 'reel',
      contentId: (json['contentId'] ?? json['reelId']).toString(),
      contentUrl: (json['contentUrl'] ?? '').toString(),
      thumbnailUrl: (json['thumbnailUrl'] ?? '').toString(),
      participants: [
        CoWatchParticipantDto(
          userId: hostId,
          userName: (json['hostName'] ?? 'Host').toString(),
          userAvatarUrl: (json['hostAvatarUrl'] ?? '').toString(),
          joinedAt: createdAt,
        ),
        if (guestId != null)
          CoWatchParticipantDto(
            userId: guestId,
            userName: (json['guestName'] ?? 'Guest').toString(),
            userAvatarUrl: (json['guestAvatarUrl'] ?? '').toString(),
            joinedAt: joinedAt,
          ),
      ],
      status: status,
      startedAt: createdAt,
    );
  }

  CoWatchSession toDomain() => CoWatchSession(
    id: id,
    hostId: hostId,
    hostName: hostName,
    hostAvatarUrl: hostAvatarUrl,
    contentType: _parseContentType(contentType),
    contentId: contentId,
    contentUrl: contentUrl,
    thumbnailUrl: thumbnailUrl,
    participants: participants.map((p) => p.toDomain()).toList(growable: false),
    status: _parseStatus(status),
    startedAt: startedAt,
  );

  static CoWatchContentType _parseContentType(String s) =>
      s == 'product' ? CoWatchContentType.product : CoWatchContentType.reel;

  static CoWatchSessionStatus _parseStatus(String s) {
    switch (s) {
      case 'live':
        return CoWatchSessionStatus.live;
      case 'ended':
        return CoWatchSessionStatus.ended;
      default:
        return CoWatchSessionStatus.waiting;
    }
  }
}

@freezed
abstract class CoWatchReactionDto with _$CoWatchReactionDto {
  const factory CoWatchReactionDto({
    required String id,
    required String sessionId,
    required String userId,
    required String userName,
    required String reaction,
    required DateTime timestamp,
  }) = _CoWatchReactionDto;

  const CoWatchReactionDto._();

  factory CoWatchReactionDto.fromJson(Map<String, dynamic> json) =>
      _$CoWatchReactionDtoFromJson(json);

  factory CoWatchReactionDto.fromAggregateJson(Map<String, dynamic> json) =>
      CoWatchReactionDto(
        id: json['id'].toString(),
        sessionId: (json['sessionId'] ?? json['coWatchSessionId']).toString(),
        userId: '',
        userName: 'Everyone',
        reaction: (json['reaction'] ?? json['emojiCode']).toString(),
        timestamp: DateTime.parse(
          (json['timestamp'] ?? json['updatedUtc']).toString(),
        ),
      );

  CoWatchReaction toDomain() => CoWatchReaction(
    id: id,
    sessionId: sessionId,
    userId: userId,
    userName: userName,
    reaction: reaction,
    timestamp: timestamp,
  );
}
