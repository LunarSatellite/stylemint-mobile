import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/presentation/widgets/companion_recommendations_shelf.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Every conversation the shopper has had with Minty, newest first.
class AssistantConversationsScreen extends ConsumerWidget {
  const AssistantConversationsScreen({super.key});

  static const Key listKey = Key('assistant-conversations');
  static const Key newChatKey = Key('assistant-new-conversation');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(assistantConversationsProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppBody,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppBody,
        title: const Text('Minty'),
      ),
      floatingActionButton: Semantics(
        button: true,
        label: 'Start a new conversation with Minty',
        excludeSemantics: true,
        child: FloatingActionButton.extended(
          key: newChatKey,
          onPressed: () => unawaited(
            _openThread(context, ref, RouteNames.assistantNewConversation),
          ),
          backgroundColor: DesignTokens.primaryGreen,
          foregroundColor: DesignTokens.bgAppBody,
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('New chat'),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CompanionRecommendationsShelf(),
            Expanded(child: _body(context, ref, conversations)),
          ],
        ),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<ConversationList> conversations,
  ) => conversations.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (_, _) => MallErrorState(
      title: "We couldn't load your conversations",
      body: 'Check your connection and try again.',
      onRetry: () => ref.invalidate(assistantConversationsProvider),
    ),
    data: (list) => list.items.isEmpty
        ? MallEmptyState(
            icon: Icons.auto_awesome_outlined,
            eyebrow: 'Personal shopping',
            title: 'Minty is your shopping assistant',
            body:
                'Describe an occasion, a budget or a gap in your '
                'wardrobe. Minty suggests — you decide what goes in '
                'your bag.',
            actionLabel: 'Start a conversation',
            onAction: () => unawaited(
              _openThread(context, ref, RouteNames.assistantNewConversation),
            ),
          )
        : ListView.separated(
            key: listKey,
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s48 + DesignTokens.s32,
            ),
            itemCount: list.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.s8),
            // The screen's context, not the row's: the row may be rebuilt
            // away by the refetch, the screen is what must still be mounted.
            itemBuilder: (_, index) {
              final summary = list.items[index];
              return _ConversationRow(
                summary: summary,
                onTap: () => unawaited(
                  _openThread(
                    context,
                    ref,
                    RouteNames.assistantConversation.replaceFirst(
                      ':conversationId',
                      summary.id,
                    ),
                  ),
                ),
              );
            },
          ),
  );

  /// Opens a thread and refetches the history once the shopper comes back.
  ///
  /// A chat changes the list it was opened from — a new chat adds a row, a
  /// reply bumps a message count — and this route stays mounted underneath,
  /// so without the refetch the list shows what it held before the visit.
  /// The previous rows stay on screen while the refetch runs.
  static Future<void> _openThread(
    BuildContext context,
    WidgetRef ref,
    String location,
  ) async {
    await context.push<void>(location);
    if (!context.mounted) return;
    ref.invalidate(assistantConversationsProvider);
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.summary, required this.onTap});

  final ConversationSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = summary.messageCount;
    final detail = count == 1 ? '1 message' : '$count messages';
    return Semantics(
      button: true,
      label: '${summary.title}, $detail',
      excludeSemantics: true,
      child: Material(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s4),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          height: 1.4,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: DesignTokens.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
