
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class FullAnalyticsReportScreen extends StatelessWidget {
  const FullAnalyticsReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: DesignTokens.textWhite,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date range label ──────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(left: DesignTokens.s16, top: DesignTokens.s8),
              child: Text(
                'Date Range: Dec 1 - 18, 2025',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.textLight,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.s8),

            // ── Filter chips (horizontal scroll) ─────────────────────────
            const _FilterChipsRow(),
            const SizedBox(height: DesignTokens.s16),

            // ── Padded content ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  // Section 1: Earnings Overview
                  _EarningsOverviewSection(),
                  SizedBox(height: DesignTokens.s24),

                  // Section 2: Content Performance
                  _ContentPerformanceSection(),
                  SizedBox(height: DesignTokens.s24),

                  // Section 3: Conversion Metrics
                  _ConversionMetricsSection(),
                  SizedBox(height: DesignTokens.s24),

                  // Section 4: Conversion Funnel
                  _ConversionFunnelSection(),
                  SizedBox(height: DesignTokens.s24),

                  // Section 5: Audience Demographic
                  _AudienceDemographicSection(),
                  SizedBox(height: DesignTokens.s24),

                  // Section 6: Best Posting Times
                  _BestPostingTimesSection(),
                  SizedBox(height: DesignTokens.s24),

                  // Section 7: Gender Distribution Data
                  _GenderDistributionSection(),
                  SizedBox(height: DesignTokens.s24),

                  // Section 8: Top 5 Earning Products
                  _TopEarningProductsSection(),
                  SizedBox(height: DesignTokens.s24),

                  // Section 9: Top Locations
                  _TopLocationsSection(),
                  SizedBox(height: DesignTokens.s32),
                ],
              ),
            ),
          ],
        ),
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
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
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
  const _EarningsOverviewSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Earnings Overview',
          subtitle: 'Audience Demographic according to different age groups',
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
            child: CustomPaint(painter: _EarningsLinePainter()),
          ),
        ),
      ],
    );
  }
}

class _EarningsLinePainter extends CustomPainter {
  static const _data = [5000.0, 8000.0, 12000.0, 25000.0, 10000.0, 18000.0];
  static const _xLabels = ['Dec 1', 'Dec 7', 'Dec 14', 'Dec 21', 'Dec 28', 'Today'];
  static const _yLabels = ['0', '5k', '10k', '15k', '20k', '25k'];
  static const _maxVal = 25000.0;
  static const _leftPad = 38.0;
  static const _bottomPad = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad;

    final pts = List.generate(_data.length, (i) => Offset(
      _leftPad + i * chartW / (_data.length - 1),
      chartH - (_data[i] / _maxVal) * chartH,
    ));

