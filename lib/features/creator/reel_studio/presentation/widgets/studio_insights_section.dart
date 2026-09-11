import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/models/reel_studio_extras_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio_extras.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class StudioLaunchpadSection extends ConsumerWidget {
  const StudioLaunchpadSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchpad = ref.watch(launchpadProvider);
    return launchpad.when(
      loading: () => const _LoadingCard(
        key: ValueKey('studio-launchpad-loading'),
        label: 'Loading your creator roadmap…',
      ),
      error: (_, _) => _InlineErrorCard(
        key: const ValueKey('studio-launchpad-error'),
        label: 'Creator roadmap is unavailable right now.',
        onRetry: () => ref.invalidate(launchpadProvider),
      ),
      data: (data) => _LaunchpadCard(data: data),
    );
  }
}

class StudioIdeasSection extends ConsumerWidget {
  const StudioIdeasSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collabs = ref.watch(collabSuggestionsProvider);
    final prompt = ref.watch(dropPartyPromptProvider);
    final nudges = ref.watch(tagNudgesProvider);

    final collabItems = switch (collabs) {
      AsyncData(:final value) => value,
      _ => const <CollabSuggestion>[],
    };
    final dropPrompt = switch (prompt) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final tagItems = switch (nudges) {
      AsyncData(:final value) => value,
      _ => const <TagNudge>[],
    };
    final hasContent =
        collabItems.isNotEmpty || dropPrompt != null || tagItems.isNotEmpty;
    final isLoading = collabs.isLoading || prompt.isLoading || nudges.isLoading;
    final allFailed = collabs.hasError && prompt.hasError && nudges.hasError;

    if (!hasContent && isLoading) {
      return const _LoadingCard(
        key: ValueKey('studio-ideas-loading'),
        label: 'Finding personalised ideas…',
      );
    }
    if (!hasContent && allFailed) {
      return _InlineErrorCard(
        key: const ValueKey('studio-ideas-error'),
        label: 'Personalised ideas are unavailable right now.',
        onRetry: () {
          ref
            ..invalidate(collabSuggestionsProvider)
            ..invalidate(dropPartyPromptProvider)
            ..invalidate(tagNudgesProvider);
        },
      );
    }

    return Column(
      key: const ValueKey('studio-personalised-ideas'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.auto_awesome_outlined,
          title: 'Personalised Ideas',
        ),
        const SizedBox(height: DesignTokens.s8),
        if (!hasContent)
          const _MutedCard(
            text:
                'No new collaboration, product-tag, or Drop Party ideas right now.',
          )
        else ...[
          if (dropPrompt != null)
            _IdeaCard(
              icon: Icons.celebration_outlined,
              title:
                  'Plan a Drop Party with ${dropPrompt.vendorName ?? 'a brand'}',
              body:
                  dropPrompt.suggestionText ??
                  '${dropPrompt.highPerformingReelCount} strong reels make this a good time to plan a live drop.',
            ),
          ...collabItems
              .take(2)
              .map(
                (item) => _IdeaCard(
                  icon: Icons.group_add_outlined,
                  title:
                      'Collaborate with @${item.otherCreatorHandle ?? 'creator'}',
                  body:
                      item.matchReason ??
                      'You both create content around ${item.sharedProductName ?? 'the same product'}.',
                ),
              ),
          ...tagItems
              .take(2)
              .map(
                (item) => _IdeaCard(
                  icon: Icons.sell_outlined,
                  title: 'Tag ${item.productName ?? 'a related product'}',
                  body:
                      item.reason ??
                      'This product is relevant to one of your recent reels.',
                ),
              ),
        ],
      ],
    );
  }
}

class _LaunchpadCard extends StatelessWidget {
  const _LaunchpadCard({required this.data});

  final LaunchpadDto data;

