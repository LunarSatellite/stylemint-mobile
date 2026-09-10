import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/entities/vendor_analytics_summary.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorAnalyticsScreen extends ConsumerWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsNotifierProvider);
    final summary = state.maybeWhen(
      loadSuccess: (value) => value,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: DesignTokens.textWhite,
            size: 18,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Analytics (30 days)',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: state.when(
              initial: () => const SizedBox.shrink(),
              loadInProgress: () => const Center(
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
              loadSuccess: (summary) => _AnalyticsBody(summary: summary),
              loadFailure: (_) => SmErrorView(
                message: 'Failed to load analytics.',
                onRetry: () =>
                    ref.read(analyticsNotifierProvider.notifier).load(),
              ),
            ),
          ),
          Container(
            color: DesignTokens.bgAppFoundation,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: summary == null ? null : () => _shareReport(summary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: const Icon(
                  Icons.download_outlined,
                  color: Colors.black,
                  size: 20,
                ),
                label: const Text(
                  'Download Full Report',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Trailing change-vs-previous-period badge (e.g. "+12%"), parenthesized
  /// only when present — an empty badge (no prior-period baseline yet, e.g.
  /// a brand-new vendor account) previously left a bare "()" on the line.
  static String _withBadge(String value, String badge) =>
      badge.isEmpty ? value : '$value ($badge)';

  void _shareReport(VendorAnalyticsSummary summary) {
    final overview = summary.revenueOverview;
    final lines = <String>[
      'Style Mint — Vendor Analytics (last 30 days)',
      '',
      'Gross sales: ${_withBadge('${overview.currency} ${overview.grossSales.toStringAsFixed(2)}', overview.grossSalesBadge)}',
      'Net revenue: ${_withBadge('${overview.currency} ${overview.netRevenue.toStringAsFixed(2)}', overview.netRevenueBadge)}',
      'Conversion rate: ${_withBadge('${overview.conversionRate.toStringAsFixed(2)}%', overview.conversionRateBadge)}',
      'Total orders: ${_withBadge('${overview.totalOrders}', overview.totalOrdersBadge)}',
      '',
      'Top products',
      ...summary.topProducts.map(
        (product) =>
            '${product.rank}. ${product.name} — ${product.unitsSold} sold, ${product.currency} ${product.price.toStringAsFixed(2)}',
      ),
      '',
      'Top creators',
      ...summary.topCreators.map(
        (creator) =>
            '${creator.rank}. ${creator.formattedHandle} — ${creator.currency} ${creator.attributedRevenue.toStringAsFixed(2)} from ${creator.distinctReelCount} reels',
      ),
      '',
      'Traffic sources',
      ...summary.trafficSources.map(
        (source) =>
            '${source.platform}: ${source.percentage.toStringAsFixed(1)}%',
      ),
    ];
    unawaited(SharePlus.instance.share(ShareParams(text: lines.join('\n'))));
  }
}

// ---------------------------------------------------------------------------
// Scrollable body — shown only when data is loaded
// ---------------------------------------------------------------------------

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.summary});

  final VendorAnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Overview (Last 30 Days)',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: 8),
          _RevenueOverviewCard(overview: summary.revenueOverview),
          const SizedBox(height: 12),
          _EarningsOverviewCard(points: summary.earningsPoints),
          const SizedBox(height: 12),
          _topProductsSection(context, summary.topProducts),
          const SizedBox(height: 12),
          _creatorPerformanceSection(context, summary.topCreators),
          const SizedBox(height: 12),
          _TrafficSourcesCard(sources: summary.trafficSources),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Revenue Overview
// ---------------------------------------------------------------------------

class _RevenueOverviewCard extends StatelessWidget {
  const _RevenueOverviewCard({required this.overview});

