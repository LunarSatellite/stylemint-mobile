import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_age_bucket.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/audience_location.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/best_posting_window.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/content_performance_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/conversion_funnel.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/conversion_metrics.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/earnings_trend_point.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/full_analytics_report.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/gender_distribution.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/domain/entities/top_product.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/presentation/notifiers/creator_full_report_notifier.dart';
import 'package:stylemint_mobile_frontend/features/creator/analytics/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FullAnalyticsReportScreen extends ConsumerWidget {
  const FullAnalyticsReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creatorFullReportNotifierProvider);
    final report = state.maybeWhen(
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
        title: const Text(
          'Full Analytics Report',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.bookmark_border_rounded,
              color: DesignTokens.textWhite,
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Saving reports is coming soon.'),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: DesignTokens.textWhite,
            ),
            tooltip: 'Share report',
            onPressed: report == null ? null : () => _shareReport(report),
          ),
        ],
      ),
      body: state.when(
        initial: () => const SizedBox.shrink(),
        loadInProgress: () => const Center(child: CircularProgressIndicator()),
        loadFailure: (failure) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load report',
                style: DesignTokens.mediumRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              TextButton(
                onPressed: () => ref
                    .read(creatorFullReportNotifierProvider.notifier)
                    .fetch(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        loadSuccess: (FullAnalyticsReport report) =>
            _ReportBody(report: report),
      ),
    );
  }
}

void _shareReport(FullAnalyticsReport report) {
  final totalEarnings = report.earningsTrend.fold<double>(
    0,
    (sum, point) => sum + point.amount.amount,
  );
  final topProducts = report.topProducts
      .take(3)
      .map(
        (product) =>
            '${product.name ?? product.productId}: ${product.totalSales} sales',
      )
      .join('\n');
  final earnings = Money(
    amount: totalEarnings,
    currency: report.earningsTrend.isEmpty
        ? 'NPR'
        : report.earningsTrend.first.amount.currency,
  );
  final lines = <String>[
    'Style Mint creator analytics report',
    'Period: ${DateFormat.yMMMd().format(report.window.fromUtc)} – '
        '${DateFormat.yMMMd().format(report.window.toUtc)}',
    'Earnings: ${formatMoney(earnings)}',
    'Clicks: ${report.conversionMetrics.totalClicks}',
    'Orders: ${report.conversionMetrics.totalOrders}',
    'Conversion: ${report.conversionMetrics.conversionRate.toStringAsFixed(2)}%',
    'Average order value: ${formatMoney(report.conversionMetrics.averageOrderValue)}',
    if (topProducts.isNotEmpty) 'Top products:\n$topProducts',
  ];
  unawaited(SharePlus.instance.share(ShareParams(text: lines.join('\n'))));
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final FullAnalyticsReport report;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    final dateLabel =
        '${fmt.format(report.window.fromUtc)} – ${fmt.format(report.window.toUtc)}, ${report.window.toUtc.year}';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: DesignTokens.s16,
              top: DesignTokens.s8,
            ),
            child: Text(
              'Date Range: $dateLabel',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DesignTokens.textLight,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          const _FilterChipsRow(),
          const SizedBox(height: DesignTokens.s16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EarningsOverviewSection(trend: report.earningsTrend),
                const SizedBox(height: DesignTokens.s24),
                _ContentPerformanceSection(
                  performance: report.contentPerformance,
                ),
                const SizedBox(height: DesignTokens.s24),
                _ConversionMetricsSection(metrics: report.conversionMetrics),
                const SizedBox(height: DesignTokens.s24),
                _ConversionFunnelSection(funnel: report.conversionFunnel),
                const SizedBox(height: DesignTokens.s24),
                _AudienceDemographicSection(
                  buckets: report.audienceDemographic,
                ),
                const SizedBox(height: DesignTokens.s24),
                _BestPostingTimesSection(windows: report.bestPostingTimes),
                const SizedBox(height: DesignTokens.s24),
                _GenderDistributionSection(gender: report.genderDistribution),
                const SizedBox(height: DesignTokens.s24),
                _TopEarningProductsSection(products: report.topProducts),
                const SizedBox(height: DesignTokens.s24),
                _TopLocationsSection(locations: report.topLocations),
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
  const _FilterChipsRow();

  static const _chips = [
    (Icons.calendar_today_rounded, 'Custom Date', false),
    (null, 'Last 7 days', true),
    (null, 'Last 30 days', false),
    (null, 'Last 90 days', false),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: _chips.map((c) {
          final icon = c.$1;
          final label = c.$2;
          final selected = c.$3;
          return Container(
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
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 13,
                    color: selected
                        ? DesignTokens.primaryGreen
                        : DesignTokens.textMuted,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected
                        ? DesignTokens.primaryGreen
                        : DesignTokens.textLight,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section header helper ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      ],
    );
  }
}

// ── Section 1: Earnings Overview ─────────────────────────────────────────────

class _EarningsOverviewSection extends StatelessWidget {
  const _EarningsOverviewSection({required this.trend});

  final List<EarningsTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Earnings Overview',
          subtitle: 'Earnings over the selected period',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s12,
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: trend.isEmpty
                ? const Center(
                    child: Text(
                      'No earnings data yet',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _EarningsLinePainter(trend: trend),
                  ),
          ),
        ),
      ],
    );
  }
}