  @override
  Widget build(BuildContext context) {
    final journey = data.journey;
    final nextMilestone = data.milestones
        .where((item) => !item.isCompleted)
        .cast<LaunchpadMilestoneDto?>()
        .firstOrNull;
    final forecast = data.forecast;

    return Column(
      key: const ValueKey('studio-launchpad'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.rocket_launch_outlined,
          title: 'Creator Launchpad',
        ),
        const SizedBox(height: DesignTokens.s8),
        Container(
          padding: const EdgeInsets.all(DesignTokens.s16),
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
                  Expanded(
                    child: Text(
                      journey.currentPhase.isEmpty
                          ? 'Your creator journey'
                          : journey.currentPhase,
                      style: DesignTokens.h3.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                  Text(
                    '${data.milestones.where((m) => m.isCompleted).length}/${data.milestones.length} milestones',
                    style: DesignTokens.tiny,
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              Row(
                children: [
                  Expanded(
                    child: _JourneyStat(
                      label: 'Reels',
                      value: '${journey.totalReelsPublished}',
                    ),
                  ),
                  Expanded(
                    child: _JourneyStat(
                      label: 'Followers',
                      value: '${journey.totalFollowers}',
                    ),
                  ),
                  Expanded(
                    child: _JourneyStat(
                      label: 'Partners',
                      value: '${journey.totalPartnerships}',
                    ),
                  ),
                ],
              ),
              if (nextMilestone != null) ...[
                const SizedBox(height: DesignTokens.s16),
                Text('Next milestone', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nextMilestone.name,
                        style: DesignTokens.smallRegular,
                      ),
                    ),
                    Text(
                      '${nextMilestone.completionPercent.round()}%',
                      style: DesignTokens.tiny,
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.s4),
                  child: LinearProgressIndicator(
                    value: (nextMilestone.completionPercent / 100).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: DesignTokens.bgAppBodyLight,
                    color: DesignTokens.primaryGreen,
                  ),
                ),
                if (nextMilestone.description.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.s8),
                  Text(
                    nextMilestone.description,
                    style: DesignTokens.tiny.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                ],
              ],
              if (forecast != null) ...[
                const SizedBox(height: DesignTokens.s16),
                const Divider(color: DesignTokens.borderDefault),
                const SizedBox(height: DesignTokens.s8),
                Text('Revenue forecast', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'NPR ${forecast.projectedMonthlyEarnings.toStringAsFixed(0)} · ${forecast.projectedMonthLabel}',
                  style: DesignTokens.oneLinerSemibold,
                ),
                if (forecast.recommendation.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(forecast.recommendation, style: DesignTokens.tiny),
                ],
              ],
              if (data.lessons.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.s16),
                const Divider(color: DesignTokens.borderDefault),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Recommended learning',
                  style: DesignTokens.mediumSemibold,
                ),
                const SizedBox(height: DesignTokens.s8),
                ...data.lessons
                    .take(2)
                    .map(
                      (lesson) => Padding(
                        padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              color: DesignTokens.primaryGreen,
                              size: 18,
                            ),
                            const SizedBox(width: DesignTokens.s8),
                            Expanded(
                              child: Text(
                                '${lesson.title} · ${lesson.readingTimeMinutes} min',
                                style: DesignTokens.smallRegular,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JourneyStat extends StatelessWidget {
  const _JourneyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value, style: DesignTokens.oneLinerSemibold),
      Text(label, style: DesignTokens.tiny),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: DesignTokens.primaryGreen, size: 20),
      const SizedBox(width: DesignTokens.s8),
      Text(title, style: DesignTokens.h3),
    ],
  );
}

class _IdeaCard extends StatelessWidget {
  const _IdeaCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: DesignTokens.s8),
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: DesignTokens.primaryGreen, size: 20),
        const SizedBox(width: DesignTokens.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s4),
              Text(body, style: DesignTokens.smallRegular),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MutedCard extends StatelessWidget {
  const _MutedCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Text(
      text,
      style: DesignTokens.smallRegular.copyWith(
        color: DesignTokens.textMuted,
      ),
    ),
  );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Row(
      children: [
        const SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: DesignTokens.primaryGreen,
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(label, style: DesignTokens.smallRegular)),
      ],
    ),
  );
}

class _InlineErrorCard extends StatelessWidget {
  const _InlineErrorCard({
    super.key,
    required this.label,
    required this.onRetry,
  });

  final String label;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          color: DesignTokens.textMuted,
          size: 20,
        ),
        const SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(label, style: DesignTokens.smallRegular)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
