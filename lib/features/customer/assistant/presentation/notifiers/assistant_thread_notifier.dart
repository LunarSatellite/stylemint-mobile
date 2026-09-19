import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/repositories/assistant_repository.dart';
import 'package:uuid/uuid.dart';

/// What one suggestion's add-to-cart control is doing.
///
/// The idempotency key is minted once, when the customer first presses the
/// control, and kept here. A retry after a failure reuses it, so a request
/// that actually landed before the connection dropped cannot add a second
/// unit.
class SuggestionAddState {
  const SuggestionAddState({
    required this.idempotencyKey,
    this.busy = false,
    this.added = false,
    this.error,
  });

  final String idempotencyKey;
  final bool busy;
  final bool added;
  final String? error;

  SuggestionAddState copyWith({bool? busy, bool? added, String? error}) =>
      SuggestionAddState(
        idempotencyKey: idempotencyKey,
        busy: busy ?? this.busy,
        added: added ?? this.added,
        error: error,
      );
}

/// A key that pins an add to one suggestion *inside one turn*.
String suggestionKey(String turnId, String productId) =>
    '$turnId|${productId.toLowerCase()}';

class AssistantThreadState {
  const AssistantThreadState({
    this.conversationId,
    this.turns = const <CompanionTurn>[],
    this.nextCursor,
    this.loading = false,
    this.loadingMore = false,
    this.sending = false,
    this.error,
    this.adds = const <String, SuggestionAddState>{},
    this.lastCartItemCount,
  });

  final String? conversationId;

  /// Oldest first, exactly as the API orders them.
  final List<CompanionTurn> turns;
  final String? nextCursor;
  final bool loading;
  final bool loadingMore;
  final bool sending;
  final String? error;
  final Map<String, SuggestionAddState> adds;

  /// The cart count the last successful add reported.
  final int? lastCartItemCount;

  bool get hasMore => (nextCursor ?? '').isNotEmpty;
  bool get isNew => (conversationId ?? '').isEmpty;

  AssistantThreadState copyWith({
    String? conversationId,
    List<CompanionTurn>? turns,
    String? nextCursor,
    bool? loading,
    bool? loadingMore,
    bool? sending,
    String? error,
    Map<String, SuggestionAddState>? adds,
    int? lastCartItemCount,
  }) => AssistantThreadState(
    conversationId: conversationId ?? this.conversationId,
    turns: turns ?? this.turns,
    nextCursor: nextCursor,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    sending: sending ?? this.sending,
    error: error,
    adds: adds ?? this.adds,
    lastCartItemCount: lastCartItemCount ?? this.lastCartItemCount,
  );
}

/// Drives one conversation thread.
///
/// Nothing here can reach checkout. The only mutation it can cause beyond
/// sending a message is [addSuggestion], which takes the turn object itself
/// and hands it to the repository, where the "this turn suggested it" gate
/// lives.
class AssistantThreadNotifier extends StateNotifier<AssistantThreadState> {
  AssistantThreadNotifier(this._repository, {String? conversationId})
    : super(
        AssistantThreadState(
          conversationId: conversationId,
          // A thread with an id is going to be fetched, so it starts in the
          // loading state rather than flashing "ask Minty anything" first.
          loading: (conversationId ?? '').isNotEmpty,
        ),
      );

  final AssistantRepository _repository;
  static const _uuid = Uuid();

  /// Notified with the authoritative cart count after a successful add, so
  /// the badge the shopper already watches moves.
  void Function(int cartItemCount)? onCartCountChanged;

  Future<void> load() async {
    final id = state.conversationId;
    if (id == null || id.isEmpty) return;
    state = state.copyWith(loading: true, nextCursor: state.nextCursor);
    final result = await _repository.getConversation(id);
    if (!mounted) return;
    state = result.fold(
      (failure) => state.copyWith(
        loading: false,
        error: _message(failure),
        nextCursor: state.nextCursor,
      ),
      (page) => state.copyWith(
        loading: false,
        turns: page.turns,
        nextCursor: page.nextCursor,
      ),
    );
  }