class _EarningsLinePainter extends CustomPainter {
  _EarningsLinePainter({required this.trend});

  final List<EarningsTrendPoint> trend;

  static const _leftPad = 38.0;
  static const _bottomPad = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final amounts = trend.map((p) => p.amount.amount).toList(growable: false);
    final maxVal = amounts.reduce(math.max).clamp(1.0, double.infinity);

    final fmt = DateFormat('MMM d');
    final xLabels = trend
        .map((p) => fmt.format(p.date))
        .toList(growable: false);

    final yMax = (maxVal * 1.1).ceilToDouble();
    final yLabels = List.generate(
      6,
      (i) => _formatYLabel((yMax * i / 5).roundToDouble()),
    );

    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad;

    final pts = List.generate(
      amounts.length,
      (i) => Offset(
        _leftPad + i * chartW / (amounts.length - 1),
        chartH - (amounts[i] / yMax) * chartH,
      ),
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < yLabels.length; i++) {
      final y = chartH - (i / (yLabels.length - 1)) * chartH;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), gridPaint);
    }

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

    // Y-axis labels
    for (int i = 0; i < yLabels.length; i++) {
      final y = chartH - (i / (yLabels.length - 1)) * chartH;
      _drawLabel(canvas, yLabels[i], Offset(0, y));
    }

    // X-axis labels — show at most 6 evenly spaced
    final step = (xLabels.length / math.min(xLabels.length, 6)).ceil();
    for (int i = 0; i < xLabels.length; i += step) {
      final x = _leftPad + i * chartW / (xLabels.length - 1);
      _drawLabel(canvas, xLabels[i], Offset(x, chartH + 5), centerX: true);
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    bool centerX = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: DesignTokens.textMuted,
          fontSize: 9,
          fontFamily: DesignTokens.fontFamily,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        centerX ? offset.dx - tp.width / 2 : offset.dx,
        offset.dy - tp.height / 2,
      ),
    );
  }

  String _formatYLabel(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    // 0-decimal rounding can collapse adjacent gridlines onto the same
    // label (e.g. 1800 and 2400 both showing "2k") — fall back to 1
    // decimal whenever the value isn't a whole number of thousands.
    if (v >= 1000) {
      final thousands = v / 1000;
      return thousands == thousands.roundToDouble()
          ? '${thousands.toStringAsFixed(0)}k'
          : '${thousands.toStringAsFixed(1)}k';
    }
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _EarningsLinePainter old) => old.trend != trend;
}

// ── Section 2: Content Performance ───────────────────────────────────────────

class _ContentPerformanceSection extends StatelessWidget {
  const _ContentPerformanceSection({required this.performance});

