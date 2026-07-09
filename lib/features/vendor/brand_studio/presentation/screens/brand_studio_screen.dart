import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/notifiers/brand_studio_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/widgets/format_learning_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/widgets/top_creator_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Renders the Brand Intelligence Dashboard (`GET /v1/vendor/dashboard`).
///
/// Vendor-facing "campaign template" browsing has no backend support — only
/// admins author goal templates (`GET /v1/admin/brand-studio/goal-templates`)
/// — so this screen shows real insights only, with no fabricated templates
/// or campaign-analytics section.
class BrandStudioScreen extends ConsumerWidget {
  const BrandStudioScreen({super.key});

  static const _windowOptions = [7, 30, 90];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(brandStudioNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Brand Studio', style: DesignTokens.titleMedium),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (insights, windowDays) => RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh: () => ref
              .read(brandStudioNotifierProvider.notifier)
              .load(windowDays: windowDays),
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              _buildWindowSelector(ref, windowDays),
              const SizedBox(height: DesignTokens.s16),
              _buildTopCreatorsSection(insights.topCreators),
              const SizedBox(height: DesignTokens.s24),
              _buildReachSection(insights.reach),
              const SizedBox(height: DesignTokens.s24),
              _buildFormatLearningsSection(insights.formatLearnings),
              const SizedBox(height: DesignTokens.s24),
              if (insights.benchmark != null)
                _buildBenchmarkSection(insights.benchmark!),
              if (insights.benchmark != null)
                const SizedBox(height: DesignTokens.s24),
              _buildSuggestedCreatorsSection(insights.suggestedCreators),
              const SizedBox(height: DesignTokens.s24),
              _buildByRecipeSection(insights.byRecipe),
            ],
          ),
        ),
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load brand studio insights.',
          onRetry: () => ref.read(brandStudioNotifierProvider.notifier).load(),
        ),
      ),
    );
  }

  Widget _buildWindowSelector(WidgetRef ref, int selected) {
    return Row(
      children: _windowOptions
          .map(
            (days) => Padding(
              padding: const EdgeInsets.only(right: DesignTokens.s8),
              child: _WindowChip(
                label: '${days}d',
                selected: selected == days,
                onTap: () => ref
                    .read(brandStudioNotifierProvider.notifier)
                    .load(windowDays: days),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildTopCreatorsSection(List<TopCreatorByAttributedSales> creators) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Creators by Attributed Sales', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s12),
        if (creators.isEmpty)
          const SmEmptyState(
            message: 'No attributed sales in this window yet.',
            icon: Icons.emoji_events_outlined,
          )
        else
          ...creators.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: TopCreatorCard(creator: c),
            ),
          ),
      ],
    );
  }

  Widget _buildReachSection(ReachDiagnosticsSummary reach) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reach Diagnostics', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Impressions',
                value: _formatNumber(reach.totalImpressions),
                color: DesignTokens.colorInfo,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                label: 'Unique Audience',
                value: _formatNumber(reach.uniqueAudience),
                color: DesignTokens.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        _StatCard(
          label: 'Audience Growth',
          value: '${reach.audienceGrowthRate.toStringAsFixed(1)}%',
          color: reach.audienceGrowthRate >= 0
              ? DesignTokens.primaryGreen
              : DesignTokens.colorError,
        ),
        if (reach.topRegions.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            'Top regions: ${reach.topRegions.join(', ')}',
            style: DesignTokens.smallRegular,
          ),
        ],
        if (reach.underperformingRegions.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Underperforming: ${reach.underperformingRegions.join(', ')}',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFormatLearningsSection(List<FormatLearning> learnings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Format Learnings', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s12),
        if (learnings.isEmpty)
          const SmEmptyState(
            message: 'No format learnings yet.',
            icon: Icons.auto_awesome,
          )
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: learnings.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: DesignTokens.s12),
              itemBuilder: (_, i) => FormatLearningCard(learning: learnings[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildBenchmarkSection(CompetitiveBenchmarkSummary benchmark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Competitive Benchmark', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s4),
        Text(
          'vs ${benchmark.cohortLabel} (${benchmark.cohortMemberCount} vendors)',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Your Conversion',
                value: '${benchmark.yourAvgConversion.toStringAsFixed(1)}%',
                color: DesignTokens.primaryGreen,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                label: 'Cohort Median',
                value:
                    '${benchmark.cohortMedianConversion.toStringAsFixed(1)}%',
                color: DesignTokens.colorInfo,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                label: 'Top Quartile',
                value:
                    '${benchmark.cohortTopQuartileConversion.toStringAsFixed(1)}%',
                color: DesignTokens.warning500,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(benchmark.takeaway, style: DesignTokens.smallRegular),
      ],
    );
  }

  Widget _buildSuggestedCreatorsSection(List<SuggestedCreator> creators) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Suggested Creators', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s12),
        if (creators.isEmpty)
          const SmEmptyState(
            message: 'No creator suggestions right now.',
            icon: Icons.person_search_outlined,
          )
        else
          ...creators.map(
            (c) => Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.s8),
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: DesignTokens.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.creatorHandle,
                          style: DesignTokens.mediumSemibold,
                        ),
                      ),
                      Text(
                        '${(c.matchScore * 100).toStringAsFixed(0)}% match',
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  if (c.topThreeReasons.isNotEmpty) ...[
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      c.topThreeReasons,
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildByRecipeSection(List<RecipePerformance> recipes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Performance by Recipe', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s12),
        if (recipes.isEmpty)
          const SmEmptyState(
            message: 'No recipe-tagged sales in this window.',
            icon: Icons.receipt_long_outlined,
          )
        else
          ...recipes.map(
            (r) => Container(
              margin: const EdgeInsets.only(bottom: DesignTokens.s8),
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: DesignTokens.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recipe v${r.recipeVersion}',
                    style: DesignTokens.mediumSemibold,
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    '${r.citingCreatorCount} creators · '
                    '${r.citedReelCount} reels · '
                    '${r.attributedUnits} units',
                    style: DesignTokens.smallRegular,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: DesignTokens.smallRegular),
          const SizedBox(height: DesignTokens.s4),
          Text(
            value,
            style: DesignTokens.sectionInnerTitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16,
          vertical: DesignTokens.s6,
        ),
        decoration: selected
            ? DesignTokens.chipDecorationSelected()
            : DesignTokens.chipDecorationDefault(),
        child: Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.textMuted,
          ),
        ),
      ),
    );
  }
}
