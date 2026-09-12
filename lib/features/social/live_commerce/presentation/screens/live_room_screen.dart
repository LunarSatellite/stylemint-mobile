import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/config/api_config.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/entities/live_session.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The live room — joins the LiveCommerceHub SignalR connection for
/// [sessionId] and renders viewer count, reaction bursts, a pinned-product
/// banner, and chat. There's no in-app video player here (that needs
/// WebRTC/streaming infra this pass doesn't build) — the video area is a
/// placeholder "LIVE" surface, same fallback pattern ReelPlayer uses for
/// platforms it can't render inline.
class LiveRoomScreen extends ConsumerStatefulWidget {
  const LiveRoomScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<LiveRoomScreen> createState() => _LiveRoomScreenState();
}

class _LiveRoomScreenState extends ConsumerState<LiveRoomScreen> {
  final _chatController = TextEditingController();
  final _chatScroll = ScrollController();
  final List<LiveChatMessage> _messages = [];

  int? _viewerCount;
  String? _pinnedProductId;
  StreamSubscription<LiveRoomEvent>? _sub;
  bool _joining = true;

  @override
  void initState() {
    super.initState();
    unawaited(_join());
  }

  Future<void> _join() async {
    final service = ref.read(liveCommerceRealtimeServiceProvider);
    _sub = service.events.listen(_onEvent);

    final token = await ref.read(tokenStorageProvider).accessToken;
    await service.join(
      hubBaseUrl: ApiConfig.baseUrl,
      sessionId: widget.sessionId,
      accessToken: token,
    );
    if (mounted) setState(() => _joining = false);
  }

  void _onEvent(LiveRoomEvent event) {
    if (!mounted) return;
    switch (event) {
      case ViewerCountUpdated(:final count):
        setState(() => _viewerCount = count);
      case ProductPinned(:final productId):
        setState(() => _pinnedProductId = productId);
      case LiveChatMessage():
        setState(() => _messages.add(event));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScroll.hasClients) {
            _chatScroll.jumpTo(_chatScroll.position.maxScrollExtent);
          }
        });
      case ReactionBurst():
      case ProductReserved():
      case ReserveFailed():
      case PurchaseConfirmed():
      case PurchaseFailed():
        // Reaction bursts are purely decorative here (no animation layer
        // built this pass) and reservation/purchase flow is a follow-up —
        // acknowledged in the event model but not yet surfaced in the UI.
        break;
    }
  }

  void _sendChat() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    unawaited(ref.read(liveCommerceRealtimeServiceProvider).sendMessage(text));
    _chatController.clear();
  }

  void _sendReaction(String type) {
    unawaited(ref.read(liveCommerceRealtimeServiceProvider).sendReaction(type));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.baseBlack,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  const ColoredBox(
                    color: DesignTokens.baseBlack,
                    child: Center(
                      child: Icon(Icons.podcasts, size: 64, color: DesignTokens.iconLight),
                    ),
                  ),
                  Positioned(
                    top: DesignTokens.s12,
                    left: DesignTokens.s12,
                    child: _LiveBadge(viewerCount: _viewerCount, joining: _joining),
                  ),
                  Positioned(
                    top: DesignTokens.s12,
                    right: DesignTokens.s12,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: DesignTokens.iconWhite),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  if (_pinnedProductId != null)
                    Positioned(
                      left: DesignTokens.s12,
                      right: DesignTokens.s12,
                      bottom: DesignTokens.s12,
                      child: Container(
                        padding: const EdgeInsets.all(DesignTokens.s12),
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppFoundation.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(DesignTokens.s8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.push_pin, size: 16, color: DesignTokens.primaryGreen),
                            const SizedBox(width: DesignTokens.s8),
                            const Expanded(
                              child: Text(
                                'Featured product pinned by host',
                                style: TextStyle(color: DesignTokens.textWhite, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _ChatAndReactions(
              messages: _messages,
              scrollController: _chatScroll,
              chatController: _chatController,
              onSend: _sendChat,
              onReact: _sendReaction,
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.viewerCount, required this.joining});

  final int? viewerCount;
  final bool joining;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 4),
      decoration: BoxDecoration(
        color: DesignTokens.colorError,
        borderRadius: BorderRadius.circular(DesignTokens.s4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'LIVE',
            style: TextStyle(color: DesignTokens.textWhite, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          if (!joining && viewerCount != null) ...[
            const SizedBox(width: DesignTokens.s8),
            const Icon(Icons.visibility, size: 12, color: DesignTokens.textWhite),
            const SizedBox(width: 2),
            Text('$viewerCount', style: const TextStyle(color: DesignTokens.textWhite, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

class _ChatAndReactions extends StatelessWidget {
  const _ChatAndReactions({
    required this.messages,
    required this.scrollController,
    required this.chatController,
    required this.onSend,
    required this.onReact,
  });

  final List<LiveChatMessage> messages;
  final ScrollController scrollController;
  final TextEditingController chatController;
  final VoidCallback onSend;
  final void Function(String reactionType) onReact;

  static const _reactions = ['Love', 'Fire', 'Clap', 'Wow'];
  static const _reactionIcons = {
    'Love': Icons.favorite,
    'Fire': Icons.local_fire_department,
    'Clap': Icons.back_hand,
    'Wow': Icons.sentiment_satisfied_alt,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: DesignTokens.bgAppFoundation,
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 120,
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (_, i) {
                final m = messages[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    m.message,
                    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: _reactions
                .map((r) => Padding(
                      padding: const EdgeInsets.only(right: DesignTokens.s8),
                      child: IconButton(
                        icon: Icon(_reactionIcons[r], color: DesignTokens.primaryGreen),
                        onPressed: () => onReact(r),
                      ),
                    ))
                .toList(growable: false),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatController,
                  style: const TextStyle(color: DesignTokens.textWhite),
                  decoration: const InputDecoration(
                    hintText: 'Say something…',
                    hintStyle: TextStyle(color: DesignTokens.textMuted),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: DesignTokens.primaryGreen),
                onPressed: onSend,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
