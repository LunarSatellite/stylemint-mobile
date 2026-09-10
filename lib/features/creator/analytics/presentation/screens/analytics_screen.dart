import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/earnings_trend_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/kpi_tile.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_product_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_reel_summary.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_dashboard_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_overview_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creatorDashboardNotifierProvider);
    final avatarPath = ref.watch(avatarImagePathProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      // ─── Bottom bar: custom button + nav ──────────────────────────────
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Custom "View Full Report" button – solid green, small radius
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              8, // space above
              DesignTokens.s16,
              8, // space below (between button and nav)
            ),
            child: _FullReportButton(),
          ),
          const _AnalyticsBottomNav(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, avatarPath),
            Expanded(
              child: state.when(
                initial: () => const _LoadingView(),
                loadInProgress: () => const _LoadingView(),
                loadSuccess: (dashboard) =>
                    _DashboardBody(dashboard: dashboard),
                loadFailure: (_) => _ErrorView(
                  onRetry: () => ref
                      .read(creatorDashboardNotifierProvider.notifier)
                      .fetch(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String? avatarPath) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 36,
              height: 36,
              child: avatarPath != null
                  ? Image.file(File(avatarPath), fit: BoxFit.cover)
                  : Container(
                      color: DesignTokens.bgAppBodyLight,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.person_rounded,
                        size: 20,
                        color: DesignTokens.textMuted,
                      ),
                    ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: DesignTokens.textWhite,
            ),
            onPressed: () => context.push(RouteNames.creatorSearch),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: DesignTokens.textWhite,
            ),
            onPressed: () => context.push(RouteNames.creatorActivity),
          ),
        ],
      ),
    );
  }
}

// ── Custom "View Full Report" button ─────────────────────────────────────────

class _FullReportButton extends StatelessWidget {
  const _FullReportButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.push(RouteNames.creatorFullAnalyticsReport),
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primaryGreen,
          foregroundColor: DesignTokens.buttonPrimaryText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              8,
            ), // small radius – rectangle with slight rounding
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'View Full Report',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_rounded,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading / error states ────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryGreen),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load analytics.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          ElevatedButton(
            onPressed: onRetry,
            style: DesignTokens.primaryButtonStyle(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard});
  final CreatorDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PerformanceOverview(dashboard: dashboard),
          const SizedBox(height: DesignTokens.s24),
          _TopReelsSection(topReels: dashboard.topReels),
          const SizedBox(height: DesignTokens.s24),
          const _EarningTrendSection(),
          const SizedBox(height: DesignTokens.s24),
          _TopProductsSection(topProducts: dashboard.topProducts),
        ],
      ),
    );
  }
}

// ── Performance Overview ──────────────────────────────────────────────────────

class _PerformanceOverview extends StatelessWidget {
  const _PerformanceOverview({required this.dashboard});
  final CreatorDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Overview (Last 30 Days)',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        _EarningsCard(tile: dashboard.totalEarnings),
        const SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(
              child: _SmallMetricCard(
                cardBg: const Color(0xFF7C3AED),
                iconBg: const Color(0xFF5B21B6),
                icon: Icons.shopping_bag_outlined,
                iconColor: Colors.white,
                label: 'Total Sales',
                value: _formatCount(dashboard.totalSales.current),
                delta: _formatDelta(dashboard.totalSales.deltaPercent),
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: _SmallMetricCard(
                cardBg: const Color(0xFF0891B2),
                iconBg: const Color(0xFF0E7490),
                icon: Icons.currency_exchange,
                iconColor: Colors.white,
                label: 'Conversion Rate',
                value:
                    '${dashboard.conversionRate.current.toStringAsFixed(1)}%',
                delta: _formatDelta(dashboard.conversionRate.deltaPercent),
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        _TotalViewsCard(tile: dashboard.totalViews),
      ],
    );
  }
}

class _EarningsCard extends StatelessWidget {
  const _EarningsCard({required this.tile});
  final KpiTile<Money> tile;

