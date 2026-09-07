import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/direct_message.dart';

/// Backend `DirectMessageDto` (StyleMint.Modules.Messaging). v1 carries
/// only text; attachment ids will be added when the backend lands them.
///
/// Implemented as a plain immutable class (not @freezed) because the
/// project's freezed `.g.dart` codegen has not produced files for the
/// messaging tree; the rest of the codebase keeps using freezed.
class DirectMessageDto {
  const DirectMessageDto({
    required this.id,
    required this.threadId,
    required this.senderAccountId,
    this.body = '',
    required this.sentUtc,
  });

  final String id;
  final String threadId;
  final String senderAccountId;
  final String body;
  final DateTime sentUtc;

  factory DirectMessageDto.fromJson(Map<String, dynamic> json) {
    return DirectMessageDto(
      id: json['id'] as String,
      threadId: json['threadId'] as String,
      senderAccountId: json['senderAccountId'] as String,
      body: (json['body'] as String?) ?? '',
      sentUtc: DateTime.parse(json['sentUtc'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'threadId': threadId,
        'senderAccountId': senderAccountId,
        'body': body,
        'sentUtc': sentUtc.toIso8601String(),
      };

  DirectMessage toDomain() => DirectMessage(
        id: id,
        threadId: threadId,
        senderAccountId: senderAccountId,
        body: body,
        sentUtc: sentUtc,
      );
}