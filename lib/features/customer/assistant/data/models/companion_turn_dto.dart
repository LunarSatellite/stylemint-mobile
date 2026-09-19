import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';

/// Wire mapping for `/v1/customer/companion/chat*`. Hand-written rather than
/// generated: the payload is small, and the one rule that matters here — a
/// user turn never carries suggestions — is easier to see in plain code.

DateTime _utc(Object? raw) =>
    DateTime.tryParse(raw as String? ?? '')?.toUtc() ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

String _str(Object? raw) => raw is String ? raw : '';

int? _intOrNull(Object? raw) => switch (raw) {
  final int value => value,
  final num value => value.toInt(),
  final String value => int.tryParse(value),
  _ => null,
};

int _int(Object? raw) => _intOrNull(raw) ?? 0;

CompanionTurn companionTurnFromJson(Map<String, dynamic> json) {
  final role = CompanionTurnRole.parse(json['role']);
  return CompanionTurn(
    id: _str(json['id']),
    threadId: _str(json['threadId']),
    accountId: _str(json['accountId']),
    role: role,
    message: _str(json['message']),
    mood: _intOrNull(json['mood']),
    contextType: _intOrNull(json['contextType']),
    suggestedProductIds: CompanionTurnParsing.suggestionsFrom(
      json['productIdsSuggested'],
      role,
    ),
    suggestedReelIds: CompanionTurnParsing.suggestionsFrom(
      json['reelIdsSuggested'],
      role,
    ),
    createdUtc: _utc(json['createdUtc']),
  );
}

ConversationSummary conversationSummaryFromJson(Map<String, dynamic> json) =>
    ConversationSummary(
      id: _str(json['id']),
      title: _str(json['title']).trim().isEmpty
          ? 'Conversation'
          : _str(json['title']).trim(),
      messageCount: _int(json['messageCount']),
      lastMessageUtc: _utc(json['lastMessageUtc'] ?? json['updatedUtc']),
    );

ConversationList conversationListFromJson(Map<String, dynamic> json) {
  final items = (json['items'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .map(conversationSummaryFromJson)
      .toList(growable: false);
  return ConversationList(
    items: items,
    nextCursor: json['nextCursor'] as String?,
  );
}

ConversationPage conversationPageFromJson(Map<String, dynamic> json) {
  final conversation = json['conversation'];
  return ConversationPage(
    conversation: conversation is Map<String, dynamic>
        ? conversationSummaryFromJson(conversation)
        : ConversationSummary(
            id: '',
            title: 'Conversation',
            messageCount: 0,
            lastMessageUtc: _epoch,
          ),
    turns: (json['turns'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(companionTurnFromJson)
        .toList(growable: false),
    totalTurns: _int(json['totalTurns']),
    nextCursor: json['nextCursor'] as String?,
  );
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

ChatReply chatReplyFromJson(Map<String, dynamic> json) => ChatReply(
  conversationId: _str(json['conversationId']),
  userTurn: companionTurnFromJson(
    json['userTurn'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  ),
  reply: companionTurnFromJson(
    json['reply'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  ),
);

CartAddition cartAdditionFromJson(Map<String, dynamic> json) {
  final receipt = json['receiptTurn'];
  return CartAddition(
    conversationId: _str(json['conversationId']),
    messageId: _str(json['messageId']),
    productId: _str(json['productId']),
    quantity: _int(json['quantity']),
    cartItemCount: _int(json['cartItemCount']),
    addedUtc: _utc(json['addedUtc']),
    receiptTurn: receipt is Map<String, dynamic>
        ? companionTurnFromJson(receipt)
        : null,
  );
}