    // Grid lines
    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < _yLabels.length; i++) {
      final y = chartH - (i / (_yLabels.length - 1)) * chartH;
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
    for (int i = 0; i < _yLabels.length; i++) {
      final y = chartH - (i / (_yLabels.length - 1)) * chartH;
      final tp = TextPainter(
        text: TextSpan(
          text: _yLabels[i],
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // X-axis labels
    for (int i = 0; i < _xLabels.length; i++) {
      final x = _leftPad + i * chartW / (_xLabels.length - 1);
      final tp = TextPainter(
        text: TextSpan(
          text: _xLabels[i],
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartH + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Section 2: Content Performance ───────────────────────────────────────────

class _ContentPerformanceSection extends StatelessWidget {
  const _ContentPerformanceSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Content Performance',
          subtitle: 'Audience Demographic according to different age groups',
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
            child: CustomPaint(painter: _BarChartPainter()),
          ),
        ),
      ],
    );
  }
}

class _BarChartPainter extends CustomPainter {
  static const _barData = [
    20000.0, 18000.0, 8000.0, 25000.0, 22000.0,
    13000.0, 28000.0, 25000.0, 22000.0, 15000.0,
  ];
  static const _xLabels = [
    'R1', 'R2', 'R3', 'R4', 'R5', 'R6', 'R7', 'R8', 'R9', 'R10',
  ];
  static const _yLabels = ['0', '5k', '10k', '15k', '20k', '25k', '30k', '35k'];
  static const _maxVal = 35000.0;
  static const _leftPad = 38.0;
  static const _bottomPad = 22.0;
  static const _barColor = Color(0xFF4DA6FF);

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad;

    // Grid lines
    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < _yLabels.length; i++) {
      final y = chartH - (i / (_yLabels.length - 1)) * chartH;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), gridPaint);
    }

    // Y-axis labels
    for (int i = 0; i < _yLabels.length; i++) {
      final y = chartH - (i / (_yLabels.length - 1)) * chartH;
      final tp = TextPainter(
        text: TextSpan(
          text: _yLabels[i],
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Bars
    final count = _barData.length;
    final slotW = chartW / count;
    final barW = slotW * 0.6;
    const radius = Radius.circular(3);
    final barPaint = Paint()..color = _barColor;

    for (int i = 0; i < count; i++) {
      final barH = (_barData[i] / _maxVal) * chartH;
      final left = _leftPad + i * slotW + (slotW - barW) / 2;
      final top = chartH - barH;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(left, top, barW, barH),
        topLeft: radius,
        topRight: radius,
      );
      canvas.drawRRect(rect, barPaint);

      // X-axis labels
      final tp = TextPainter(
        text: TextSpan(
          text: _xLabels[i],
          style: const TextStyle(
            color: DesignTokens.textMuted,
            fontSize: 9,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(left + barW / 2 - tp.width / 2, chartH + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Section 3: Conversion Metrics ────────────────────────────────────────────

class _ConversionMetricsSection extends StatelessWidget {
  const _ConversionMetricsSection();

  static const _metrics = [
    (Icons.ads_click_rounded, '12,890', 'Total Clicks'),
    (Icons.receipt_outlined, '187', 'Total Orders'),
    (Icons.percent, '10.25%', 'Conversion Rate'),
    (Icons.credit_card_outlined, 'Rs 5,478', 'Avg. Order Value'),
  ];

  @override
  Widget build(BuildContext context) {
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
        _MetricGrid(metrics: _metrics),
      ],
    );
  }
}

// ── Section 4: Conversion Funnel ─────────────────────────────────────────────

class _ConversionFunnelSection extends StatelessWidget {
  const _ConversionFunnelSection();

  static const _metrics = [
    (Icons.remove_red_eye_outlined, '250k (100%)', 'Viewed Reel'),
    (Icons.inventory_2_outlined, '8,942 (3.8%)', 'Clicked Product'),
    (Icons.shopping_cart_outlined, '562 (0.24%)', 'Added Cart'),
    (Icons.shopping_bag_outlined, '187 (0.08%)', 'Completed Order'),
  ];

  @override
  Widget build(BuildContext context) {
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
        _MetricGrid(metrics: _metrics),
      ],
    );
  }
}

// ── Shared 2×2 metric grid ────────────────────────────────────────────────────

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<(IconData, String, String)> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _MetricCard(icon: metrics[0].$1, value: metrics[0].$2, label: metrics[0].$3)),
            const SizedBox(width: DesignTokens.s12),
            Expanded(child: _MetricCard(icon: metrics[1].$1, value: metrics[1].$2, label: metrics[1].$3)),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(child: _MetricCard(icon: metrics[2].$1, value: metrics[2].$2, label: metrics[2].$3)),
            const SizedBox(width: DesignTokens.s12),
            Expanded(child: _MetricCard(icon: metrics[3].$1, value: metrics[3].$2, label: metrics[3].$3)),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
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
            child: Icon(icon, color: DesignTokens.textMuted, size: 22),
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
  const _AudienceDemographicSection();

  static const _segments = [
    (0.55, Color(0xFFFF9800), '55%', '18-24'),
    (0.20, Color(0xFF4DA6FF), '20%', '25-34'),
    (0.09, Color(0xFF2ECC71), '9%', '35-44'),
    (0.16, Color(0xFFFFD93D), '16%', '45+'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Audience Demographic',
          subtitle: 'Audience Demographic according to different age groups',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _DonutLabelsPainter(
                      segments: _segments
                          .map((s) => (s.$1, s.$2, s.$3))
                          .toList(),
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
                children: _segments
                    .map((s) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.$2,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.$4,
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ))
                    .toList(),
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
  const _BestPostingTimesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Green card
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
                      'Heatmap: Day x Hour',
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
              // Stacked icons
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 64,
                      color: Color.fromRGBO(255, 255, 255, 0.30),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Icon(
                        Icons.cloud_rounded,
                        size: 28,
                        color: Colors.white.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        // Dark card with schedule rows
        Container(
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            children: [
              _PostingTimeRow(
                day: 'Monday - Friday : 6-9 PM',
                subtitle: 'Peak Engagement',
              ),
              const Divider(
                color: DesignTokens.borderDefault,
                height: 1,
                indent: DesignTokens.s16,
                endIndent: DesignTokens.s16,
              ),
              _PostingTimeRow(
                day: 'Saturday - Sunday : 12-3 PM',
                subtitle: 'High Activity',
              ),
            ],
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
  const _GenderDistributionSection();

  static const _blue = Color(0xFF4DA6FF);
  static const _green = Color(0xFF2ECC71);
  static const _yellow = Color(0xFFFFD93D);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Gender Distribution Data',
          subtitle: 'Audience Demographic according to different gender',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Segmented bar
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
                        Expanded(
                          flex: 54,
                          child: Container(
                            color: _blue,
                            alignment: Alignment.center,
                            child: const Text(
                              '54%',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 26,
                          child: Container(
                            color: _green,
                            alignment: Alignment.center,
                            child: const Text(
                              '26%',
                              style: TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 20,
                          child: Container(
                            color: _yellow,
                            alignment: Alignment.center,
                            child: const Text(
                              '20%',
                              style: TextStyle(
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
              // Legend rows
              _GenderRow(color: _blue, label: 'Female', pct: '54%'),
              _GenderRow(color: _green, label: 'Male', pct: '26%'),
              _GenderRow(color: _yellow, label: 'Others', pct: '20%'),
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
  const _TopEarningProductsSection();

  static const _products = [
    _ProductData(
      name: 'Nike Air Jordan Travis Scott Limited Edition',
      bgColor: Color(0xFF2A2A2A),
      icon: Icons.directions_run_rounded,
      price: 'Rs 25,000',
      sales: 245,
    ),
    _ProductData(
      name: 'Nike Air Max Reds 2025',
      bgColor: Color(0xFFB71C1C),
      icon: Icons.directions_run_rounded,
      price: 'Rs 18,000',
      sales: 233,
    ),
    _ProductData(
      name: 'Nike Air Jordan Autumn Bloom Ultra Light Sneakers',
      bgColor: Color(0xFFE65100),
      icon: Icons.directions_run_rounded,
      price: 'Rs 32,500',
      sales: 208,
    ),
    _ProductData(
      name: 'Nike Tech Fleece Jacket',
      bgColor: Color(0xFF37474F),
      icon: Icons.checkroom_rounded,
      price: 'Rs 12,000',
      sales: 178,
    ),
    _ProductData(
      name: 'Nike Omi Multi Court Sneakers',
      bgColor: Color(0xFF0D47A1),
      icon: Icons.directions_run_rounded,
      price: 'Rs 16,000',
      sales: 148,
    ),
  ];

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
        ...List.generate(_products.length, (i) {
          final p = _products[i];
          final isLast = i == _products.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
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
                      child: Container(
                        width: 52,
                        height: 52,
                        color: p.bgColor,
                        alignment: Alignment.center,
                        child: Icon(p.icon, color: Colors.white38, size: 28),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
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
                            '${p.price} · ${p.sales} sales',
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

class _ProductData {
  const _ProductData({
    required this.name,
    required this.bgColor,
    required this.icon,
    required this.price,
    required this.sales,
  });

  final String name;
  final Color bgColor;
  final IconData icon;
  final String price;
  final int sales;
}

// ── Section 9: Top Locations ──────────────────────────────────────────────────

class _TopLocationsSection extends StatelessWidget {
  const _TopLocationsSection();

  static const _segments = [
    (0.22, Color(0xFF4DA6FF), '22%', 'New York'),
    (0.28, Color(0xFFFFD93D), '28%', 'Chicago'),
    (0.25, Color(0xFFFF6B6B), '25%', 'Miami'),
    (0.16, Color(0xFFFF8C42), '16%', 'Berlin'),
    (0.09, Color(0xFF2ECC71), '9%', 'Others'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Top Locations',
          subtitle: 'Audience Demographic according to different location',
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: _DonutLabelsPainter(
                      segments: _segments
                          .map((s) => (s.$1, s.$2, s.$3))
                          .toList(),
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
                children: _segments
                    .map((s) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.$2,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.$4,
                              style: DesignTokens.smallRegular.copyWith(
                                color: DesignTokens.textLight,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ))
                    .toList(),
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

  /// (fraction, color, label)
  final List<(double, Color, String)> segments;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width, size.height) / 2 - strokeWidth / 2 - 2;
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

      // Label on arc — only if segment is large enough
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
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
      }

      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
