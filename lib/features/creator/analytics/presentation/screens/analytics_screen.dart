import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/presentation/creator_profile_screen.dart';
import 'package:stylemint_mobile_frontend/features/social/creator_profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      bottomNavigationBar: const _AnalyticsBottomNav(),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s16,
                  DesignTokens.s8,
                  DesignTokens.s16,
                  DesignTokens.s32,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PerformanceOverview(),
                    SizedBox(height: DesignTokens.s24),
                    _TopReelsSection(),
                    SizedBox(height: DesignTokens.s24),
                    _EarningTrendSection(),
                    SizedBox(height: DesignTokens.s24),
                    _TopProductsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: [
          Consumer(
            builder: (_, ref, __) {
              final path = ref.watch(avatarImagePathProvider);
              return ClipOval(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: path != null
                      ? Image.file(File(path), fit: BoxFit.cover)
                      : Container(
                          color: DesignTokens.bgAppBodyLight,
                          alignment: Alignment.center,
                          child: const Icon(Icons.person_rounded,
                              size: 20, color: DesignTokens.textMuted),
                        ),
                ),
              );
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: DesignTokens.textWhite),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: DesignTokens.textWhite),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ── Performance Overview ──────────────────────────────────────────────────────

class _PerformanceOverview extends StatelessWidget {
  const _PerformanceOverview();

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
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),

        // Total Earnings — full width
        _EarningsCard(),
        const SizedBox(height: DesignTokens.s12),

        // Sales + Conversion — side by side
        Row(
          children: [
            Expanded(child: _SmallMetricCard(
              cardBg: const Color(0xFF2D1A5E),
              iconBg: const Color(0xFF3D2870),
              icon: Icons.shopping_bag_outlined,
              iconColor: const Color(0xFFAB8FF5),
              label: 'Total Sales',
              value: '109',
              delta: '+36%',
            )),
            const SizedBox(width: DesignTokens.s12),
            Expanded(child: _SmallMetricCard(
              cardBg: const Color(0xFF0D2D3A),
              iconBg: const Color(0xFF1A3D4A),
              icon: Icons.sync_rounded,
              iconColor: const Color(0xFF4DA6FF),
              label: 'Conversion Rate',
              value: '3.2%',
              delta: '+25%',
            )),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),

        // Total Views — full width
        _TotalViewsCard(),
      ],
    );
  }
}