  @override
  Widget build(BuildContext context) {
    final delta = _formatDelta(tile.deltaPercent);
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      clipBehavior: Clip.antiAlias,
      decoration: DesignTokens.cardDecoration().copyWith(
        border: Border.all(color: DesignTokens.borderDefault, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Earnings',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatMoney(tile.current),
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      if (delta.isNotEmpty) ...[
                        const SizedBox(width: DesignTokens.s8),
                        _DeltaBadge(delta: delta),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s12),
            child: Image.asset(
              'assets/images/creatordash/money.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({
    required this.cardBg,
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.delta,
  });

  final Color cardBg;
  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: DesignTokens.s8),
              if (delta.isNotEmpty) _DeltaBadge(delta: delta),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: Colors.white.withValues(alpha: 0.60),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalViewsCard extends StatelessWidget {
  const _TotalViewsCard({required this.tile});
  final KpiTile<int> tile;

  @override
  Widget build(BuildContext context) {
    final delta = _formatDelta(tile.deltaPercent);
    return Container(
      height: 90,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1DB954), Color(0xFF0E8A3C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Views',
                    style: DesignTokens.smallRegular.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        _formatCount(tile.current),
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      if (delta.isNotEmpty) ...[
                        const SizedBox(width: DesignTokens.s8),
                        _DeltaBadge(delta: delta, onGreen: true),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            'assets/images/creatordash/hands.png',
            width: 130,
            height: 130,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ],
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({required this.delta, this.onGreen = false});

  final String delta;
  final bool onGreen;

  @override
  Widget build(BuildContext context) {
    if (delta.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: onGreen
            ? Colors.black.withValues(alpha: 0.20)
            : DesignTokens.primaryGreenDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        delta,
        style: DesignTokens.smallRegular.copyWith(
          color: onGreen ? DesignTokens.textWhite : DesignTokens.primaryGreen,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Top Performing Reels ──────────────────────────────────────────────────────

class _TopReelsSection extends StatelessWidget {
  const _TopReelsSection({required this.topReels});
  final List<TopReelSummary> topReels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Reels',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (topReels.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
              child: Text(
                'No reel data available.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          )
        else
          ...topReels.asMap().entries.map(
            (e) => Padding(
              padding: EdgeInsets.only(
                bottom: e.key < topReels.length - 1 ? DesignTokens.s12 : 0,
              ),
              child: _TopReelCard(reel: e.value),
            ),
          ),
      ],
    );
  }
}

class _TopReelCard extends StatefulWidget {
  const _TopReelCard({required this.reel});
  final TopReelSummary reel;

  @override
  State<_TopReelCard> createState() => _TopReelCardState();
}

class _TopReelCardState extends State<_TopReelCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final reel = widget.reel;
    final stats = [
      (Icons.play_circle_outline_rounded, _formatCount(reel.views)),
      (Icons.favorite_rounded, _formatCount(reel.likes)),
      (Icons.visibility_outlined, _formatCount(reel.impressions)),
      (Icons.share_outlined, _formatCount(reel.shares)),
      (Icons.chat_bubble_outline_rounded, _formatCount(reel.comments)),
      (Icons.shopping_bag_outlined, reel.sales.toString()),
    ];

    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.s8),
                child: reel.thumbnailUrl.isNotEmpty
                    ? Image.network(
                        reel.thumbnailUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _PlaceholderThumb(),
                      )
                    : const _PlaceholderThumb(),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel.title.isNotEmpty ? reel.title : 'Untitled Reel',
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
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      'Posted on: ${_formatPostedAt(reel.publishedAtUtc)}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push(
                  RouteNames.creatorReelAnalyticsDetail.replaceFirst(
                    ':reelId',
                    widget.reel.reelId,
                  ),
                ),
                child: const Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: DesignTokens.s12),
            const Divider(color: DesignTokens.borderDefault, height: 1),
            const SizedBox(height: DesignTokens.s12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stats
                  .map((s) => _StatItem(icon: s.$1, value: s.$2))
                  .toList(),
            ),
          ],
          const SizedBox(height: DesignTokens.s8),
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: DesignTokens.textMuted,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderThumb extends StatelessWidget {
  const _PlaceholderThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      color: DesignTokens.bgAppBodyLight,
      alignment: Alignment.center,
      child: const Icon(
        Icons.play_circle_outline_rounded,
        color: DesignTokens.textMuted,
        size: 28,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: DesignTokens.textLight),
        const SizedBox(height: 3),
        Text(
          value,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ── Earning Trend ─────────────────────────────────────────────────────────────

class _EarningTrendSection extends ConsumerWidget {
  const _EarningTrendSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewState = ref.watch(creatorOverviewNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earning Trend (Last 30 Days)',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s12,
          ),
          child: SizedBox(
            height: 200,
            child: overviewState.when(
              initial: () => const _ChartLoadingPlaceholder(),
              loadInProgress: () => const _ChartLoadingPlaceholder(),
              loadFailure: (_) => Center(
                child: Text(
                  'Could not load trend data.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ),
              loadSuccess: (overview) => overview.earningsTrend.isEmpty
                  ? Center(
                      child: Text(
                        'No trend data available.',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    )
                  : CustomPaint(
                      painter: _TrendChartPainter(overview.earningsTrend),
                      size: Size.infinite,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartLoadingPlaceholder extends StatelessWidget {
  const _ChartLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryGreen),
        strokeWidth: 2,
      ),
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter(this.points);

  final List<EarningsTrendPoint> points;

  static const _leftPad = 36.0;
  static const _bottomPad = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final amounts = points.map((p) => p.amount.amount).toList();
    if (amounts.isEmpty) return;

    final rawMax = amounts.reduce((a, b) => a > b ? a : b);
    final maxValue = rawMax > 0 ? rawMax * 1.1 : 1;

    const chartL = _leftPad;
    final chartW = size.width - chartL;
    final chartB = size.height - _bottomPad;
    final chartH = chartB;

    final gridPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 1;
    for (var i = 0; i <= 5; i++) {
      final y = chartB - i / 5 * chartH;
      canvas.drawLine(Offset(chartL, y), Offset(size.width, y), gridPaint);
    }

    for (var i = 0; i <= 5; i++) {
      final y = chartB - i / 5 * chartH;
      final tickValue = maxValue * i / 5;
      // 0-decimal rounding can collapse adjacent gridlines onto the same
      // label (e.g. 1800 and 2400 both showing "2k") — fall back to 1
      // decimal whenever the value isn't a whole number of thousands.
      final thousands = tickValue / 1000;
      final label = tickValue == 0
          ? '0'
          : tickValue >= 1000000
          ? '${(tickValue / 1000000).toStringAsFixed(1)}M'
          : tickValue >= 1000
          ? (thousands == thousands.roundToDouble()
                ? '${thousands.toStringAsFixed(0)}k'
                : '${thousands.toStringAsFixed(1)}k')
          // Same collision just below the 1000 threshold — fall
          // back to 1 decimal whenever the value isn't a whole
          // number, so adjacent gridlines stay visually distinct.
          : (tickValue == tickValue.roundToDouble()
                ? tickValue.toStringAsFixed(0)
                : tickValue.toStringAsFixed(1));
      _paintText(
        canvas,
        label,
        Offset(0, y - 6),
        _leftPad - 2,
        TextAlign.right,
      );
    }

    if (amounts.length < 2) return;

    final pts = <Offset>[];
    for (var i = 0; i < amounts.length; i++) {
      pts.add(
        Offset(
          chartL + i / (amounts.length - 1) * chartW,
          chartB - amounts[i] / maxValue * chartH,
        ),
      );
    }

    final areaPath = Path()..moveTo(pts.first.dx, chartB);
    _addBezier(areaPath, pts);
    areaPath
      ..lineTo(pts.last.dx, chartB)
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
        ).createShader(Rect.fromLTRB(chartL, 0, size.width, chartB))
        ..style = PaintingStyle.fill,
    );

    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    _addBezier(linePath, pts);

    canvas.drawPath(
      linePath,
      Paint()
        ..color = DesignTokens.primaryGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final labelIdxs = _labelIndices(points.length);
    for (final i in labelIdxs) {
      _paintText(
        canvas,
        _formatAxisDate(points[i].date),
        Offset(pts[i].dx - 22, chartB + 5),
        44,
        TextAlign.center,
      );
    }
  }

  List<int> _labelIndices(int count) {
    if (count <= 6) return List.generate(count, (i) => i);
    final step = (count - 1) / 5;
    return List.generate(6, (i) => (i * step).round());
  }

  String _formatAxisDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  void _addBezier(Path path, List<Offset> pts) {
    for (var i = 1; i < pts.length; i++) {
      final cpX = (pts[i - 1].dx + pts[i].dx) / 2;
      path.cubicTo(cpX, pts[i - 1].dy, cpX, pts[i].dy, pts[i].dx, pts[i].dy);
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    double maxWidth,
    TextAlign align,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF666666),
          fontSize: 10,
          fontFamily: DesignTokens.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_TrendChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

// ── Top Products ──────────────────────────────────────────────────────────────

class _TopProductsSection extends StatelessWidget {
  const _TopProductsSection({required this.topProducts});
  final List<TopProductSummary> topProducts;

  static const _accentColors = [
    Color(0xFFE74C3C),
    Color(0xFF3498DB),
    Color(0xFF2ECC71),
    Color(0xFFF39C12),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Products',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (topProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
            child: Center(
              child: Text(
                'No product data available.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          )
        else
          ...topProducts.asMap().entries.map((e) {
            final product = e.value;
            final accent = _accentColors[e.key % _accentColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s12),
              child: _TopProductItem(
                name: product.name.isNotEmpty ? product.name : 'Product',
                totalSales: product.totalSales,
                commission: _formatMoney(product.totalCommission),
                rate: '${product.commissionRatePercent.toStringAsFixed(1)}%',
                average: _formatMoney(product.avgCommissionPerSale),
                accentColor: accent,
                icon: Icons.inventory_2_outlined,
              ),
            );
          }),
      ],
    );
  }
}

class _TopProductItem extends StatelessWidget {
  const _TopProductItem({
    required this.name,
    required this.totalSales,
    required this.commission,
    required this.rate,
    required this.accentColor,
    required this.icon,
    this.average,
  });

  final String name;
  final int totalSales;
  final String commission;
  final String rate;
  final String? average;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DesignTokens.s8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                Text(
                  'Total Sales: $totalSales',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                const Divider(color: DesignTokens.borderDefault, height: 1),
                const SizedBox(height: DesignTokens.s8),
                _InfoRow(label: 'Total Commission', value: commission),
                const SizedBox(height: DesignTokens.s4),
                _InfoRow(label: '% Rate', value: rate),
                if (average != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  _InfoRow(label: 'Average', value: average!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _AnalyticsBottomNav extends ConsumerWidget {
  const _AnalyticsBottomNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountId = ref
        .watch(sessionControllerProvider)
        .maybeWhen(authenticated: (id) => id, orElse: () => '');
    return Container(
      height: 68 + MediaQuery.of(context).padding.bottom,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(
          top: BorderSide(color: DesignTokens.borderDefault, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBtn(
              iconWidget: const Icon(
                Icons.home_rounded,
                size: 22,
                color: DesignTokens.textMuted,
              ),
              label: 'Home',
              onTap: () => context.go(RouteNames.creatorHome),
            ),
            _NavBtn(
              iconWidget: Image.asset(
                'assets/images/creatordash/Analytics_Icon_green.png',
                width: 22,
                height: 22,
              ),
              label: 'Analytics',
              active: true,
              onTap: null,
            ),
            GestureDetector(
              onTap: () => context.push(RouteNames.reelImport),
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: DesignTokens.primaryGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  color: DesignTokens.buttonPrimaryText,
                  size: 26,
                ),
              ),
            ),
            _NavBtn(
              iconWidget: Image.asset(
                'assets/images/creatordash/Brand_Icon.png',
                width: 22,
                height: 22,
              ),
              label: 'Brands',
              onTap: () => context.push(RouteNames.partnerships),
            ),
            _NavBtn(
              iconWidget: const Icon(
                Icons.person_rounded,
                size: 22,
                color: DesignTokens.textMuted,
              ),
              label: 'Profile',
              onTap: () => context.push(
                RouteNames.creatorProfile.replaceFirst(':accountId', accountId),
                extra: CreatorProfileArgs(
                  accountId: accountId,
                  displayName: '',
                  handle: '',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.iconWidget,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final Widget iconWidget;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? DesignTokens.primaryGreen : DesignTokens.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────

String _formatMoney(Money money) {
  final amount = money.amount;
  final isWhole = amount == amount.truncateToDouble();
  final raw = isWhole ? amount.toInt().toString() : amount.toStringAsFixed(2);
  final parts = raw.split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
  return parts.length > 1 ? 'Rs. $intPart.${parts[1]}' : 'Rs. $intPart';
}

String _formatDelta(double? delta) {
  if (delta == null) return '';
  final sign = delta >= 0 ? '+' : '';
  return '$sign${delta.toStringAsFixed(0)}%';
}

String _formatCount(int count) {
  if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
  if (count >= 1000) return '${(count / 1000000).toStringAsFixed(1)}k';
  return count.toString();
}

String _formatPostedAt(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final min = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '${dt.day} ${months[dt.month - 1]}. ${dt.year} $hour:$min $ampm';
}
