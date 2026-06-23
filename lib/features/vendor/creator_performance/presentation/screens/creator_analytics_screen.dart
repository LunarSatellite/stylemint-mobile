import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/adjust_commission_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/message_creator_screen.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── Args ─────────────────────────────────────────────────────────────────────

class CreatorAnalyticsArgs {
  const CreatorAnalyticsArgs({
    required this.creatorName,
    required this.handle,
    required this.followersLabel,
    required this.commission,
    this.avatarAsset = '',
  });

  final String creatorName;
  final String handle;
  final String followersLabel;
  final int commission;
  final String avatarAsset;
}

// ─── Mock product data ────────────────────────────────────────────────────────

class _MockProduct {
  const _MockProduct({
    required this.rank,
    required this.name,
    required this.price,
    required this.sales,
    required this.imagePath,
  });

  final int rank;
  final String name;
  final String price;
  final int sales;
  final String imagePath;
}

const _mockProducts = [
  _MockProduct(
    rank: 1,
    name: 'Air Force 1 Low',
    price: '',
    sales: 245,
    imagePath: 'assets/images/sample_shoe1.png',
  ),
  _MockProduct(
    rank: 2,
    name: 'Nike Air Max 270',
    price: '',
    sales: 233,
    imagePath: 'assets/images/sample_shoe2.png',
  ),
  _MockProduct(
    rank: 3,
    name: 'New Balance 550',
    price: 'Rs 32,500',
    sales: 208,
    imagePath: 'assets/images/sample_shoe3.png',
  ),
  _MockProduct(
    rank: 4,
    name: 'Nike Air Max Classic',
    price: '',
    sales: 178,
    imagePath: 'assets/images/product_nike_air_max.png',
  ),
  _MockProduct(
    rank: 5,
    name: 'Air Jordan 1',
    price: 'Rs 16,000',
    sales: 148,
    imagePath: 'assets/images/product_nike_air_jordan.png',
  ),
  _MockProduct(
    rank: 6,
    name: 'Nike Windshield Jacket',
    price: 'Rs 12,000',
    sales: 133,
    imagePath: 'assets/images/product_nike_windsheeter.png',
  ),
  _MockProduct(
    rank: 7,
    name: 'Nike Zoom Pegasus',
    price: 'Rs 18,000',
    sales: 127,
    imagePath: 'assets/images/sample_shoe1.png',
  ),
  _MockProduct(
    rank: 8,
    name: 'Nike Sportswear Tee',
    price: 'Rs 7,000',
    sales: 109,
    imagePath: 'assets/images/sample_shoe2.png',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class CreatorAnalyticsScreen extends StatefulWidget {
  const CreatorAnalyticsScreen({super.key, required this.args});

  final CreatorAnalyticsArgs args;

  @override
  State<CreatorAnalyticsScreen> createState() =>
      _CreatorAnalyticsScreenState();
}

class _CreatorAnalyticsScreenState extends State<CreatorAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  static const _filters = [
    'Custom Date',
    'Last 7 days',
    'Last 30 days',
    'Last 6 months',
  ];
  String _selectedFilter = 'Last 7 days';
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Creator Analytics',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
        actions: [
          _AppBarIconButton(
            assetPath: 'assets/images/icon_file_export.png',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _AppBarIconButton(
            assetPath: 'assets/images/icon_btn_right.png',
            onTap: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  DesignTokens.s16, DesignTokens.s12, DesignTokens.s16, 0),
              child: Text(
                'Date Range: Dec 1 - 18, 2025',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 13,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _FilterChips(
              filters: _filters,
              selected: _selectedFilter,
              onSelect: (f) => setState(() => _selectedFilter = f),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                0,
                DesignTokens.s16,
                DesignTokens.s16,
              ),
              child: _CreatorCard(args: widget.args),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                0,
                DesignTokens.s16,
                DesignTokens.s16,
              ),
              child: const _GraphCard(),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(tabCtrl: _tabCtrl),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: const [
            _ProductsTab(),
            _ReelsTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Date filter chips ────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
      child: Row(
        children: filters.map((f) {
          final isSelected = f == selected;
          final isCustom = f == 'Custom Date';
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s8),
            child: GestureDetector(
              onTap: () => onSelect(f),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? DesignTokens.primaryGreen.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? DesignTokens.primaryGreen
                        : DesignTokens.borderDefault,
                  ),
                ),
                child: Row(
                  children: [
                    if (isCustom) ...[
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 14,
                        color: isSelected
                            ? DesignTokens.primaryGreen
                            : DesignTokens.textMuted,
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      f,
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        color: isSelected
                            ? DesignTokens.primaryGreen
                            : DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Creator card ─────────────────────────────────────────────────────────────

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.args});

  final CreatorAnalyticsArgs args;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    args.avatarAsset,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: DesignTokens.bgAppFoundation,
                      alignment: Alignment.center,
                      child: Text(
                        args.creatorName.isNotEmpty
                            ? args.creatorName[0]
                            : '?',
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        args.creatorName,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 12,
                            color: DesignTokens.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${args.followersLabel} Followers · ${args.handle}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 12,
                                color: DesignTokens.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Commission: ${args.commission}%',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
              height: 1, thickness: 1, color: DesignTokens.borderDefault),
          // Stats
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              children: [
                _StatRow(
                  iconAsset: 'assets/images/icon_gross_sales.png',
                  iconBgColor: const Color(0xFF1A3A1A),
                  label: 'Total Sales',
                  value: '3,45,12,589.98',
                ),
                const SizedBox(height: DesignTokens.s16),
                _StatRow(
                  iconAsset: 'assets/images/icon_net_revenue.png',
                  iconBgColor: const Color(0xFF0D2137),
                  label: 'Total Revenue',
                  value: '2,85,92,677.90',
                ),
                const SizedBox(height: DesignTokens.s16),
                _StatRow(
                  iconAsset: 'assets/images/icon_conversion_rate.png',
                  iconBgColor: Colors.transparent,
                  iconAssetFill: true,
                  label: 'Conversion Rate',
                  value: '567%',
                ),
                const SizedBox(height: DesignTokens.s16),
                _StatRow(
                  icon: Icons.trending_up_rounded,
                  iconColor: DesignTokens.primaryGreen,
                  iconBgColor: const Color(0xFF1A3A1A),
                  label: 'Gain/Loss (ROI Calculation)',
                  value: '+173%',
                  valueColor: DesignTokens.textWhite,
                ),
              ],
            ),
          ),
          const Divider(
              height: 1, thickness: 1, color: DesignTokens.borderDefault),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Message Creator',
                    onTap: () => context.push(
                      RouteNames.vendorMessageCreator,
                      extra: MessageCreatorArgs(
                        creatorName: args.creatorName,
                        handle: args.handle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.currency_exchange_rounded,
                    label: 'Adjust Commission',
                    onTap: () => context.push(
                      RouteNames.vendorAdjustCommission,
                      extra: AdjustCommissionArgs(
                        creatorName: args.creatorName,
                        handle: args.handle,
                        followersLabel: args.followersLabel,
                        currentCommission: args.commission,
                      ),
                    ),
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

// ─── Stat row ─────────────────────────────────────────────────────────────────

class _StatRow extends StatelessWidget {
  const _StatRow({
    this.iconAsset,
    this.icon,
    this.iconColor = Colors.white,
    required this.iconBgColor,
    required this.label,
    required this.value,
    this.valueColor = DesignTokens.textWhite,
    this.iconAssetFill = false,
  });

  final String? iconAsset;
  final IconData? icon;
  final Color iconColor;
  final Color iconBgColor;
  final String label;
  final String value;
  final Color valueColor;
  final bool iconAssetFill;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconAsset != null
                ? iconAssetFill
                    ? Image.asset(iconAsset!, width: 44, height: 44,
                        fit: BoxFit.cover)
                    : Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(iconAsset!, fit: BoxFit.contain),
                      )
                : Center(
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppFoundation,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: DesignTokens.textLight, size: 22),
            const SizedBox(height: DesignTokens.s6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Performance graph card ───────────────────────────────────────────────────

class _GraphCard extends StatelessWidget {
  const _GraphCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Trend Graph',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Performance Trend Graph of Creator according to sales done',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 12,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          SizedBox(
            height: 210,
            child: CustomPaint(
              painter: _ChartPainter(),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          const Text(
            'Date Range: Dec 1 - 18, 2025',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 11,
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Chart painter ────────────────────────────────────────────────────────────

class _ChartPainter extends CustomPainter {
  static const _yLabels = ['25k', '20k', '15k', '10k', '5k', '0'];
  static const _xLabels = ['Dec 1', 'Dec 7', 'Dec 14', 'Dec 21', 'Dec 28', 'Today'];
  static const _data = [9000.0, 11000.0, 5000.0, 22000.0, 9000.0, 18000.0];
  static const _maxY = 25000.0;

  @override
  void paint(Canvas canvas, Size size) {
    const yAxisWidth = 38.0;
    const xAxisHeight = 22.0;
    const topPad = 8.0;

    final chartLeft = yAxisWidth;
    final chartTop = topPad;
    final chartRight = size.width;
    final chartBottom = size.height - xAxisHeight;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final mutedColor = const Color(0xFF9F9FA9).withOpacity(0.5);
    final labelStyle = TextStyle(
      color: mutedColor,
      fontSize: 10,
      fontFamily: 'Poppins',
    );

    // Horizontal grid lines + Y-axis labels
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    for (int i = 0; i <= 5; i++) {
      final yFrac = i / 5.0;
      final y = chartTop + chartHeight * yFrac;
      canvas.drawLine(
          Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: _yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // Compute data points
    final pts = List.generate(_data.length, (i) {
      final x = chartLeft + chartWidth * i / (_data.length - 1);
      final y = chartTop + chartHeight * (1.0 - _data[i] / _maxY);
      return Offset(x, y);
    });

    // Area fill with gradient
    final areaPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      areaPath.lineTo(pts[i].dx, pts[i].dy);
    }
    areaPath.lineTo(pts.last.dx, chartBottom);
    areaPath.lineTo(chartLeft, chartBottom);
    areaPath.close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignTokens.primaryGreen.withOpacity(0.45),
            DesignTokens.primaryGreen.withOpacity(0.0),
          ],
        ).createShader(
          Rect.fromLTWH(chartLeft, chartTop, chartWidth, chartHeight),
        ),
    );

    // Line stroke
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      linePath.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = DesignTokens.primaryGreen
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // X-axis labels
    for (int i = 0; i < _xLabels.length; i++) {
      final x = chartLeft + chartWidth * i / (_xLabels.length - 1);
      final tp = TextPainter(
        text: TextSpan(text: _xLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartBottom + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) => false;
}

// ─── Tab bar delegate (pinned) ────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({required this.tabCtrl});

  final TabController tabCtrl;

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: DesignTokens.bgAppFoundation,
      child: TabBar(
        controller: tabCtrl,
        tabs: const [Tab(text: 'Products'), Tab(text: 'Reels')],
        indicatorColor: DesignTokens.primaryGreen,
        indicatorWeight: 2,
        labelColor: DesignTokens.primaryGreen,
        unselectedLabelColor: DesignTokens.textMuted,
        labelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        dividerColor: DesignTokens.borderDefault,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabCtrl != tabCtrl;
}

// ─── Products tab ─────────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s16,
      ),
      itemCount: _mockProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) => _ProductRow(product: _mockProducts[i]),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product});

  final _MockProduct product;

  @override
  Widget build(BuildContext context) {
    final hasPriceTag =
        product.price.isNotEmpty;

    return Row(
      children: [
        // Rank
        SizedBox(
          width: 22,
          child: Text(
            '${product.rank}',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            product.imagePath,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 64,
              height: 64,
              color: DesignTokens.bgAppBodyLight,
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined,
                  color: DesignTokens.textMuted, size: 24),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPriceTag
                    ? '${product.price} · ${product.sales} sales'
                    : '· ${product.sales} sales',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── AppBar icon button ───────────────────────────────────────────────────────

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({required this.assetPath, required this.onTap});

  final String assetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          color: DesignTokens.textWhite,
          colorBlendMode: BlendMode.srcIn,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.more_horiz,
            color: DesignTokens.textWhite,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Reels tab ────────────────────────────────────────────────────────────────

class _ReelsTab extends StatelessWidget {
  const _ReelsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No reels data available',
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 14,
          color: DesignTokens.textMuted,
        ),
      ),
    );
  }
}
