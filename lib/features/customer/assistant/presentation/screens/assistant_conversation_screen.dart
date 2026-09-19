import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/notifiers/assistant_thread_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/widgets/assistant_turn_bubble.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One conversation with Minty.
///
/// Minty answers, and suggests. It cannot place an order: there is no
/// checkout control anywhere on this screen, and the only mutation it can
/// cause is adding one suggested product to the shopper's own cart from the
/// shelf under the turn that suggested it. Ordinary shopping is untouched —
/// this screen is a place to come, not a gate to pass.
class AssistantConversationScreen extends ConsumerStatefulWidget {
  const AssistantConversationScreen({super.key, this.conversationId});

  /// Null starts a new thread; the first send creates it server-side.
  final String? conversationId;

  static const Key composerKey = Key('assistant-composer');
  static const Key sendKey = Key('assistant-send');
  static const Key listKey = Key('assistant-turns');
  static const Key loadMoreKey = Key('assistant-load-more');
  static const Key evidenceKey = Key('assistant-evidence-entry');

  @override
  ConsumerState<AssistantConversationScreen> createState() =>
      _AssistantConversationScreenState();
}

class _AssistantConversationScreenState
    extends ConsumerState<AssistantConversationScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  /// Fixed for this screen's lifetime: the provider family key must not
  /// change when the first send mints a real conversation id, or the state
  /// (including in-flight idempotency keys) would be thrown away.
  late final String _familyKey = widget.conversationId ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(assistantThreadProvider(_familyKey).notifier).load(),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantThreadProvider(_familyKey));
    final conversationId = state.conversationId ?? '';

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Minty'),
        actions: [
          // Minty answers in prose. This opens the same kind of question
          // asked of the record store instead, where the reply arrives with
          // every record it was built from.
          Semantics(
            button: true,
            label: 'Ask a question and see the evidence behind the answer',
            excludeSemantics: true,
            child: IconButton(
              key: AssistantConversationScreen.evidenceKey,
              tooltip: 'Answers with evidence',
              onPressed: () => unawaited(
                context.push(RouteNames.evidenceAnswers),
              ),
              icon: const Icon(Icons.fact_check_outlined),
            ),
          ),
          if (state.lastCartItemCount != null)
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                0,
                0,
                DesignTokens.s12,
                0,
              ),
              child: Center(
                child: MallStatusPill(
                  label: '${state.lastCartItemCount} in bag',
                  tone: MallStatusTone.success,
                  icon: Icons.shopping_bag_outlined,
                  dense: true,
                  semanticLabel: '${state.lastCartItemCount} items in your bag',
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _body(state, conversationId)),
            _Composer(
              controller: _controller,
              sending: state.sending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AssistantThreadState state, String conversationId) {
    if (state.loading && state.turns.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.turns.isEmpty) {
      // MallEmptyState scrolls itself when it is given less room than it
      // needs, so this does not need its own SingleChildScrollView.
      return const MallEmptyState(
        icon: Icons.auto_awesome_outlined,
        eyebrow: 'Personal shopping',
        title: 'Ask Minty anything',
        body:
            'Describe what you are after and Minty will suggest pieces. It '
            'never buys anything for you — adding to your bag is always '
            'your call.',
      );
    }

    return ListView.builder(
      key: AssistantConversationScreen.listKey,
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      // Oldest first, as the API orders a thread, plus one trailing slot for
      // the cursor control.
      itemCount: state.turns.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.turns.length) {
          return Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s12),
            child: Center(
              child: TextButton(
                key: AssistantConversationScreen.loadMoreKey,
                onPressed: state.loadingMore
                    ? null
                    : () => unawaited(
                        ref
                            .read(
                              assistantThreadProvider(_familyKey).notifier,
                            )
                            .loadMore(),
                      ),
                child: Semantics(
                  button: true,
                  label: 'Load the rest of this conversation',
                  excludeSemantics: true,
                  child: Text(
                    state.loadingMore ? 'Loading…' : 'Load more messages',
                  ),
                ),
              ),
            ),
          );
        }
        return AssistantTurnBubble(
          conversationId: conversationId,
          turn: state.turns[index],
        );
      },
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await ref
        .read(assistantThreadProvider(_familyKey).notifier)
        .send(text);
    if (!mounted) return;
    if (ok) {
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
      return;
    }
    final error = ref.read(assistantThreadProvider(_familyKey)).error;
    messenger?.showSnackBar(
      SnackBar(content: Text(error ?? 'That message could not be sent.')),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s12,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Semantics(
              textField: true,
              label: 'Message Minty',
              child: TextField(
                key: AssistantConversationScreen.composerKey,
                controller: controller,
                maxLength: 2000,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  color: DesignTokens.textWhite,
                ),
                decoration: const InputDecoration(
                  hintText: 'Ask Minty…',
                  counterText: '',
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Semantics(
            button: true,
            enabled: !sending,
            label: 'Send message',
            excludeSemantics: true,
            child: IconButton(
              key: AssistantConversationScreen.sendKey,
              onPressed: sending ? null : () => unawaited(onSend()),
              icon: sending
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_upward_rounded),
              style: IconButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreenDark,
                foregroundColor: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
