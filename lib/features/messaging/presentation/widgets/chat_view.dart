import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/entities/direct_message.dart';
import 'package:stylemint_mobile_frontend/features/messaging/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Args for the reusable chat view. Callers pass a `threadId` of an
/// existing thread, an `otherParticipantId` to open one fresh, or a
/// `profileId` (resolved to the account id via
/// `GET /v1/accounts/by-profile/{id}`). The header fields
/// (`title`, `subtitle`, `avatarAsset`) are display-only.
class ChatViewArgs {
  const ChatViewArgs({
    this.threadId,
    this.otherParticipantId,
    this.profileId,
    this.scope = MessageThreadScope.vendorCreatorPartnership,
    this.contextId,
    required this.title,
    this.subtitle = '',
    this.avatarAsset = '',
  });

  final String? threadId;
  final String? otherParticipantId;

  /// The counterpart role-profile id. Resolved to an account id
  /// via `GET /v1/accounts/by-profile/{id}` and used to open or
  /// fetch the thread. Use this when callers only have the profile id.
  final String? profileId;
  final MessageThreadScope scope;
  final String? contextId;
  final String title;
  final String subtitle;
  final String avatarAsset;
}

/// Shared chat body. Both the vendor's `MessageCreatorScreen` and the
/// creator's `BrandMessagingScreen` mount this widget so the UX stays
/// consistent (same composer, same message bubble styling, same
/// realtime path). Resolves the actual thread id by calling
/// `POST /v1/message-threads` when only `otherParticipantId` or
/// `profileId` is supplied.
class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key, required this.args});
  final ChatViewArgs args;

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _threadId;
  bool _opening = false;
  String? _openError;

  @override
  void initState() {
    super.initState();
    _threadId = widget.args.threadId;
    if (_threadId == null &&
        (widget.args.otherParticipantId != null ||
            (widget.args.profileId != null &&
                widget.args.profileId!.isNotEmpty))) {
      _openThread();
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _openThread() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _openError = null;
    });
    final repo = ref.read(messagingRepositoryProvider);
    String? otherId = widget.args.otherParticipantId;
    if (otherId == null || otherId.isEmpty) {
      final profileId = widget.args.profileId;
      if (profileId == null || profileId.isEmpty) {
        setState(() {
          _opening = false;
          _openError = 'No participant id provided.';
        });
        return;
      }
      String resolved;
      try {
        resolved = await ref.read(accountByProfileProvider(profileId).future);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _opening = false;
          _openError = 'Could not open this conversation. Please try again later.';
        });
        return;
      }
      if (!mounted) return;
      otherId = resolved;
      if (otherId.isEmpty) {
        setState(() {
          _opening = false;
          _openError = 'Could not resolve participant account.';
        });
        return;
      }
    }
    final result = await repo.openThread(
      scope: widget.args.scope,
      otherParticipantAccountId: otherId,
      contextId: widget.args.contextId,
    );
    if (!mounted) return;
    setState(() {
      _opening = false;
      _openError = result.fold((f) => f.toString(), (_) => null);
    });
    result.fold(
      (_) => null,
      (thread) => setState(() => _threadId = thread.id),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = _threadId;
    return Column(
      children: [
        if (_openError != null) _ErrorBanner(message: _openError!),
        if (id == null)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
            ),
          )
        else
          Expanded(
            child: _MessageList(
              threadId: id,
              scrollController: _scrollCtrl,
              onNewMessage: _scrollToBottom,
            ),
          ),
        _InputBar(
          controller: _msgCtrl,
          enabled: id != null,
          onSend: id == null
              ? null
              : () async {
                  final body = _msgCtrl.text;
                  if (body.trim().isEmpty) return;
                  _msgCtrl.clear();
                  await ref
                      .read(chatNotifierProvider(id).notifier)
                      .send(body);
                  _scrollToBottom();
                },
        ),
      ],
    );
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList({
    required this.threadId,
    required this.scrollController,
    required this.onNewMessage,
  });

  final String threadId;
  final ScrollController scrollController;
  final VoidCallback onNewMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatNotifierProvider(threadId));
    final me = ref.watch(currentAccountIdProvider);

    if (state.loading && state.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
    }
    if (state.error != null && state.messages.isEmpty) {
      return Center(
        child: Text(
          state.error!,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.messages.isNotEmpty) onNewMessage();
    });

    if (state.messages.isEmpty) {
      return const Center(
        child: Text(
          'Say hi to start the conversation.',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s16,
      ),
      itemCount: _rowCountFor(state.messages),
      itemBuilder: (_, i) {
        final entry = _entryAt(state.messages, i);
        if (entry.kind == _RowKind.header) {
          return _DateHeader(utc: entry.date!);
        }
        final m = entry.message!;
        return _MessageBubble(message: m, isSent: m.senderAccountId == me);
      },
    );
  }
}

