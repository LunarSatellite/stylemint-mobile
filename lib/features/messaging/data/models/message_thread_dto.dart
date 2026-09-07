import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/message_thread.dart';

/// Backend `MessageThreadDto` (StyleMint.Modules.Messaging).
/// Mirrors the C# wire shape: id, scope (int), two participant account ids,
/// optional contextId, lastMessageUtc, createdUtc.
///
/// Scope ints (per backend enum):
/// 1 = VendorCreatorPartnership, 2 = CreatorBrandPartnership.
///
/// Implemented as a plain immutable class (not @freezed) because the
/// project's freezed `.g.dart` codegen has not produced files for the
/// messaging tree; the rest of the codebase keeps using freezed.
class MessageThreadDto {
  const MessageThreadDto({
    required this.id,
    required this.scope,
    required this.participantAId,
    required this.participantBId,
    this.contextId,
    this.lastMessageUtc,
    required this.createdUtc,
  });

  final String id;
  final int scope;
  final String participantAId;
  final String participantBId;
  final String? contextId;
  final DateTime? lastMessageUtc;
  final DateTime createdUtc;

  factory MessageThreadDto.fromJson(Map<String, dynamic> json) {
    return MessageThreadDto(
      id: json['id'] as String,
      scope: (json['scope'] as num).toInt(),
      participantAId: json['participantAId'] as String,
      participantBId: json['participantBId'] as String,
      contextId: json['contextId'] as String?,
      lastMessageUtc: json['lastMessageUtc'] == null
          ? null
          : DateTime.parse(json['lastMessageUtc'] as String),
      createdUtc: DateTime.parse(json['createdUtc'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'scope': scope,
        'participantAId': participantAId,
        'participantBId': participantBId,
        if (contextId != null) 'contextId': contextId,
        if (lastMessageUtc != null)
          'lastMessageUtc': lastMessageUtc!.toIso8601String(),
        'createdUtc': createdUtc.toIso8601String(),
      };

  MessageThread toDomain() => MessageThread(
        id: id,
        scope: MessageThreadScope.fromInt(scope),
        participantAId: participantAId,
        participantBId: participantBId,
        contextId: contextId,
        lastMessageUtc: lastMessageUtc,
        createdUtc: createdUtc,
      );
}