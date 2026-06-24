import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorAnalyticsScreen extends StatelessWidget {
  const VendorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: DesignTokens.textWhite, size: 18),
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Revenue Overview (Last 30 Days)',
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RevenueOverviewCard(),
                  const SizedBox(height: 12),
                  _EarningsOverviewCard(),
                  const SizedBox(height: 12),
                  _topProductsSection(context),
                  const SizedBox(height: 12),
                  _creatorPerformanceSection(context),
                  const SizedBox(height: 12),
                  _TrafficSourcesCard(),
                ],
              ),
            ),
          ),

          // Fixed bottom button
          Container(
            color: DesignTokens.bgAppFoundation,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGreen,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.download_outlined,
                    color: Colors.black, size: 20),
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
}

// ---------------------------------------------------------------------------
// Revenue Overview
// ---------------------------------------------------------------------------

class _RevenueOverviewCard extends StatelessWidget {
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
                  label: 'Gross Sales',
                  badge: '+23%',
                  value: '3,45,12,589.98',
                  badgeColor: DesignTokens.primaryGreen,
                ),
                const SizedBox(height: 14),
                _MetricRow(
                  icon: 'assets/images/vendordashboard/icon_net_revenue.png',
                  label: 'Net Revenue',
                  badge: '+15%',
                  value: '2,85,92,677.90',
                  badgeColor: DesignTokens.primaryGreen,
                ),
                const SizedBox(height: 14),
                _MetricRow(
                  icon: 'assets/images/vendordashboard/icon_conversion_rate.png',
                  label: 'Conversion Rate',
                  badge: '+15%',
                  value: '3.8%',
                  badgeColor: DesignTokens.primaryGreen,
                ),
              ],
            ),
          ),

          // Total Orders strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(DesignTokens.cardRadius)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Orders Completed',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '1,981',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_drop_up,
                              size: 18, color: Colors.black87),
                          Text(
                            '14%',
                            style: TextStyle(
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
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.badge,
    required this.value,
    required this.badgeColor,
  });

  final String icon;
  final String label;
  final String badge;
  final String value;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(icon, width: 32, height: 32, fit: BoxFit.contain),
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
                      color: Color(0xFF9F9FA9),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  fontWeight: FontWeight.w700,
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
  static const _points = [
    5000.0, 8000.0, 20000.0, 13000.0, 8000.0, 10000.0,
  ];
  static const _labels = [
    'Dec 1', 'Dec 7', 'Dec 14', 'Dec 21', 'Dec 28', 'Today',
  ];

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
              color: Color(0xFF9F9FA9),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: _LineChart(points: _points, xLabels: _labels),
          ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.points, required this.xLabels});

  final List<double> points;
  final List<String> xLabels;

  @override
  Widget build(BuildContext context) {
    const yMax = 25000.0;
    const ySteps = 5;
    const yLabels = ['0', '5k', '10k', '15k', '20k', '25k'];
    const labelW = 32.0;
    const bottomH = 20.0;

    return Row(
      children: [
        // Y-axis labels
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: xLabels
                      .map((l) => Text(
                            l,
                            style: const TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 9,
                              color: Color(0xFF9F9FA9),
                            ),
                          ))
                      .toList(),
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

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFF3A3A3C)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= ySteps; i++) {
      final y = h - (i / ySteps) * h;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Convert data to canvas coordinates
    Offset toOffset(int i) {
      final x = (i / (points.length - 1)) * w;
      final y = h - (points[i] / yMax) * h;
      return Offset(x, y);
    }

    final offsets = List.generate(points.length, toOffset);

    // Filled gradient area
    final fillPath = Path();
    fillPath.moveTo(offsets.first.dx, h);
    for (final o in offsets) {
      fillPath.lineTo(o.dx, o.dy);
    }
    fillPath.lineTo(offsets.last.dx, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          DesignTokens.primaryGreen.withValues(alpha: 0.3),
          DesignTokens.primaryGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = DesignTokens.primaryGreen
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    linePath.moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      final prev = offsets[i - 1];
      final curr = offsets[i];
      final cpx = (prev.dx + curr.dx) / 2;
      linePath.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots at each data point
    final dotPaint = Paint()..color = DesignTokens.primaryGreen;
    final dotBg = Paint()..color = DesignTokens.bgAppBodyLight;
    for (final o in offsets) {
      canvas.drawCircle(o, 4, dotBg);
      canvas.drawCircle(o, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Top Products
// ---------------------------------------------------------------------------

Widget _topProductsSection(BuildContext context) {
  const products = [
    _Product(
      rank: 1,
      name: 'Nike Air Jordan Travis Scott\nLimited Edition',
      price: 'Rs 25,000',
      sales: '245 sales',
      image: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=100',
    ),
    _Product(
      rank: 2,
      name: 'Nike Air Max Reds 2025',
      price: 'Rs 18,000',
      sales: '198 sales',
      image: 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=100',
    ),
    _Product(
      rank: 3,
      name: 'Nike Tech Fleece Jacket',
      price: 'Rs 12,000',
      sales: '178 sales',
      image: 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=100',
    ),
  ];

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
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.vendorTopProducts),
            child: const Text(
              'View All',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
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
                      height: 1, color: Color(0xFF3A3A3C), indent: 16, endIndent: 16),
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

  final _Product product;

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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9F9FA9),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              product.image,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48,
                height: 48,
                color: const Color(0xFF2C2C2E),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Color(0xFF9F9FA9), size: 24),
              ),
            ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.price}  •  ${product.sales}',
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

