/// Pure Dart — no JSON, no Dio.
///
/// The personal shopping assistant ("Minty") is a conversation and nothing
/// more. The proposal's commitment is explicit: the AI "will not set prices,
/// reserve stock or move money." So there is no order, no reservation and no
/// payment anywhere in this domain. The single act a conversation can cause
/// is putting one product the assistant *itself suggested* into the caller's
/// own cart, and only when the customer asks for it.
library;

import 'package:flutter/foundation.dart';

/// Who spoke. The wire sends `"user" | "minty" | "system"`.
enum CompanionTurnRole {
  /// The customer.
  user,

  /// The assistant.
  minty,

  /// A receipt the backend appended, e.g. "added to your bag".
  system;

  static CompanionTurnRole parse(Object? raw) => switch (raw) {
    'user' => CompanionTurnRole.user,
    'minty' => CompanionTurnRole.minty,
    'system' => CompanionTurnRole.system,
    // An unknown role is read as the assistant rather than as the customer:
    // a turn must never be mistaken for something the customer said, because
    // only a non-user turn can carry suggestions.
    _ => CompanionTurnRole.minty,
  };

  String get wire => name;

  /// Only the assistant suggests. A user turn never carries products, and
  /// [CompanionTurn.suggestedProductIds] enforces that structurally.
  bool get canSuggest => this == CompanionTurnRole.minty;
}

/// One message in a thread.
///
/// `mood` and `contextType` arrive as **numbers** here while the mission API
/// sends its enums as **strings**. That inconsistency is known and deliberate
/// on the backend for now, so both are kept as they came rather than being
/// forced into one shape.
@immutable
class CompanionTurn {
  const CompanionTurn({
    required this.id,
    required this.threadId,
    required this.role,
    required this.message,
    required this.createdUtc,
    this.accountId = '',
    this.mood,
    this.contextType,
    this.suggestedProductIds = const <String>[],
    this.suggestedReelIds = const <String>[],
  });

  final String id;
  final String threadId;
  final CompanionTurnRole role;
  final String message;
  final DateTime createdUtc;
  final String accountId;

  /// 1..7 on the wire, or null. Numeric by backend contract.
  final int? mood;

  /// 1..12 on the wire, or null. Numeric by backend contract.
  final int? contextType;

  /// Parsed from the comma-separated `productIdsSuggested` string.
  ///
  /// Empty for every [CompanionTurnRole.user] turn by construction — see
  /// [CompanionTurnParsing.suggestionsFrom]. This is the *only* list the UI
  /// may offer an add-to-cart action for, and the backend independently
  /// refuses anything else.
  final List<String> suggestedProductIds;

  final List<String> suggestedReelIds;

  bool get hasSuggestions => suggestedProductIds.isNotEmpty;

  /// Whether this turn may be asked to add [productId] to the cart.
  ///
  /// Both halves matter: the turn must be one that can suggest at all (never
  /// the customer's own), and the product must be one it actually named.
  bool suggests(String productId) =>
      role.canSuggest &&
      suggestedProductIds.any(
        (id) => id.toLowerCase() == productId.trim().toLowerCase(),
      );

  // Value equality on identity + what it suggested, so a Riverpod family
  // keyed on a turn resolves its products once rather than on every rebuild.
  @override
  bool operator ==(Object other) =>
      other is CompanionTurn &&
      other.id == id &&
      other.role == role &&
      other.suggestedProductIds.join(',') == suggestedProductIds.join(',');

  @override
  int get hashCode => Object.hash(id, role, suggestedProductIds.join(','));
}

/// Shared parsing for the comma-separated guid strings the API sends.
abstract final class CompanionTurnParsing {
  /// Splits `"a,b , ,b"` into `['a', 'b']` — trimmed, blanks dropped, order
  /// preserved, duplicates collapsed case-insensitively.
  static List<String> idList(Object? raw) {
    if (raw is! String || raw.trim().isEmpty) return const <String>[];
    final seen = <String>{};
    final out = <String>[];
    for (final part in raw.split(',')) {
      final id = part.trim();
      if (id.isEmpty) continue;
      if (seen.add(id.toLowerCase())) out.add(id);
    }
    return List.unmodifiable(out);
  }

  /// [idList], but empty for any role that cannot suggest.
  ///
  /// A user turn that somehow came back carrying product ids is not rendered
  /// as a suggestion — there would be no way for the customer to "approve"
  /// their own message, and the backend rejects that too.
  static List<String> suggestionsFrom(Object? raw, CompanionTurnRole role) =>
      role.canSuggest ? idList(raw) : const <String>[];
}

/// A row in the conversation history list.
class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.title,
    required this.messageCount,
    required this.lastMessageUtc,
  });

  final String id;
  final String title;
  final int messageCount;
  final DateTime lastMessageUtc;
}

/// One cursor page of a thread, oldest turn first.
class ConversationPage {
  const ConversationPage({
    required this.conversation,
    required this.turns,
    required this.totalTurns,
    this.nextCursor,
  });

  final ConversationSummary conversation;

  /// Oldest first, as the API sends them.
  final List<CompanionTurn> turns;
  final int totalTurns;

  /// Null when this is the last page.
  final String? nextCursor;

  bool get hasMore => (nextCursor ?? '').isNotEmpty;
}

/// What a send returns: both turns, and the thread they landed in.
class ChatReply {
  const ChatReply({
    required this.conversationId,
    required this.userTurn,
    required this.reply,
  });

  final String conversationId;
  final CompanionTurn userTurn;
  final CompanionTurn reply;
}

/// The result of the one action a conversation can cause.
class CartAddition {
  const CartAddition({
    required this.conversationId,
    required this.messageId,
    required this.productId,
    required this.quantity,
    required this.cartItemCount,
    required this.addedUtc,
    this.receiptTurn,
  });

  final String conversationId;
  final String messageId;
  final String productId;
  final int quantity;

  /// Units in the cart after the add — the authoritative number for the badge.
  final int cartItemCount;
  final DateTime addedUtc;

  /// The system turn the backend appended recording the add, when it sent one.
  final CompanionTurn? receiptTurn;
}

/// A cursor page of conversation summaries.
class ConversationList {
  const ConversationList({required this.items, this.nextCursor});

  final List<ConversationSummary> items;
  final String? nextCursor;

  bool get hasMore => (nextCursor ?? '').isNotEmpty;
}
