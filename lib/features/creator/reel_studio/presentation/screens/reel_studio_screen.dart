import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/notifiers/reel_studio_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/widgets/studio_insights_section.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ReelStudioScreen extends ConsumerWidget {
  const ReelStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reelStudioNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Reel Studio', style: DesignTokens.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DesignTokens.primaryGreen,
        foregroundColor: DesignTokens.textDark,
        onPressed: () async {
          ref.read(createDraftNotifierProvider.notifier).reset();
          // The draft is saved as soon as Create Draft's "Save" succeeds,
          // independent of whether the AI coaching analysis that follows
          // succeeds — but this list previously only refreshed itself on
          // a *successful* analysis, so a saved draft stayed invisible
          // here whenever coaching failed (e.g. no AI provider configured).
          await context.push('/creator/reel-studio/create');
          if (context.mounted) {
            ref.read(reelStudioNotifierProvider.notifier).load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Draft'),
      ),
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (recipes, drafts) {
            return RefreshIndicator(
              color: DesignTokens.primaryGreen,
              onRefresh: () async {
                ref
                  ..invalidate(launchpadProvider)
                  ..invalidate(collabSuggestionsProvider)
                  ..invalidate(dropPartyPromptProvider)
                  ..invalidate(tagNudgesProvider);
                await ref.read(reelStudioNotifierProvider.notifier).load();
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s16,
                  120 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  const StudioLaunchpadSection(),
                  const SizedBox(height: DesignTokens.s24),
                  const StudioIdeasSection(),
                  const SizedBox(height: DesignTokens.s24),
                  if (drafts.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Your Drafts',
                      count: drafts.length,
                    ),
                    ...drafts.map(
                      (draft) => _DraftTile(
                        draft: draft,
                        onTap: () async {
                          ref
                              .read(createDraftNotifierProvider.notifier)
                              .editExisting(draft);
                          await context.push(
                            '/creator/reel-studio/create',
                          );
                          if (context.mounted) {
                            ref
                                .read(reelStudioNotifierProvider.notifier)
                                .load();
                          }
                        },
                        onDelete: () => ref
                            .read(reelStudioNotifierProvider.notifier)
                            .deleteDraft(draft.id),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s24),
                  ] else ...[
                    const _SectionHeader(title: 'Your Drafts', count: 0),
                    const _EmptyCollectionCard(
                      icon: Icons.video_library_outlined,
                      message: 'No drafts yet. Tap New Draft to create one.',
                    ),
                    const SizedBox(height: DesignTokens.s24),
                  ],
                  if (recipes.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'AI Recipes',
                      count: recipes.length,
                    ),
                    ...recipes.map((recipe) => _RecipeTile(recipe: recipe)),
                  ] else ...[
                    const _SectionHeader(title: 'Reel Recipes', count: 0),
                    const _EmptyCollectionCard(
                      icon: Icons.auto_awesome_outlined,
                      message:
                          'No brand or generic recipes match your creator profile yet.',
                    ),
                  ],
                ],
              ),
            );
          },
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load Reel Studio.',
            onRetry: () => ref.read(reelStudioNotifierProvider.notifier).load(),
          ),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _EmptyCollectionCard extends StatelessWidget {
  const _EmptyCollectionCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s16),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Row(
      children: [
        Icon(icon, color: DesignTokens.textMuted, size: 22),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Text(
            message,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ),
      ],
    ),
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
  const _DraftTile({
    required this.draft,
    required this.onTap,
    required this.onDelete,
  });

  final ReelDraft draft;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      child: Container(
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
                Icon(
                  draft.platform.icon,
                  color: draft.platform.color,
                  size: 18,
                ),
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
                children: draft.hashtags
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
              Icon(
                recipe.fromBrand ? Icons.lock_outline : Icons.auto_awesome,
                color: DesignTokens.primaryGreen,
                size: 18,
              ),
              const SizedBox(width: DesignTokens.s8),
              Expanded(
                child: Text(
                  recipe.title,
                  style: DesignTokens.oneLinerSemibold.copyWith(
                    color: DesignTokens.primaryGreen,
                  ),
                ),
              ),
              if (recipe.intendedDurationSeconds > 0)
                Text(
                  _durationLabel(recipe.intendedDurationSeconds),
                  style: DesignTokens.tiny,
                ),
            ],
          ),
          if (recipe.suggestedMusic.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Row(
              children: [
                const Icon(
                  Icons.music_note_outlined,
                  color: DesignTokens.textMuted,
                  size: 16,
                ),
                const SizedBox(width: DesignTokens.s4),
                Expanded(
                  child: Text(
                    recipe.suggestedMusic,
                    style: DesignTokens.smallRegular,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: DesignTokens.s8),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s8,
                vertical: DesignTokens.s4,
              ),
              decoration: BoxDecoration(
                color: recipe.fromBrand
                    ? DesignTokens.statusOngoingBg
                    : DesignTokens.chipsSelectedFill,
                borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
              ),
              child: Text(
                recipe.fromBrand ? 'From the brand' : 'Generic recipe',
                style: DesignTokens.tiny.copyWith(
                  color: recipe.fromBrand
                      ? DesignTokens.statusOngoingIcon
                      : DesignTokens.primaryGreen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _durationLabel(int seconds) {
    final minutes = seconds ~/ 60;
    final remainder = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainder';
  }
}