class _Product {
  const _Product({
    required this.rank,
    required this.name,
    required this.price,
    required this.sales,
    required this.image,
  });

  final int rank;
  final String name;
  final String price;
  final String sales;
  final String image;
}

// ---------------------------------------------------------------------------
// Creator Performance
// ---------------------------------------------------------------------------

Widget _creatorPerformanceSection(BuildContext context) {
  const creators = [
    _Creator(rank: 1, handle: '@fashion_sarah', sales: 'Rs 25,000', reels: '12 reels'),
    _Creator(rank: 2, handle: '@style_guru', sales: 'Rs 25,000', reels: '12 reels'),
    _Creator(rank: 3, handle: '@fitness_pro', sales: 'Rs 25,000', reels: '12 reels'),
  ];

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
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.vendorCreatorPerformance),
            child: const Text(
              'View All',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
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
                      height: 1, color: Color(0xFF3A3A3C), indent: 16, endIndent: 16),
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

  final _Creator creator;

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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9F9FA9),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2C2C2E),
            child: Text(
              creator.handle[1].toUpperCase(),
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
                  creator.handle,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${creator.sales}  •  ${creator.reels}',
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

class _Creator {
  const _Creator({
    required this.rank,
    required this.handle,
    required this.sales,
    required this.reels,
  });

  final int rank;
  final String handle;
  final String sales;
  final String reels;
}

// ---------------------------------------------------------------------------
// Traffic Sources
// ---------------------------------------------------------------------------

class _TrafficSourcesCard extends StatelessWidget {
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
          Row(
            children: [
              Expanded(
                child: _TrafficTile(
                  icon: 'assets/images/vendordashboard/icon_youtube.png',
                  label: 'Youtube\nShorts',
                  percent: '23%',
                  color: const Color(0xFFFF0000),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrafficTile(
                  icon: 'assets/images/vendordashboard/icon_instagram.png',
                  label: 'Instagram\nReels',
                  percent: '45%',
                  color: const Color(0xFFE1306C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TrafficTile(
                  icon: 'assets/images/vendordashboard/icon_tiktok.png',
                  label: 'TikTok',
                  percent: '32%',
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          Image.asset(icon, width: 32, height: 32, fit: BoxFit.contain),
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