enum _RowKind { header, message }

class _RowEntry {
  const _RowEntry.header(DateTime date) : kind = _RowKind.header, date = date, message = null;
  const _RowEntry.message(DirectMessage message) : kind = _RowKind.message, date = null, message = message;
  final _RowKind kind;
  final DateTime? date;
  final DirectMessage? message;
}

int _rowCountFor(List<DirectMessage> messages) {
  if (messages.isEmpty) return 0;
  var count = messages.length;
  for (var i = 0; i < messages.length; i++) {
    final m = messages[i];
    final d = (m.sentUtc).toLocal();
    final showHeader = i == 0 || !_sameDay(messages[i - 1].sentUtc.toLocal(), d);
    if (showHeader) count++;
  }
  return count;
}

_RowEntry _entryAt(List<DirectMessage> messages, int i) {
  var consumed = 0;
  for (var k = 0; k < messages.length; k++) {
    final m = messages[k];
    final d = (m.sentUtc).toLocal();
    final showHeader = k == 0 || !_sameDay(messages[k - 1].sentUtc.toLocal(), d);
    if (showHeader) {
      if (consumed == i) return _RowEntry.header((m.sentUtc));
      consumed++;
    }
    if (consumed == i) return _RowEntry.message(m);
    consumed++;
  }
  throw StateError('entryAt out of range');
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.utc});
  final DateTime utc;

  @override
  Widget build(BuildContext context) {
    final local = utc.toLocal();
    final today = DateTime.now();
    final label = _labelFor(local, today);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            color: DesignTokens.textMuted,
          ),
        ),
      ),
    );
  }

  String _labelFor(DateTime local, DateTime today) {
    if (_sameDay(local, today)) return 'Today';
    final yesterday = today.subtract(const Duration(days: 1));
    if (_sameDay(local, yesterday)) return 'Yesterday';
    if (today.difference(local).inDays < 7) {
      return DateFormat.EEEE().format(local);
    }
    return DateFormat('d MMM yyyy').format(local);
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isSent});
  final DirectMessage message;
  final bool isSent;

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(message.sentUtc);
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isSent
              ? DesignTokens.primaryGreen
              : const Color(0xFF27272A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isSent ? 14 : 4),
            bottomRight: Radius.circular(isSent ? 4 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                height: 1.4,
                color: isSent
                    ? const Color(0xFF06190E)
                    : DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 10,
                    color: isSent
                        ? const Color(0xFF06190E).withValues(alpha: 0.7)
                        : DesignTokens.textMuted,
                  ),
                ),
                if (isSent) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 12,
                    color: const Color(0xFF06190E).withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime utc) {
    final local = utc.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback? onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(top: BorderSide(color: DesignTokens.borderDefault)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s16,
            DesignTokens.s16,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF27272A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF52525C)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          enabled: enabled,
                          textInputAction: TextInputAction.send,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            color: DesignTokens.textWhite,
                            height: 1.5,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 14,
                              color: DesignTokens.textMuted,
                            ),
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => onSend?.call(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              GestureDetector(
                onTap: enabled ? onSend : null,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: enabled
                        ? DesignTokens.primaryGreen
                        : DesignTokens.bgAppBodyLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    color: enabled
                        ? const Color(0xFF06190E)
                        : DesignTokens.textMuted,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: const Color(0xFF7F1D1D),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          message,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            color: DesignTokens.textWhite,
          ),
        ),
      );
}
