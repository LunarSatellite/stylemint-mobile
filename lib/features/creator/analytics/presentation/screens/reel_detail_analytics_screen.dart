import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_age_bucket.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_location.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_reel_analytics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/earnings_trend_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/gender_distribution.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_header.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_product_earnings_slice.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/reel_statistics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_reel_analytics_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ── Color palette for charts ──────────────────────────────────────────────────

const _kChartColors = [
  Color(0xFF4DA6FF),
  Color(0xFF2ECC71),
  Color(0xFFFF6B6B),
  Color(0xFFFFD93D),
  Color(0xFFAB8FF5),
];

// ── Date filter ───────────────────────────────────────────────────────────────

enum _DateFilter {
  last7Days('Last 7 days', 7),
  last30Days('Last 30 days', 30),
  last90Days('Last 90 days', 90);

  const _DateFilter(this.label, this.days);
  final String label;
  final int days;

  DateTime get fromUtc => DateTime.now().toUtc().subtract(Duration(days: days));
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ReelDetailAnalyticsScreen extends ConsumerStatefulWidget {
  const ReelDetailAnalyticsScreen({super.key, required this.reelId});

  final String reelId;

  @override
  ConsumerState<ReelDetailAnalyticsScreen> createState() =>
      _ReelDetailAnalyticsScreenState();
}

class _ReelDetailAnalyticsScreenState
    extends ConsumerState<ReelDetailAnalyticsScreen> {
  _DateFilter _filter = _DateFilter.last7Days;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      creatorReelAnalyticsNotifierProvider(widget.reelId),
    );
    final analytics = state.maybeWhen(
      loadSuccess: (value) => value,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reel Details', style: DesignTokens.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_border_rounded,
              color: DesignTokens.textWhite,
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saving reel reports is coming soon.'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: DesignTokens.textWhite,
            ),
            onPressed: analytics == null ? null : () => _shareReport(analytics),
          ),
        ],
      ),
      body: state.when(
        initial: () => const SizedBox.shrink(),
        loadInProgress: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                failure.isNoInternet
                    ? 'No internet connection'
                    : 'Failed to load reel analytics',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              ElevatedButton(
                onPressed: _fetch,
                style: DesignTokens.primaryButtonStyle(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loadSuccess: (CreatorReelAnalytics analytics) =>
            _Body(analytics: analytics, filter: _filter, onFilter: _setFilter),
      ),
    );
  }

  void _setFilter(_DateFilter f) {
    setState(() => _filter = f);
    _fetch();
  }

  void _fetch() {
    ref
        .read(creatorReelAnalyticsNotifierProvider(widget.reelId).notifier)
        .fetch(fromUtc: _filter.fromUtc);
  }

  void _shareReport(CreatorReelAnalytics analytics) {
    final reel = analytics.reel;
    final stats = analytics.statistics;
    final lines = <String>[
      'Style Mint — Reel analytics',
      reel.title?.isNotEmpty == true ? reel.title! : 'Untitled reel',
      '',
      'Earnings: ${analytics.totalEarnings.currency} ${analytics.totalEarnings.amount.toStringAsFixed(2)}',
      'Views: ${reel.views}',
      'Likes: ${reel.likes}',
      'Comments: ${reel.comments}',
      'Watch time: ${analytics.watchTimeMinutes} minutes',
      'Conversion rate: ${stats.conversionRate.toStringAsFixed(2)}%',
      'Click-through rate: ${stats.clickThroughRate.toStringAsFixed(2)}%',
      'Completion rate: ${stats.completionRate.toStringAsFixed(2)}%',
      'Unique viewers: ${stats.uniqueViewersEstimate}',
      '',
      'Product earnings',
      ...analytics.earningsDistribution.map(
        (slice) =>
            '${slice.name ?? 'Product'} — ${slice.amount.currency} ${slice.amount.amount.toStringAsFixed(2)} (${slice.quantity} sold)',
      ),
    ];
    if (reel.sourceUrl?.isNotEmpty == true) {
      lines.add('');
      lines.add('Watch reel: ${reel.sourceUrl}');
    }
    unawaited(SharePlus.instance.share(ShareParams(text: lines.join('\n'))));
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.analytics,
    required this.filter,
    required this.onFilter,
  });

  final CreatorReelAnalytics analytics;
  final _DateFilter filter;
  final ValueChanged<_DateFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final from = DateFormat('MMM d, yyyy').format(analytics.window.fromUtc);
    final to = DateFormat('MMM d, yyyy').format(analytics.window.toUtc);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date range + filter chips ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s8,
              DesignTokens.s16,
              DesignTokens.s8,
            ),
            child: Text(
              'Date Range: $from – $to',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DesignTokens.textLight,
              ),
            ),
          ),
          _FilterChipsRow(current: filter, onSelected: onFilter),
          const SizedBox(height: DesignTokens.s16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Reel info card ────────────────────────────────────────
                _ReelInfoCard(reel: analytics.reel),
                const SizedBox(height: DesignTokens.s20),

                // ── Earnings distribution ─────────────────────────────────
                const Text(
                  'Earnings Distribution Data',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Analytics data for each tagged product's earnings",
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: DesignTokens.s12),
                _EarningsDistributionCard(
                  totalEarnings: analytics.totalEarnings,
                  slices: analytics.earningsDistribution,
                ),
                const SizedBox(height: DesignTokens.s16),

                // ── Statistics ────────────────────────────────────────────
                _StatisticsSection(
                  stats: analytics.statistics,
                  watchTimeMinutes: analytics.watchTimeMinutes,
                ),
                const SizedBox(height: DesignTokens.s24),

                // ── Earnings overview chart ────────────────────────────────
                _EarningsOverviewSection(trend: analytics.earningsTrend),
                const SizedBox(height: DesignTokens.s24),

                // ── Audience demographic ──────────────────────────────────
                _AudienceDemographicSection(
                  buckets: analytics.audienceDemographic,
                ),
                const SizedBox(height: DesignTokens.s24),

                // ── Gender distribution ───────────────────────────────────
                _GenderDistributionSection(
                  gender: analytics.genderDistribution,
                ),
                const SizedBox(height: DesignTokens.s24),

                // ── Top locations ─────────────────────────────────────────
                _TopLocationsSection(locations: analytics.topLocations),
                const SizedBox(height: DesignTokens.s32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chips ──────────────────────────────────────────────────────────────

class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({required this.current, required this.onSelected});

  final _DateFilter current;
  final ValueChanged<_DateFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: _DateFilter.values.map((f) {
          final selected = f == current;
          return GestureDetector(
            onTap: () => onSelected(f),
            child: Container(
              margin: const EdgeInsets.only(right: DesignTokens.s8),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? DesignTokens.primaryGreen.withValues(alpha: 0.15)
                    : DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? DesignTokens.primaryGreen
                      : DesignTokens.borderDefault,
                ),
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? DesignTokens.primaryGreen
                      : DesignTokens.textLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Reel info card ────────────────────────────────────────────────────────────

class _ReelInfoCard extends StatelessWidget {
  const _ReelInfoCard({required this.reel});

  final ReelHeader reel;

  @override
  Widget build(BuildContext context) {
    final title = (reel.title?.isNotEmpty ?? false)
        ? reel.title!
        : 'Untitled reel';
    final posted = reel.publishedAtUtc != null
        ? 'Posted on: ${DateFormat('d MMM, yyyy hh:mm a').format(reel.publishedAtUtc!.toLocal())}'
        : '';
    final platform = reel.sourcePlatform ?? '';

    return Container(
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                  child: Container(
                    width: 64,
                    height: 72,
                    color: DesignTokens.bgAppBody,
                    alignment: Alignment.center,
                    child: (reel.thumbnailUrl?.isNotEmpty ?? false)
                        ? Image.network(
                            reel.thumbnailUrl!,
                            width: 64,
                            height: 72,
                            fit: BoxFit.cover,
                          )
                        : const Icon(
                            Icons.play_circle_fill,
                            color: DesignTokens.iconLight,
                            size: 32,
                          ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                          height: 1.4,
                        ),
                      ),
                      if (platform.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Imported from $platform',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (posted.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          posted,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: DesignTokens.textMuted,
                ),
              ],
            ),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _IconStat(icon: Icons.favorite_rounded, value: reel.likes),
                _IconStat(icon: Icons.visibility_outlined, value: reel.views),
                _IconStat(
                  icon: Icons.chat_bubble_outline_rounded,
                  value: reel.comments,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconStat extends StatelessWidget {
  const _IconStat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: DesignTokens.textLight),
        const SizedBox(height: 4),
        Text(
          _compact(value),
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(2)}k';
    return '$n';
  }
}

// ── Earnings distribution card ────────────────────────────────────────────────

class _EarningsDistributionCard extends StatelessWidget {
  const _EarningsDistributionCard({
    required this.totalEarnings,
    required this.slices,
  });

  final dynamic totalEarnings;
  final List<ReelProductEarningsSlice> slices;

  @override
  Widget build(BuildContext context) {
    final total = totalEarnings.amount as double;
    final currency = totalEarnings.currency as String;

    if (slices.isEmpty) {
      return Container(
        decoration: DesignTokens.cardDecoration(),
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Text(
          'No product data yet.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }

    return Container(
      decoration: DesignTokens.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s16,
              DesignTokens.s12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  total.toStringAsFixed(2),
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: DesignTokens.textWhite,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '$currency earned',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Segmented bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s8),
              child: SizedBox(
                height: 36,
                child: Row(
                  children: slices.asMap().entries.map((e) {
                    final color = _kChartColors[e.key % _kChartColors.length];
                    final pct = e.value.percentOfTotal.round();
                    return Expanded(
                      flex: pct.clamp(1, 100),
                      child: Container(
                        color: color,
                        alignment: Alignment.center,
                        child: Text(
                          '$pct%',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          // Product rows
          ...slices.asMap().entries.map((e) {
            final slice = e.value;
            final color = _kChartColors[e.key % _kChartColors.length];
            final name = (slice.name?.isNotEmpty ?? false)
                ? slice.name!
                : 'Product';
            return Column(
              children: [
                const Divider(
                  color: DesignTokens.borderDefault,
                  height: 1,
                  indent: DesignTokens.s16,
                  endIndent: DesignTokens.s16,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16,
                    vertical: DesignTokens.s12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: Text(
                          name,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Text(
                        '${slice.amount.currency} ${slice.amount.amount.toStringAsFixed(2)}',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Statistics section ────────────────────────────────────────────────────────

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection({
    required this.stats,
    required this.watchTimeMinutes,
  });

  final ReelStatistics stats;
  final int watchTimeMinutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                iconWidget: const _PercentIcon(),
                value: '${stats.conversionRate.toStringAsFixed(2)}%',
                label: 'Conversion Rate',
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: _StatCard(
                iconWidget: const Icon(
                  Icons.ads_click_rounded,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
                value: '${stats.clickThroughRate.toStringAsFixed(2)}%',
                label: 'Click Through Rate',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                iconWidget: const Icon(
                  Icons.remove_red_eye_outlined,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
                value: '${stats.completionRate.toStringAsFixed(2)}%',
                label: 'Completion Rate',
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: _StatCard(
                iconWidget: const Icon(
                  Icons.account_circle_outlined,
                  color: DesignTokens.textMuted,
                  size: 22,
                ),
                value: _compact(stats.uniqueViewersEstimate),
                label: 'Unique Viewers',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        _WatchTimeCard(minutes: watchTimeMinutes),
      ],
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(2)}k';
    return '$n';
  }
}

class _WatchTimeCard extends StatelessWidget {
  const _WatchTimeCard({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFF0A1F0F),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.timer_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: DesignTokens.s16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatMinutes(minutes)} minutes',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Watch Time',
                style: DesignTokens.smallRegular.copyWith(
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(2)}k';
    return '$n';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.iconWidget,
    required this.value,
    required this.label,
  });

  final Widget iconWidget;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.s12),
            ),
            alignment: Alignment.center,
            child: iconWidget,
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PercentIcon extends StatelessWidget {
  const _PercentIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '%',
      style: TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: DesignTokens.textMuted,
      ),
    );
  }
}

// ── Earnings overview chart ───────────────────────────────────────────────────

class _EarningsOverviewSection extends StatelessWidget {
  const _EarningsOverviewSection({required this.trend});

  final List<EarningsTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earnings Overview',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (trend.isEmpty)
          Text(
            'No earnings data for this period.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          )
        else
          Container(
            decoration: DesignTokens.cardDecoration(),
            padding: const EdgeInsets.fromLTRB(
              8,
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s12,
            ),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _EarningsLinePainter(trend: trend),
              ),
            ),
          ),
      ],
    );
  }
}

class _EarningsLinePainter extends CustomPainter {
  const _EarningsLinePainter({required this.trend});

  final List<EarningsTrendPoint> trend;

  static const _leftPad = 42.0;
  static const _bottomPad = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty) return;

    final data = trend.map((p) => p.amount.amount).toList();
    final maxVal = data.reduce(math.max) * 1.1;
    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad;

    final pts = List.generate(
      data.length,
      (i) => Offset(
        _leftPad + i * chartW / (data.length - 1).clamp(1, double.infinity),
        chartH - (maxVal > 0 ? (data[i] / maxVal) * chartH : 0),
      ),
    );

    // Area fill
    final areaPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      areaPath.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    areaPath
      ..lineTo(pts.last.dx, chartH)
      ..lineTo(pts.first.dx, chartH)
      ..close();
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignTokens.primaryGreen.withValues(alpha: 0.45),
            DesignTokens.primaryGreen.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(_leftPad, 0, chartW, chartH)),
    );

    // Line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      linePath.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = DesignTokens.primaryGreen
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Y-axis grid + labels
    const ySteps = 5;
    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= ySteps; i++) {
      final y = chartH - (i / ySteps) * chartH;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), gridPaint);
      final val = (maxVal * i / ySteps).round();
      // 0-decimal rounding can collapse adjacent gridlines onto the same
      // label (e.g. 1800 and 2400 both showing "2k") — fall back to 1
      // decimal whenever the value isn't a whole number of thousands.
      final label = val >= 1000
          ? (val % 1000 == 0
                ? '${val ~/ 1000}k'
                : '${(val / 1000).toStringAsFixed(1)}k')
          : '$val';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // X-axis labels (first and last)
    if (trend.length >= 2) {
      final xLabels = [
        DateFormat('MMM d').format(trend.first.date),
        DateFormat('MMM d').format(trend.last.date),
      ];
      final xPositions = [pts.first.dx, pts.last.dx];
      for (int i = 0; i < 2; i++) {
        final tp = TextPainter(
          text: TextSpan(
            text: xLabels[i],
            style: const TextStyle(
              color: DesignTokens.textMuted,
              fontSize: 9,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(xPositions[i] - tp.width / 2, chartH + 5));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsLinePainter old) => old.trend != trend;
}

// ── Audience demographic ──────────────────────────────────────────────────────

class _AudienceDemographicSection extends StatelessWidget {
  const _AudienceDemographicSection({required this.buckets});

  final List<AudienceAgeBucket> buckets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Audience Demographic',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'According to demographics according to age groups',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (buckets.isEmpty)
          Text(
            'No demographic data yet.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          )
        else
          Container(
            decoration: DesignTokens.cardDecoration(),
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      segments: buckets.asMap().entries.map((e) {
                        final color =
                            _kChartColors[e.key % _kChartColors.length];
                        return (e.value.percent / 100.0, color);
                      }).toList(),
                      strokeWidth: 30,
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                Wrap(
                  spacing: DesignTokens.s16,
                  runSpacing: DesignTokens.s8,
                  alignment: WrapAlignment.center,
                  children: buckets.asMap().entries.map((e) {
                    final color = _kChartColors[e.key % _kChartColors.length];
                    final label = e.value.ageRange ?? '?';
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$label  ${e.value.percent.toStringAsFixed(0)}%',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Gender distribution ───────────────────────────────────────────────────────

class _GenderDistributionSection extends StatelessWidget {
  const _GenderDistributionSection({required this.gender});

  final GenderDistribution gender;

  static const _colors = [
    Color(0xFF4DA6FF),
    Color(0xFF2ECC71),
    Color(0xFFAB8FF5),
  ];

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Female', _colors[0], gender.femalePercent),
      ('Male', _colors[1], gender.malePercent),
      ('Other', _colors[2], gender.otherPercent),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender Distribution Data',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.map((g) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: g.$2,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.s8),
                          Expanded(
                            child: Text(
                              g.$1,
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ),
                          Text(
                            '${g.$3.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.textWhite,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: DesignTokens.s16),
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutPainter(
                    segments: entries.map((g) => (g.$3 / 100.0, g.$2)).toList(),
                    strokeWidth: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Top locations ─────────────────────────────────────────────────────────────

class _TopLocationsSection extends StatelessWidget {
  const _TopLocationsSection({required this.locations});

  final List<AudienceLocation> locations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Locations',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Audience demographics according to different locations',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (locations.isEmpty)
          Text(
            'No location data yet.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          )
        else
          Container(
            decoration: DesignTokens.cardDecoration(),
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              children: [
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _DonutPainter(
                        segments: locations.asMap().entries.map((e) {
                          final color =
                              _kChartColors[e.key % _kChartColors.length];
                          return (e.value.percent / 100.0, color);
                        }).toList(),
                        strokeWidth: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                Wrap(
                  spacing: DesignTokens.s12,
                  runSpacing: DesignTokens.s8,
                  alignment: WrapAlignment.center,
                  children: locations.asMap().entries.map((e) {
                    final color = _kChartColors[e.key % _kChartColors.length];
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: DesignTokens.s4),
                        Text(
                          e.value.city ?? 'Unknown',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Shared donut chart painter ────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.segments, this.strokeWidth = 24});

  final List<(double, Color)> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;
    const gapAngle = 0.05;
    final totalGap = gapAngle * segments.length;
    final total = segments.fold(0.0, (s, e) => s + e.$1);
    if (total == 0) return;
    double startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (final seg in segments) {
      final sweep = (seg.$1 / total) * (2 * math.pi - totalGap);
      paint.color = seg.$2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.strokeWidth != strokeWidth;
}