  final List<ContentPerformancePoint> performance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Content Performance',
          subtitle: 'Earnings per reel for the selected period',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s12,
            DesignTokens.s12,
          ),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: performance.isEmpty
                ? const Center(
                    child: Text(
                      'No content data yet',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _BarChartPainter(performance: performance),
                  ),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.performance});

  final List<ContentPerformancePoint> performance;

  static const _leftPad = 38.0;
  static const _bottomPad = 22.0;
  static const _barColor = Color(0xFF4DA6FF);

  @override
  void paint(Canvas canvas, Size size) {
    final barData = performance
        .map((p) => p.earnings.amount)
        .toList(growable: false);
    final maxVal = barData.reduce(math.max).clamp(1.0, double.infinity) * 1.1;

    final yLabels = List.generate(
      8,
      (i) => _formatYLabel((maxVal * i / 7).roundToDouble()),
    );
    final xLabels = List.generate(
      performance.length,
      (i) => 'R${i + 1}',
    );

    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad;

    // Grid lines
    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < yLabels.length; i++) {
      final y = chartH - (i / (yLabels.length - 1)) * chartH;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), gridPaint);
    }

    // Y-axis labels
    for (int i = 0; i < yLabels.length; i++) {
      final y = chartH - (i / (yLabels.length - 1)) * chartH;
      final tp = TextPainter(
        text: TextSpan(
          text: yLabels[i],
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

    // Bars
    final count = barData.length;
    final slotW = chartW / count;
    final barW = slotW * 0.6;
    const radius = Radius.circular(3);
    final barPaint = Paint()..color = _barColor;

    for (int i = 0; i < count; i++) {
      final barH = (barData[i] / maxVal) * chartH;
      final left = _leftPad + i * slotW + (slotW - barW) / 2;
      final top = chartH - barH;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(left, top, barW, barH),
          topLeft: radius,
          topRight: radius,
        ),
        barPaint,
      );

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
      tp.paint(canvas, Offset(left + barW / 2 - tp.width / 2, chartH + 5));
    }
  }

  String _formatYLabel(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    // 0-decimal rounding can collapse adjacent gridlines onto the same
    // label (e.g. 1800 and 2400 both showing "2k") — fall back to 1
    // decimal whenever the value isn't a whole number of thousands.
    if (v >= 1000) {
      final thousands = v / 1000;
      return thousands == thousands.roundToDouble()
          ? '${thousands.toStringAsFixed(0)}k'
          : '${thousands.toStringAsFixed(1)}k';
    }
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.performance != performance;
}

// ── Section 3: Conversion Metrics ────────────────────────────────────────────

class _ConversionMetricsSection extends StatelessWidget {
  const _ConversionMetricsSection({required this.metrics});

  final ConversionMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Image.asset(
              'assets/images/creatordash/material-symbols_touch-app-outline-rounded.png',
              width: 22,
              height: 22,
              color: DesignTokens.textMuted,
            )
            as Widget,
        NumberFormat.compact().format(metrics.totalClicks),
        'Total Clicks',
      ),
      (
        Image.asset(
              'assets/images/creatordash/box-outline-rounded.png',
              width: 22,
              height: 22,
              color: DesignTokens.textMuted,
            )
            as Widget,
        metrics.totalOrders.toString(),
        'Total Orders',
      ),
      (
        const Icon(
              Icons.currency_exchange,
              color: DesignTokens.textMuted,
              size: 22,
            )
            as Widget,
        '${metrics.conversionRate.toStringAsFixed(2)}%',
        'Conversion Rate',
      ),
      (
        Image.asset(
              'assets/images/creatordash/universal-currency.png',
              width: 22,
              height: 22,
              color: DesignTokens.textMuted,
            )
            as Widget,
        formatMoney(metrics.averageOrderValue),
        'Avg. Order Value',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conversion Metrics',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        _MetricGrid(metrics: items),
      ],
    );
  }
}

// ── Section 4: Conversion Funnel ─────────────────────────────────────────────

class _ConversionFunnelSection extends StatelessWidget {
  const _ConversionFunnelSection({required this.funnel});

  final ConversionFunnel funnel;

  @override
  Widget build(BuildContext context) {
    String label(int count, double pct) =>
        '${NumberFormat.compact().format(count)} (${pct.toStringAsFixed(1)}%)';

    final items = [
      (
        const Icon(
              Icons.remove_red_eye_outlined,
              color: DesignTokens.textMuted,
              size: 22,
            )
            as Widget,
        label(funnel.views.count, funnel.views.percentOfTop),
        'Viewed Reel',
      ),
      (
        Image.asset(
              'assets/images/creatordash/material-symbols_package-2-outline.png',
              width: 22,
              height: 22,
              color: DesignTokens.textMuted,
            )
            as Widget,
        label(funnel.clicks.count, funnel.clicks.percentOfTop),
        'Clicked Product',
      ),
      (
        const Icon(
              Icons.shopping_cart_outlined,
              color: DesignTokens.textMuted,
              size: 22,
            )
            as Widget,
        label(funnel.addedToCart.count, funnel.addedToCart.percentOfTop),
        'Added Cart',
      ),
      (
        const Icon(
              Icons.shopping_bag_outlined,
              color: DesignTokens.textMuted,
              size: 22,
            )
            as Widget,
        label(funnel.orders.count, funnel.orders.percentOfTop),
        'Completed Order',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Conversion Funnel',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        _MetricGrid(metrics: items),
      ],
    );
  }
}

