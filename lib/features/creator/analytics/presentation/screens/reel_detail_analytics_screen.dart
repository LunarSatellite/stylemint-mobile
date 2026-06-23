import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ReelDetailAnalyticsScreen extends StatelessWidget {
  const ReelDetailAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DesignTokens.textWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Reel Details', style: DesignTokens.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border_rounded, color: DesignTokens.textWhite),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: DesignTokens.textWhite),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Date range text + filter chips ─────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.s16, DesignTokens.s8, DesignTokens.s16, DesignTokens.s8,
              ),
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
            const _FilterChipsRow(),
            const SizedBox(height: DesignTokens.s16),

            // ── Reel info + stats ───────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: _ReelInfoCard(),
            ),
            const SizedBox(height: DesignTokens.s20),

            // ── Earnings distribution ───────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Earnings Distribution Data',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Analytics data for each tagged product\'s earnings',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      color: DesignTokens.textMuted,
                    ),
                  ),
                  SizedBox(height: DesignTokens.s12),
                  _EarningsDistributionCard(),
                  SizedBox(height: DesignTokens.s16),
                  _StatisticsSection(),
                  SizedBox(height: DesignTokens.s24),
                  _EarningsOverviewSection(),
                  SizedBox(height: DesignTokens.s24),
                  _AudienceDemographicSection(),
                  SizedBox(height: DesignTokens.s24),
                  _GenderDistributionSection(),
                  SizedBox(height: DesignTokens.s24),
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
    (null,                          'Last 7 days',  true),
    (null,                          'Last 30 days', false),
    (null,                          'Last 90 days', false),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      child: Row(
        children: _chips.map((c) {
          final icon     = c.$1;
          final label    = c.$2;
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
                  Icon(icon,
                    size: 13,
                    color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? DesignTokens.primaryGreen : DesignTokens.textLight,
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

// ── Reel info card ────────────────────────────────────────────────────────────

class _ReelInfoCard extends StatelessWidget {
  const _ReelInfoCard();

  static const _stats = [
    (Icons.favorite_rounded,           '23.8k'),
    (Icons.visibility_outlined,         '465k'),
    (Icons.share_outlined,              '13.67k'),
    (Icons.chat_bubble_outline_rounded, '976'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          // ── Top: thumbnail + info + link icon ─────────────────────────
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Red thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                  child: Container(
                    width: 64,
                    height: 72,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFB71C1C), Color(0xFF4A0000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.directions_run_rounded,
                      color: Colors.white38,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                // Title + badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nike Structure 26 – Be the Trail Blazzer Runner',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Instagram badge
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Imported from Instagram',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Posted on: 7 Aug, 2025 09:57 PM',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 11,
                        ),
                      ),
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

          // ── Bottom: engagement stats ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _stats.map((s) => Column(
                children: [
                  Icon(s.$1, size: 20, color: DesignTokens.textLight),
                  const SizedBox(height: 4),
                  Text(
                    s.$2,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                ],
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Earnings distribution card ────────────────────────────────────────────────

class _EarningsDistributionCard extends StatelessWidget {
  const _EarningsDistributionCard();

  static const _products = [
    _Product('Blueberry Cheese Cake',                                        Color(0xFF4DA6FF), 31, 'Rs 4,135.50'),
    _Product('Belgian Chocolate Truffles Cake with Swiss Chocolate Drizzle', Color(0xFF2ECC71), 30, 'Rs 3,954.18'),
    _Product('Strawberry Cheese Cake',                                       Color(0xFFFF6B6B), 26, 'Rs 2,377.30'),
    _Product('Belgian Chocolate Tiramisu Cake',                              Color(0xFFFFD93D), 20, 'Rs 1,897'),
  ];
  

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Large earnings number ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, DesignTokens.s12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  '14,235.98',
                  style: TextStyle(
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
                    'Rs. earned',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Segmented bar ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s8),
              child: SizedBox(
                height: 36,
                child: Row(
                  children: _products.map((p) => Expanded(
                    flex: p.pct,
                    child: Container(
                      color: p.color,
                      alignment: Alignment.center,
                      child: Text(
                        '${p.pct}%',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
          ),

          // ── Product rows ───────────────────────────────────────────────
          ...List.generate(_products.length, (i) => Column(
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
                        color: _products[i].color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Text(
                        _products[i].name,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Text(
                      _products[i].amount,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }
}

class _Product {
  const _Product(this.name, this.color, this.pct, this.amount);
  final String name;
  final Color  color;
  final int    pct;
  final String amount;
}

// ── Statistics section ────────────────────────────────────────────────────────

class _StatisticsSection extends StatelessWidget {
  const _StatisticsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: DesignTokens.textWhite,
          ),
        ),
        SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(child: _StatCard(
              iconWidget: _PercentIcon(),
              value: '10.25%',
              label: 'Conversion Rate',
            )),
            SizedBox(width: DesignTokens.s12),
            Expanded(child: _StatCard(
              iconWidget: Icon(Icons.ads_click_rounded, color: DesignTokens.textMuted, size: 22),
              value: '40%',
              label: 'Click Through Rate',
            )),
          ],
        ),
        SizedBox(height: DesignTokens.s12),
        Row(
          children: [
            Expanded(child: _StatCard(
              iconWidget: Icon(Icons.remove_red_eye_outlined, color: DesignTokens.textMuted, size: 22),
              value: '257.9k',
              label: 'Completion Rate',
            )),
            SizedBox(width: DesignTokens.s12),
            Expanded(child: _StatCard(
              iconWidget: Icon(Icons.account_circle_outlined, color: DesignTokens.textMuted, size: 22),
              value: '187.9k',
              label: 'Unique Viewers',
            )),
          ],
        ),
        SizedBox(height: DesignTokens.s12),
        // Green watch time card
        _WatchTimeCard(),
      ],
    );
  }
}

class _WatchTimeCard extends StatelessWidget {
  const _WatchTimeCard();

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
            child: const Icon(Icons.timer_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: DesignTokens.s16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '5,563 minutes',
                style: TextStyle(
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
  const _EarningsOverviewSection();

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
        const SizedBox(height: 4),
        Text(
          'According to demographics according to age groups',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.fromLTRB(8, DesignTokens.s16, DesignTokens.s12, DesignTokens.s12),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _EarningsLinePainter()),
          ),
        ),
      ],
    );
  }
}

class _EarningsLinePainter extends CustomPainter {
  static const _data    = [1200.0, 3500, 5000, 8000, 11000, 22000];
  static const _xLabels = ['Dec 1', 'Dec 7', 'Dec 14', 'Dec 21', 'Dec 28', 'Today'];
  static const _yLabels = ['0', '5k', '10k', '15k', '20k', '25k'];
  static const _maxVal  = 25000.0;
  static const _leftPad   = 38.0;
  static const _bottomPad = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final chartW = size.width - _leftPad;
    final chartH = size.height - _bottomPad;

    final pts = List.generate(_data.length, (i) => Offset(
      _leftPad + i * chartW / (_data.length - 1),
      chartH - (_data[i] / _maxVal) * chartH,
    ));

    // Area fill
    final areaPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      areaPath.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    areaPath..lineTo(pts.last.dx, chartH)..lineTo(pts.first.dx, chartH)..close();
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
    canvas.drawPath(linePath, Paint()
      ..color = DesignTokens.primaryGreen
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke);

    // Grid + y-labels
    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    for (int i = 0; i < _yLabels.length; i++) {
      final y = chartH - (i / (_yLabels.length - 1)) * chartH;
      canvas.drawLine(Offset(_leftPad, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: _yLabels[i], style: const TextStyle(color: DesignTokens.textMuted, fontSize: 9, fontFamily: DesignTokens.fontFamily)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // X-labels
    for (int i = 0; i < _xLabels.length; i++) {
      final x = _leftPad + i * chartW / (_xLabels.length - 1);
      final tp = TextPainter(
        text: TextSpan(text: _xLabels[i], style: const TextStyle(color: DesignTokens.textMuted, fontSize: 9, fontFamily: DesignTokens.fontFamily)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartH + 5));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ── Audience demographic ──────────────────────────────────────────────────────

class _AudienceDemographicSection extends StatelessWidget {
  const _AudienceDemographicSection();

  static const _segments = [
    (0.35, Color(0xFF2ECC71), '18–24', '35%'),
    (0.25, Color(0xFF4DA6FF), '25–34', '25%'),
    (0.20, Color(0xFFAB8FF5), '35–44', '20%'),
    (0.12, Color(0xFFFF6B6B), '45–54', '12%'),
    (0.08, Color(0xFFFFD93D), '55+',    '8%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Audience Demographic',
          style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: DesignTokens.textWhite)),
        const SizedBox(height: 4),
        Text('According to demographics according to age groups',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            children: [
              SizedBox(
                width: 180, height: 180,
                child: CustomPaint(painter: _DonutPainter(
                  segments: _segments.map((s) => (s.$1, s.$2)).toList(),
                  strokeWidth: 30,
                )),
              ),
              const SizedBox(height: DesignTokens.s16),
              Wrap(
                spacing: DesignTokens.s16,
                runSpacing: DesignTokens.s8,
                alignment: WrapAlignment.center,
                children: _segments.map((s) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: s.$2, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('${s.$3}  ${s.$4}',
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight, fontSize: 11)),
                  ],
                )).toList(),
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
  const _GenderDistributionSection();

  static const _genders = [
    ('Female', Color(0xFF4DA6FF), 0.54, '54%'),
    ('Male',   Color(0xFF2ECC71), 0.35, '35%'),
    ('Other',  Color(0xFFAB8FF5), 0.11, '11%'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Gender Distribution Data',
          style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: DesignTokens.textWhite)),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _genders.map((g) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s16),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: g.$2, shape: BoxShape.circle)),
                        const SizedBox(width: DesignTokens.s8),
                        Expanded(child: Text(g.$1, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted))),
                        Text(g.$4, style: const TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 15, fontWeight: FontWeight.w700, color: DesignTokens.textWhite)),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(width: DesignTokens.s16),
              SizedBox(
                width: 110, height: 110,
                child: CustomPaint(painter: _DonutPainter(
                  segments: _genders.map((g) => (g.$3, g.$2)).toList(),
                  strokeWidth: 22,
                )),
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
  const _TopLocationsSection();

  static const _locations = [
    ('New York', Color(0xFF2ECC71), 0.40),
    ('Chicago',  Color(0xFF4DA6FF), 0.35),
    ('Atlanta',  Color(0xFFAB8FF5), 0.25),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Top Locations',
          style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: DesignTokens.textWhite)),
        const SizedBox(height: 4),
        Text('Audience demographics according to different locations',
          style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted)),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  width: 160, height: 160,
                  child: CustomPaint(painter: _DonutPainter(
                    segments: _locations.map((l) => (l.$3, l.$2)).toList(),
                    strokeWidth: 32,
                  )),
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _locations.map((l) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(color: l.$2, shape: BoxShape.circle)),
                      const SizedBox(width: DesignTokens.s4),
                      Text(l.$1, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight, fontSize: 11)),
                    ],
                  ),
                )).toList(),
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
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;
    const gapAngle = 0.05;
    final totalGap = gapAngle * segments.length;
    final total = segments.fold(0.0, (s, e) => s + e.$1);
    double startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (final seg in segments) {
      final sweep = (seg.$1 / total) * (2 * math.pi - totalGap);
      paint.color = seg.$2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweep, false, paint);
      startAngle += sweep + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
