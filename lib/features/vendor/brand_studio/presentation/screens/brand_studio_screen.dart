import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/domain/entities/brand_studio.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/notifiers/brand_studio_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/widgets/insight_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/presentation/widgets/template_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/brand_studio/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class BrandStudioScreen extends ConsumerStatefulWidget {
  const BrandStudioScreen({super.key});

  @override
  ConsumerState<BrandStudioScreen> createState() => _BrandStudioScreenState();
}

class _BrandStudioScreenState extends ConsumerState<BrandStudioScreen> {
  String? _selectedIndustry;

  static const _industries = [
    'Fashion',
    'Beauty',
    'Lifestyle',
    'Fitness',
    'Food',
    'Tech',
    'Travel',
    'Home',
  ];

  @override
  Widget build(BuildContext context) {
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
        loadSuccess: (templates, insights, analytics) => RefreshIndicator(
          color: DesignTokens.primaryGreen,
          onRefresh: () =>
              ref.read(brandStudioNotifierProvider.notifier).loadAll(),
          child: ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              _buildInsightsSection(insights),
              const SizedBox(height: DesignTokens.s24),
              _buildTemplatesSection(templates),
              const SizedBox(height: DesignTokens.s24),
              _buildAnalyticsSection(analytics),
            ],
          ),
        ),
        loadFailure: (failure) => SmErrorView(
          message: 'Failed to load brand studio.',
          onRetry: () =>
              ref.read(brandStudioNotifierProvider.notifier).loadAll(),
        ),
        analyticsFailure: (failure) => SmErrorView(
          message: 'Failed to load analytics.',
          onRetry: () {},
        ),
      ),
    );
  }

  Widget _buildInsightsSection(List<MarketInsight> insights) {
    if (insights.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Market Insights', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.s12),
            itemBuilder: (_, i) => InsightCard(insight: insights[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplatesSection(List<CampaignTemplate> templates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Campaign Templates', style: DesignTokens.h3),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _IndustryChip(
                label: 'All',
                selected: _selectedIndustry == null,
                onTap: () {
                  setState(() => _selectedIndustry = null);
                  ref
                      .read(brandStudioNotifierProvider.notifier)
                      .loadTemplates();
                },
              ),
              ..._industries.map(
                (ind) => _IndustryChip(
                  label: ind,
                  selected: _selectedIndustry == ind,
                  onTap: () {
                    setState(() => _selectedIndustry = ind);
                    ref
                        .read(brandStudioNotifierProvider.notifier)
                        .loadTemplates(industry: ind);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (templates.isEmpty)
          const SmEmptyState(message: 'No templates found.', icon: Icons.auto_awesome)
        else
          ...templates.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s8),
              child: TemplateCard(template: t),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalyticsSection(CampaignAnalytics? analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Campaign Analytics', style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s12),
        if (analytics != null) _buildAnalyticsCards(analytics),
        if (analytics == null)
          const SmEmptyState(
            message: 'Select a campaign to view analytics.',
            icon: Icons.analytics_outlined,
          ),
      ],
    );
  }

  Widget _buildAnalyticsCards(CampaignAnalytics analytics) {
    final trendIcon = switch (analytics.trend) {
      TrendDirection.up => Icons.trending_up,
      TrendDirection.down => Icons.trending_down,
      TrendDirection.flat => Icons.trending_flat,
    };
    final trendColor = switch (analytics.trend) {
      TrendDirection.up => DesignTokens.primaryGreen,
      TrendDirection.down => DesignTokens.colorError,
      TrendDirection.flat => DesignTokens.textMuted,
    };

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Impressions',
                value: _formatNumber(analytics.impressions),
                color: DesignTokens.colorInfo,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                label: 'Clicks',
                value: _formatNumber(analytics.clicks),
                color: DesignTokens.primaryGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Conversions',
                value: _formatNumber(analytics.conversions),
                color: DesignTokens.warning500,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                label: 'ROI',
                value: '${analytics.roi.toStringAsFixed(1)}x',
                color: trendColor,
                suffix: Icon(trendIcon, color: trendColor, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s16),
        if (analytics.topCreators.isNotEmpty) ...[
          Text('Top Creators', style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s8),
          ...analytics.topCreators.map(
            (perf) => _TopCreatorRow(performance: perf),
          ),
        ],
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
    this.suffix,
  });

  final String label;
  final String value;
  final Color color;
  final Widget? suffix;

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
          Row(
            children: [
              Text(
                value,
                style: DesignTokens.sectionInnerTitle.copyWith(color: color),
              ),
              if (suffix != null) ...[
                const SizedBox(width: DesignTokens.s4),
                suffix!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TopCreatorRow extends StatelessWidget {
  const _TopCreatorRow({required this.performance});

  final CreatorPerformance performance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(performance.avatarUrl),
            backgroundColor: DesignTokens.bgAppBodyLight,
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(performance.creatorName, style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '${performance.conversionRate.toStringAsFixed(1)}% conversion',
                  style: DesignTokens.tiny,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                performance.salesGenerated,
                style: DesignTokens.mediumSemibold.copyWith(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              Text(
                '${_formatNum(performance.impressions)} imp',
                style: DesignTokens.tiny,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNum(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)}M';
    if (num >= 1000) return '${(num / 1000).toStringAsFixed(1)}K';
    return num.toString();
  }
}

class _IndustryChip extends StatelessWidget {
  const _IndustryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: DesignTokens.s8),
      child: GestureDetector(
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
              color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