  /// Pulls the next cursor page. The API pages a thread oldest-first, so a
  /// further page is *later* messages and is appended at the end.
  Future<void> loadMore() async {
    final id = state.conversationId;
    final cursor = state.nextCursor;
    if (id == null || id.isEmpty) return;
    if (cursor == null || cursor.isEmpty || state.loadingMore) return;
    state = state.copyWith(loadingMore: true, nextCursor: cursor);
    final result = await _repository.getConversation(id, cursor: cursor);
    if (!mounted) return;
    state = result.fold(
      (failure) => state.copyWith(
        loadingMore: false,
        error: _message(failure),
        nextCursor: cursor,
      ),
      (page) {
        final seen = state.turns.map((t) => t.id).toSet();
        return state.copyWith(
          loadingMore: false,
          turns: [
            ...state.turns,
            ...page.turns.where((t) => !seen.contains(t.id)),
          ],
          nextCursor: page.nextCursor,
        );
      },
    );
  }

  /// Sends [message] and appends both the customer's turn and the reply.
  Future<bool> send(String message) async {
    final text = message.trim();
    if (text.isEmpty || state.sending) return false;
    state = state.copyWith(sending: true, nextCursor: state.nextCursor);
    final result = await _repository.sendMessage(
      message: text,
      conversationId: state.isNew ? null : state.conversationId,
    );
    if (!mounted) return false;
    return result.fold(
      (failure) {
        state = state.copyWith(
          sending: false,
          error: _message(failure),
          nextCursor: state.nextCursor,
        );
        return false;
      },
      (reply) {
        state = state.copyWith(
          sending: false,
          conversationId: reply.conversationId,
          turns: [...state.turns, reply.userTurn, reply.reply],
          nextCursor: state.nextCursor,
        );
        return true;
      },
    );
  }

  /// The one action a conversation can cause.
  ///
  /// Only ever called from an explicit press on the control belonging to
  /// [turn]'s own suggestion list — never on render, on scroll, or on open.
  Future<bool> addSuggestion({
    required CompanionTurn turn,
    required String productId,
  }) async {
    final id = state.conversationId;
    if (id == null || id.isEmpty) return false;
    final key = suggestionKey(turn.id, productId);
    final existing = state.adds[key];
    if (existing != null && (existing.busy || existing.added)) return false;

    // Minted once per customer decision and reused for every retry of it.
    final attempt = existing ?? SuggestionAddState(idempotencyKey: _uuid.v4());
    _setAdd(key, attempt.copyWith(busy: true));

    final result = await _repository.addSuggestedProductToCart(
      conversationId: id,
      turn: turn,
      productId: productId,
      idempotencyKey: attempt.idempotencyKey,
    );
    if (!mounted) return false;
    return result.fold(
      (failure) {
        _setAdd(key, attempt.copyWith(busy: false, error: _message(failure)));
        return false;
      },
      (addition) {
        _setAdd(key, attempt.copyWith(busy: false, added: true));
        final receipt = addition.receiptTurn;
        state = state.copyWith(
          turns: receipt == null || state.turns.any((t) => t.id == receipt.id)
              ? state.turns
              : [...state.turns, receipt],
          lastCartItemCount: addition.cartItemCount,
          nextCursor: state.nextCursor,
        );
        onCartCountChanged?.call(addition.cartItemCount);
        return true;
      },
    );
  }

  void clearError() => state = state.copyWith(nextCursor: state.nextCursor);

  void _setAdd(String key, SuggestionAddState value) {
    state = state.copyWith(
      adds: {...state.adds, key: value},
      nextCursor: state.nextCursor,
    );
  }

  static String _message(NetworkExceptions failure) => failure.when(
    server: (message) => message,
    serverUnavailable: () => 'Minty is unreachable right now. Try again.',
    noInternetConnection: () => 'You appear to be offline.',
    unexpectedError: () => 'Something went wrong. Try again.',
    formatException: () => 'That reply could not be read.',
    emptyData: () => 'Nothing came back.',
    validation: (code, message, _, _) => message ?? _validationCopy(code),
    auth: () => 'Please sign in again.',
    notFound: () => 'This conversation is no longer available.',
    conflict: () => 'That has already been done.',
  );

  static String _validationCopy(String code) => switch (code) {
    'companion.not_suggested' =>
      'That product was not one of these suggestions.',
    _ => 'That could not be done.',
  };
}