// ── Shared 2×2 metric grid ────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<(Widget, String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                iconWidget: metrics[0].$1,
                value: metrics[0].$2,
                label: metrics[0].$3,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: _MetricCard(
                iconWidget: metrics[1].$1,
                value: metrics[1].$2,
                label: metrics[1].$3,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                iconWidget: metrics[2].$1,
                value: metrics[2].$2,
                label: metrics[2].$3,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: _MetricCard(
                iconWidget: metrics[3].$1,
                value: metrics[3].$2,
                label: metrics[3].$3,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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

// ── Section 5: Audience Demographic ──────────────────────────────────────────

class _AudienceDemographicSection extends StatelessWidget {
  const _AudienceDemographicSection({required this.buckets});

  final List<AudienceAgeBucket> buckets;

  static const _palette = [
    Color(0xFFFF9800),
    Color(0xFF4DA6FF),
    Color(0xFF2ECC71),
    Color(0xFFFFD93D),
    Color(0xFFFF6B6B),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Audience Demographic',
          subtitle: 'Audience breakdown by age group',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: buckets.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
                    child: Text(
                      'No audience data yet',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: _DonutLabelsPainter(
                            segments: List.generate(
                              buckets.length,
                              (i) => (
                                buckets[i].percent / 100,
                                _palette[i % _palette.length],
                                '${buckets[i].percent.toStringAsFixed(0)}%',
                              ),
                            ),
                            strokeWidth: 52,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    Wrap(
                      spacing: DesignTokens.s16,
                      runSpacing: DesignTokens.s8,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        buckets.length,
                        (i) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _palette[i % _palette.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              buckets[i].ageRange ?? '?',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
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

// ── Section 6: Best Posting Times ────────────────────────────────────────────

class _BestPostingTimesSection extends StatelessWidget {
  const _BestPostingTimesSection({required this.windows});

  final List<BestPostingWindow> windows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreen,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Best Posting Times',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Optimal windows for your audience',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s16),
              SizedBox(
                width: 72,
                height: 72,
                child: OverflowBox(
                  maxWidth: 120,
                  maxHeight: 120,
                  child: Image.asset(
                    'assets/images/creatordash/best_posting_times.png',
                    width: 120,
                    height: 120,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (windows.isEmpty)
          Container(
            decoration: DesignTokens.cardDecoration(),
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: const Center(
              child: Text(
                'No posting time data yet',
                style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
              ),
            ),
          )
        else
          Container(
            decoration: DesignTokens.cardDecoration(),
            child: Column(
              children: List.generate(windows.length, (i) {
                final w = windows[i];
                final label = w.dayOfWeekLabel ?? '';
                final time = '${w.startHourLocal}:00–${w.endHourLocal}:00';
                final subtitle = w.annotation ?? time;
                return Column(
                  children: [
                    _PostingTimeRow(day: '$label : $time', subtitle: subtitle),
                    if (i < windows.length - 1)
                      const Divider(
                        color: DesignTokens.borderDefault,
                        height: 1,
                        indent: DesignTokens.s16,
                        endIndent: DesignTokens.s16,
                      ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _PostingTimeRow extends StatelessWidget {
  const _PostingTimeRow({required this.day, required this.subtitle});

  final String day;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.schedule_rounded,
              color: DesignTokens.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
              Text(
                subtitle,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section 7: Gender Distribution ───────────────────────────────────────────

class _GenderDistributionSection extends StatelessWidget {
  const _GenderDistributionSection({required this.gender});

  final GenderDistribution gender;

  static const _blue = Color(0xFF4DA6FF);
  static const _green = Color(0xFF2ECC71);
  static const _yellow = Color(0xFFFFD93D);

  @override
  Widget build(BuildContext context) {
    final female = gender.femalePercent.round();
    final male = gender.malePercent.round();
    final other = gender.otherPercent.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Gender Distribution Data',
          subtitle: 'Audience breakdown by gender',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s16,
                  DesignTokens.s16,
                  0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        if (female > 0)
                          Expanded(
                            flex: female,
                            child: Container(
                              color: _blue,
                              alignment: Alignment.center,
                              child: Text(
                                '$female%',
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (male > 0)
                          Expanded(
                            flex: male,
                            child: Container(
                              color: _green,
                              alignment: Alignment.center,
                              child: Text(
                                '$male%',
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (other > 0)
                          Expanded(
                            flex: other,
                            child: Container(
                              color: _yellow,
                              alignment: Alignment.center,
                              child: Text(
                                '$other%',
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              _GenderRow(color: _blue, label: 'Female', pct: '$female%'),
              _GenderRow(color: _green, label: 'Male', pct: '$male%'),
              _GenderRow(color: _yellow, label: 'Others', pct: '$other%'),
              const SizedBox(height: DesignTokens.s12),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenderRow extends StatelessWidget {
  const _GenderRow({
    required this.color,
    required this.label,
    required this.pct,
  });

  final Color color;
  final String label;
  final String pct;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s8,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Text(
              label,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ),
          Text(
            pct,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section 8: Top 5 Earning Products ────────────────────────────────────────

class _TopEarningProductsSection extends StatelessWidget {
  const _TopEarningProductsSection({required this.products});

  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top 5 Earning Products',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (products.isEmpty)
          const Text(
            'No products yet',
            style: TextStyle(color: DesignTokens.textMuted, fontSize: 13),
          )
        else
          ...List.generate(products.length, (i) {
            final p = products[i];
            final isLast = i == products.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: DesignTokens.s12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: p.thumbnailUrl != null
                            ? Image.network(
                                p.thumbnailUrl!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _ProductPlaceholder(index: i),
                              )
                            : _ProductPlaceholder(index: i),
                      ),
                      const SizedBox(width: DesignTokens.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name ?? 'Product',
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
                            const SizedBox(height: 4),
                            Text(
                              '${formatMoney(p.totalCommission)} · ${p.totalSales} sales',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(color: DesignTokens.borderDefault, height: 1),
              ],
            );
          }),
      ],
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder({required this.index});

  final int index;

  static const _colors = [
    Color(0xFF2A2A2A),
    Color(0xFFB71C1C),
    Color(0xFFE65100),
    Color(0xFF37474F),
    Color(0xFF0D47A1),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      color: _colors[index % _colors.length],
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Colors.white38,
        size: 28,
      ),
    );
  }
}

// ── Section 9: Top Locations ──────────────────────────────────────────────────

class _TopLocationsSection extends StatelessWidget {
  const _TopLocationsSection({required this.locations});

  final List<AudienceLocation> locations;

  static const _palette = [
    Color(0xFF4DA6FF),
    Color(0xFFFFD93D),
    Color(0xFFFF6B6B),
    Color(0xFFFF8C42),
    Color(0xFF2ECC71),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Top Locations',
          subtitle: 'Audience breakdown by city',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: locations.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: DesignTokens.s24),
                    child: Text(
                      'No location data yet',
                      style: TextStyle(
                        color: DesignTokens.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: _DonutLabelsPainter(
                            segments: List.generate(
                              locations.length,
                              (i) => (
                                locations[i].percent / 100,
                                _palette[i % _palette.length],
                                '${locations[i].percent.toStringAsFixed(0)}%',
                              ),
                            ),
                            strokeWidth: 52,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    Wrap(
                      spacing: DesignTokens.s16,
                      runSpacing: DesignTokens.s8,
                      alignment: WrapAlignment.center,
                      children: List.generate(
                        locations.length,
                        (i) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _palette[i % _palette.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              locations[i].city ?? 'Unknown',
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
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

// ── Donut painter with text labels on arc ─────────────────────────────────────

class _DonutLabelsPainter extends CustomPainter {
  const _DonutLabelsPainter({required this.segments, this.strokeWidth = 52});

  final List<(double, Color, String)> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2 - 2;
    const gap = 0.04;
    final totalGap = gap * segments.length;
    final total = segments.fold(0.0, (s, e) => s + e.$1);
    double startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (final seg in segments) {
      final sweep = (seg.$1 / total) * (2 * math.pi - totalGap);
      final midAngle = startAngle + sweep / 2;
      paint.color = seg.$2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      if (sweep > 0.2) {
        final lx = center.dx + radius * math.cos(midAngle);
        final ly = center.dy + radius * math.sin(midAngle);
        final tp = TextPainter(
          text: TextSpan(
            text: seg.$3,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutLabelsPainter old) =>
      old.segments != segments;
}
