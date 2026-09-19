import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/assistant/domain/entities/companion_turn.dart';
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
          onPressed: () => context.push(RouteNames.assistantNewConversation),
          backgroundColor: DesignTokens.primaryGreen,
          foregroundColor: DesignTokens.bgAppBody,
          icon: const Icon(Icons.add_comment_outlined),
          label: const Text('New chat'),
        ),
      ),
      body: SafeArea(
        child: conversations.when(
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
                  onAction: () =>
                      context.push(RouteNames.assistantNewConversation),
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
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DesignTokens.s8),
                  itemBuilder: (context, index) =>
                      _ConversationRow(summary: list.items[index]),
                ),
        ),
      ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.summary});

  final ConversationSummary summary;

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
          onTap: () => context.push(
            RouteNames.assistantConversation.replaceFirst(
              ':conversationId',
              summary.id,
            ),
          ),
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