  final RevenueOverview overview;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricRow(
                  icon: 'assets/images/vendordashboard/icon_gross_sales.png',
                  iconBg: const Color(0xFF092A17),
                  label: 'Gross Sales',
                  badge: overview.grossSalesBadge,
                  value: 'Rs ${overview.grossSales.toStringAsFixed(2)}',
                  badgeColor: _badgeColor(overview.grossSalesBadge),
                ),
                const SizedBox(height: 14),
                _MetricRow(
                  icon: 'assets/images/vendordashboard/icon_net_revenue.png',
                  iconBg: const Color(0xFF052F4A),
                  label: 'Net Revenue',
                  badge: overview.netRevenueBadge,
                  value: 'Rs ${overview.netRevenue.toStringAsFixed(2)}',
                  badgeColor: _badgeColor(overview.netRevenueBadge),
                ),
                const SizedBox(height: 14),
                _MetricRow(
                  icon:
                      'assets/images/vendordashboard/icon_conversion_rate.png',
                  iconBg: const Color(0xFF3A2F03),
                  label: 'Conversion Rate',
                  badge: overview.conversionRateBadge,
                  value: '${overview.conversionRate.toStringAsFixed(1)}%',
                  badgeColor: _badgeColor(overview.conversionRateBadge),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2ECC71),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(DesignTokens.cardRadius),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Orders Completed',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            overview.totalOrders.toString(),
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_drop_up,
                            size: 18,
                            color: Colors.black87,
                          ),
                          Text(
                            overview.totalOrdersBadge,
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/vendordashboard/total order completed.png',
                  width: 72,
                  height: 72,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _badgeColor(String badge) {
    if (badge.startsWith('+')) return DesignTokens.primaryGreen;
    if (badge.startsWith('-')) return Colors.red;
    return const Color(0xFF9F9FA9);
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.badge,
    required this.value,
    required this.badgeColor,
  });

  final String icon;
  final Color iconBg;
  final String label;
  final String badge;
  final String value;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          color: iconBg,
          child: Image.asset(icon, fit: BoxFit.contain),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      color: DesignTokens.textLight,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Earnings Overview (line chart)
// ---------------------------------------------------------------------------

class _EarningsOverviewCard extends StatelessWidget {
  const _EarningsOverviewCard({required this.points});

  final List<EarningsPoint> points;

