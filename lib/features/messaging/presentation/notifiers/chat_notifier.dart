import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/messaging/data/models/direct_message_dto.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/direct_message.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:stylemint_mobile_frontend/features/messaging/presentation/services/messaging_realtime_service.dart';

/// State for the open thread chat. The state is intentionally flat
/// (not a freezed union) to keep the realtime path simple: the
/// notifier holds a single `List<DirectMessage>` and appends on each
/// realtime push.
class ChatState {
  const ChatState({
    this.loading = true,
    this.messages = const <DirectMessage>[],
    this.error,
    this.sending = false,
  });

  final bool loading;
  final List<DirectMessage> messages;
  final String? error;
  final bool sending;

  ChatState copyWith({
    bool? loading,
    List<DirectMessage>? messages,
    String? error,
    bool? sending,
  }) {
    return ChatState(
      loading: loading ?? this.loading,
      messages: messages ?? this.messages,
      error: error,
      sending: sending ?? this.sending,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier({
    required this.threadId,
    required MessagingRepository repository,
    required MessagingRealtimeService realtime,
    required this.currentAccountId,
  })  : _repository = repository,
        _realtime = realtime,
        super(const ChatState()) {
    _subscription = _realtime.onMessage.listen(_onRealtimeMessage);
    unawaited(load());
  }

  final String threadId;
  final MessagingRepository _repository;
  final MessagingRealtimeService _realtime;
  final String currentAccountId;
  late final StreamSubscription<({String threadId, DirectMessageDto message})> _subscription;

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    final result = await _repository.listMessages(threadId);
    state = result.fold(
      (f) => state.copyWith(
        loading: false,
        error: 'Failed to load messages. Please try again.',
      ),
      (page) {
        // API returns DESC (newest first); reverse for chat display order.
        final ordered = page.items.reversed.toList(growable: false);
        return state.copyWith(loading: false, messages: ordered, error: null);
      },
    );
  }

  Future<void> send(String body) async {
    if (body.trim().isEmpty) return;
    if (state.sending) return;
    state = state.copyWith(sending: true, error: null);
    final result = await _repository.postMessage(threadId: threadId, body: body);
    state = result.fold(
      (f) => state.copyWith(
        sending: false,
        error: 'Failed to send message. Please try again.',
      ),
      // We deliberately do NOT append the returned message here. The
      // backend also fires `thread-message` over SignalR to BOTH
      // participants (including the sender) via
      // SignalRMessageRealtimeNotifier.NotifyMessageAsync, so the
      // realtime handler below will paint the message. If the realtime
      // push failed or this send raced ahead of it, fall back to the
      // REST response so the user sees their message immediately.
      (msg) {
        if (state.messages.any((m) => m.id == msg.id)) {
          return state.copyWith(sending: false, error: null);
        }
        return state.copyWith(
          sending: false,
          messages: [...state.messages, msg],
          error: null,
        );
      },
    );
  }

  void _onRealtimeMessage(
      ({String threadId, DirectMessageDto message}) event) {
    if (event.threadId != threadId) return;
    // Dedup by id (sender + recipient both get the realtime push).
    if (state.messages.any((m) => m.id == event.message.id)) return;
    state = state.copyWith(
      messages: [...state.messages, event.message.toDomain()],
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}