class _EarningsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      clipBehavior: Clip.antiAlias,
      decoration: DesignTokens.cardDecoration(),
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
                      const Text(
                        'Rs. 52,625',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      _DeltaBadge(delta: '+25%'),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: DesignTokens.s8),
              _DeltaBadge(delta: delta),
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
  @override
  Widget build(BuildContext context) {
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
                      const Text(
                        '33,981',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      _DeltaBadge(delta: '+14%', onGreen: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Image.asset(
            'assets/images/creatordash/hands.png',
            width: 90,
            height: 90,
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
  const _TopReelsSection();

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
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        _TopReelCard(
          title: 'Mheecha: The Bag that Matches Your Aesthetics',
          postedAt: '7 Aug. 2025 09:57 PM',
          stats: const [
            (Icons.play_circle_outline_rounded, '25.76k'),
            (Icons.favorite_rounded, '23.8k'),
            (Icons.visibility_outlined, '465k'),
            (Icons.bookmark_border_rounded, '1.8k'),
            (Icons.share_outlined, '13.67k'),
            (Icons.chat_bubble_outline_rounded, '976'),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        _TopReelCard(
          title: 'Nike Structure 26 – Be the Trail Blazzer Runner',
          postedAt: '7 Aug. 2025 09:57 PM',
          stats: const [
            (Icons.play_circle_outline_rounded, '800.25'),
            (Icons.favorite_rounded, '23.8k'),
            (Icons.visibility_outlined, '465k'),
            (Icons.bookmark_border_rounded, '1.8k'),
            (Icons.share_outlined, '13.67k'),
            (Icons.chat_bubble_outline_rounded, '976'),
          ],
        ),
      ],
    );
  }
}

class _TopReelCard extends StatefulWidget {
  const _TopReelCard({
    required this.title,
    required this.postedAt,
    required this.stats,
  });

  final String title;
  final String postedAt;
  final List<(IconData, String)> stats;

  static void _openDetail(BuildContext context) =>
      context.push(RouteNames.creatorReelAnalyticsDetail);

  @override
  State<_TopReelCard> createState() => _TopReelCardState();
}

class _TopReelCardState extends State<_TopReelCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.s8),
                child: Container(
                  width: 72,
                  height: 72,
                  color: DesignTokens.bgAppBodyLight,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: DesignTokens.textMuted,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
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
                      'Posted on: ${widget.postedAt}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _TopReelCard._openDetail(context),
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
              children: widget.stats.map((s) => _StatItem(icon: s.$1, value: s.$2)).toList(),
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

class _EarningTrendSection extends StatelessWidget {
  const _EarningTrendSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Earning Trend (Last 30 Days)',
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
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s8,
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s12,
          ),
          child: SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _TrendChartPainter(),
              size: Size.infinite,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  static const _data = [4200.0, 8800.0, 16500.0, 11000.0, 20000.0, 24500.0];
  static const _maxValue = 25000.0;
  static const _leftPad = 36.0;
  static const _bottomPad = 22.0;
  static const _xLabels = ['Dec 1', 'Dec 7', 'Dec 14', 'Dec 21', 'Dec 28', 'Today'];

  @override
  void paint(Canvas canvas, Size size) {
    final chartL = _leftPad;
    final chartW = size.width - chartL;
    final chartB = size.height - _bottomPad;
    final chartH = chartB;

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..strokeWidth = 1;
    for (int i = 0; i <= 5; i++) {
      final y = chartB - i / 5 * chartH;
      canvas.drawLine(Offset(chartL, y), Offset(size.width, y), gridPaint);
    }

    // Y-axis labels
    for (int i = 0; i <= 5; i++) {
      final y = chartB - i / 5 * chartH;
      final label = i == 0 ? '0' : '${i * 5}k';
      _paintText(canvas, label, Offset(0, y - 6), _leftPad - 2, TextAlign.right);
    }

    // Convert data to canvas points
    final pts = <Offset>[];
    for (int i = 0; i < _data.length; i++) {
      pts.add(Offset(
        chartL + i / (_data.length - 1) * chartW,
        chartB - _data[i] / _maxValue * chartH,
      ));
    }

    // Area path (bezier)
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

    // Line path (bezier)
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

    // X-axis labels
    for (int i = 0; i < pts.length; i++) {
      _paintText(
        canvas,
        _xLabels[i],
        Offset(pts[i].dx - 22, chartB + 5),
        44,
        TextAlign.center,
      );
    }
  }

  void _addBezier(Path path, List<Offset> pts) {
    for (int i = 1; i < pts.length; i++) {
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Top Products ──────────────────────────────────────────────────────────────

class _TopProductsSection extends StatelessWidget {
  const _TopProductsSection();

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
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        const _TopProductItem(
          name: 'Nike Air Max 2025',
          totalSales: 45,
          commission: 'Rs 17,789',
          rate: '15%',
          average: 'Rs 860/sale',
          accentColor: Color(0xFFE74C3C),
          icon: Icons.sports_outlined,
        ),
        const SizedBox(height: DesignTokens.s12),
        const _TopProductItem(
          name: 'Raspberry Velvet Cake',
          totalSales: 66,
          commission: 'Rs 33,000',
          rate: '48%',
          accentColor: Color(0xFFE74C3C),
          icon: Icons.cake_outlined,
        ),
        const SizedBox(height: DesignTokens.s16),
        SizedBox(
          width: double.infinity,
          height: DesignTokens.buttonHeight,
          child: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => ctx.push(RouteNames.creatorFullAnalyticsReport),
              style: DesignTokens.primaryButtonStyle(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View Full Report'),
                  SizedBox(width: DesignTokens.s8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
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
          // Icon
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
          // Info
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

class _AnalyticsBottomNav extends StatelessWidget {
  const _AnalyticsBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBtn(
            iconWidget: const Icon(Icons.home_rounded, size: 22, color: DesignTokens.textMuted),
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
            iconWidget: const Icon(Icons.storefront_outlined, size: 22, color: DesignTokens.textMuted),
            label: 'Brands',
            onTap: () => context.push(RouteNames.partnerships),
          ),
          _NavBtn(
            iconWidget: const Icon(Icons.person_outline_rounded, size: 22, color: DesignTokens.textMuted),
            label: 'Profile',
            onTap: () => context.push(
              RouteNames.creatorProfile.replaceFirst(':accountId', 'me'),
              extra: const CreatorProfileArgs(
                accountId: 'me',
                displayName: 'Danny Perierra',
                handle: '@wandererperierra',
              ),
            ),
          ),
        ],
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
