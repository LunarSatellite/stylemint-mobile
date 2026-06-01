import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/notifiers/reel_studio_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ReelStudioScreen extends ConsumerWidget {
  const ReelStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reelStudioNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: DesignTokens.textDark,
        onPressed: () => context.push('/creator/reel-studio/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Draft'),
      ),
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (recipes, drafts) {
            if (recipes.isEmpty && drafts.isEmpty) {
              return const SmEmptyState(
                message: 'No recipes or drafts yet.\nTap + to create one.',
                icon: Icons.video_library_outlined,
              );
            }
            return RefreshIndicator(
              color: DesignTokens.primaryGreen,
              onRefresh:
                  () => ref.read(reelStudioNotifierProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.all(DesignTokens.s16),
                children: [
                  if (drafts.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Your Drafts',
                      count: drafts.length,
                    ),
                    ...drafts.map((draft) => _DraftTile(
                          draft: draft,
                          onDelete: () => ref
                              .read(reelStudioNotifierProvider.notifier)
                              .deleteDraft(draft.id),
                        )),
                    const SizedBox(height: DesignTokens.s24),
                  ],
                  if (recipes.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'AI Recipes',
                      count: recipes.length,
                    ),
                    ...recipes.map((recipe) => _RecipeTile(recipe: recipe)),
                  ],
                ],
              ),
            );
          },
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load Reel Studio.',
            onRetry:
                () => ref.read(reelStudioNotifierProvider.notifier).load(),
          ),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Text(
        '$title ($count)',
        style: DesignTokens.h3,
      ),
    );
  }
}

class _DraftTile extends StatelessWidget {
  const _DraftTile({required this.draft, required this.onDelete});

  final ReelDraft draft;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(draft.platform.icon, color: draft.platform.color, size: 18),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  draft.caption.isNotEmpty ? draft.caption : 'Untitled draft',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.oneLinerSemibold,
                ),
              ),
              _DraftStatusBadge(status: draft.status),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: DesignTokens.textMuted,
                onPressed: onDelete,
              ),
            ],
          ),
          if (draft.hashtags.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s4,
              runSpacing: DesignTokens.s4,
              children:
                  draft.hashtags
                      .map(
                        (h) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s8,
                            vertical: DesignTokens.s4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryGreenLight,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.chipRadius,
                            ),
                          ),
                          child: Text(
                            '#$h',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _DraftStatusBadge extends StatelessWidget {
  const _DraftStatusBadge({required this.status});

  final ReelDraftStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String label) = switch (status) {
      ReelDraftStatus.draft => (
        DesignTokens.bgAppBodyLight,
        DesignTokens.textMuted,
        'Draft',
      ),
      ReelDraftStatus.coaching => (
        DesignTokens.statusOngoingBg,
        DesignTokens.statusOngoingIcon,
        'Coaching',
      ),
      ReelDraftStatus.ready => (
        DesignTokens.statusCompletedBg,
        DesignTokens.statusCompletedIcon,
        'Ready',
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
      ),
      child: Text(label, style: DesignTokens.tiny.copyWith(color: fg)),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe});

  final ReelRecipe recipe;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: DesignTokens.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: DesignTokens.primaryGreen, size: 18),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  recipe.title,
                  style: DesignTokens.oneLinerSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
              Icon(recipe.platform.icon, color: recipe.platform.color, size: 18),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(recipe.description, style: DesignTokens.mediumRegular),
          if (recipe.hashtags.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s4,
              runSpacing: DesignTokens.s4,
              children:
                  recipe.hashtags
                      .map(
                        (h) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.s8,
                            vertical: DesignTokens.s4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.chipsSelectedFill,
                            borderRadius: BorderRadius.circular(
                              DesignTokens.chipRadius,
                            ),
                          ),
                          child: Text(
                            '#$h',
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.primaryGreen,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }
}