  @override
  Widget build(BuildContext context) {
    final values = points.map((p) => p.value).toList();
    final labels = points.map((p) => p.label).toList();
    final yMax = _computeYMax(values);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
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
          const SizedBox(height: 2),
          const Text(
            'Sales Trend Graph',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: values.isEmpty
                ? const Center(
                    child: Text(
                      'No data',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 12,
                        color: Color(0xFF9F9FA9),
                      ),
                    ),
                  )
                : _LineChart(points: values, xLabels: labels, yMax: yMax),
          ),
        ],
      ),
    );
  }

  double _computeYMax(List<double> pts) {
    if (pts.isEmpty) return 25000;
    final m = pts.fold<double>(0, (a, b) => a > b ? a : b);
    if (m <= 0) return 25000;
    const step = 5000.0;
    return (m / step).ceil() * step;
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.points,
    required this.xLabels,
    required this.yMax,
  });

  final List<double> points;
  final List<String> xLabels;
  final double yMax;

  @override
  Widget build(BuildContext context) {
    const ySteps = 5;
    const labelW = 32.0;
    const bottomH = 20.0;
    final yLabels = List.generate(ySteps + 1, (i) {
      final v = (yMax / ySteps) * i;
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
      return v.toStringAsFixed(0);
    });

    return Row(
      children: [
        SizedBox(
          width: labelW,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(ySteps + 1, (i) {
              return Text(
                yLabels[ySteps - i],
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 9,
                  color: Color(0xFF9F9FA9),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _ChartPainter(
                    points: points,
                    yMax: yMax,
                    ySteps: ySteps,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              SizedBox(
                height: bottomH,
                // A daily point per label (e.g. 30 for a 30-day window)
                // packed into one unconstrained Row overflows the chart's
                // width well before running out of points — show only
                // first/middle/last, same as the product analytics chart.
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(xLabels.length, (i) {
                    final show = i == 0 ||
                        i == xLabels.length - 1 ||
                        i == xLabels.length ~/ 2;
                    return Text(
                      show ? xLabels[i] : '',
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 9,
                        color: Color(0xFF9F9FA9),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({
    required this.points,
    required this.yMax,
    required this.ySteps,
  });

  final List<double> points;
  final double yMax;
  final int ySteps;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault
      ..strokeWidth = 0.5;
    for (var i = 0; i <= ySteps; i++) {
      final y = h - (i / ySteps) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    Offset toOffset(int i) {
      final x = (i / (points.length - 1)) * w;
      final y = h - (points[i] / yMax) * h;
      return Offset(x, y);
    }

    final offsets = List.generate(points.length, toOffset);

    final fillPath = Path()..moveTo(offsets.first.dx, h);
    for (final o in offsets) {
      fillPath.lineTo(o.dx, o.dy);
    }
    fillPath
      ..lineTo(offsets.last.dx, h)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          DesignTokens.primaryGreen.withValues(alpha: 0.3),
          DesignTokens.primaryGreen.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = DesignTokens.primaryGreen
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      final prev = offsets[i - 1];
      final curr = offsets[i];
      final cpx = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = DesignTokens.primaryGreen;
    final dotBg = Paint()..color = DesignTokens.bgAppBodyLight;
    for (final o in offsets) {
      canvas
        ..drawCircle(o, 4, dotBg)
        ..drawCircle(o, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Top Products
// ---------------------------------------------------------------------------

Widget _topProductsSection(BuildContext context, List<TopProduct> products) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Top Products',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: DesignTokens.textLight,
            ),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.vendorTopProducts),
            child: const Text(
              'View All',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Column(
          children: products.asMap().entries.map((e) {
            final isLast = e.key == products.length - 1;
            return Column(
              children: [
                _ProductRow(product: e.value),
                if (!isLast)
                  const Divider(
                    height: 1,
                    color: DesignTokens.borderDefault,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final TopProduct product;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(
            '${product.rank}',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9F9FA9),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rs ${product.price.toStringAsFixed(0)}'
                  '  •  ${product.unitsSold} sales',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 11,
                    color: Color(0xFF9F9FA9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 56,
    height: 56,
    color: const Color(0xFF2C2C2E),
    child: const Icon(
      Icons.inventory_2_outlined,
      color: Color(0xFF9F9FA9),
      size: 24,
    ),
  );
}

// ---------------------------------------------------------------------------
// Creator Performance
// ---------------------------------------------------------------------------

Widget _creatorPerformanceSection(
  BuildContext context,
  List<TopCreatorSummary> creators,
) {
  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Creator Performance',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: DesignTokens.textLight,
            ),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.vendorCreatorPerformance),
            child: const Text(
              'View All',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Column(
          children: creators.asMap().entries.map((e) {
            final isLast = e.key == creators.length - 1;
            return Column(
              children: [
                _CreatorRow(creator: e.value),
                if (!isLast)
                  const Divider(
                    height: 1,
                    color: DesignTokens.borderDefault,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    ],
  );
}

class _CreatorRow extends StatelessWidget {
  const _CreatorRow({required this.creator});

  final TopCreatorSummary creator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Text(
            '${creator.rank}',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9F9FA9),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2C2C2E),
            child: Text(
              creator.avatarInitial,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  creator.formattedHandle,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rs ${creator.attributedRevenue.toStringAsFixed(0)}'
                  '  •  ${creator.distinctReelCount} reels',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 11,
                    color: Color(0xFF9F9FA9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Traffic Sources
// ---------------------------------------------------------------------------

class _TrafficSourcesCard extends StatelessWidget {
  const _TrafficSourcesCard({required this.sources});

  final List<TrafficSource> sources;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Traffic Sources',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: 12),
          if (sources.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No traffic data yet',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  color: DesignTokens.textMuted,
                ),
              ),
            )
          else
            Row(
              children: [
                for (int i = 0; i < sources.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: _buildTile(sources[i])),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTile(TrafficSource source) {
    final (icon, label, color) = _sourceMeta(source.platform);
    return _TrafficTile(
      icon: icon,
      label: label,
      percent: '${source.percentage.toStringAsFixed(0)}%',
      color: color,
    );
  }

  (String, String, Color) _sourceMeta(String platform) {
    return switch (platform.toLowerCase()) {
      'youtube' => (
        'assets/icons/youtube.svg',
        'Youtube\nShorts',
        const Color(0xFFFF0000),
      ),
      'instagram' => (
        'assets/icons/instagram.svg',
        'Instagram\nReels',
        const Color(0xFFE1306C),
      ),
      _ => (
        'assets/icons/tiktok.svg',
        platform,
        DesignTokens.textWhite,
      ),
    };
  }
}

class _TrafficTile extends StatelessWidget {
  const _TrafficTile({
    required this.icon,
    required this.label,
    required this.percent,
    required this.color,
  });

  final String icon;
  final String label;
  final String percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          SvgPicture.asset(icon, width: 32, height: 32),
          const SizedBox(height: 8),
          Text(
            percent,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 11,
              color: Color(0xFF9F9FA9),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
