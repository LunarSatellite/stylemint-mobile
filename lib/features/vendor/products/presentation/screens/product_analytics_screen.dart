import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ProductAnalyticsScreen extends StatefulWidget {
  const ProductAnalyticsScreen({required this.product, super.key});

  final VendorProduct product;

  @override
  State<ProductAnalyticsScreen> createState() =>
      _ProductAnalyticsScreenState();
}

class _ProductAnalyticsScreenState extends State<ProductAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedFilter = 1;
  late final TabController _reviewTabController;

  static const _filters = ['Custom Date', 'Last 7 days', 'Last 30 days', 'Last 90 days'];

  @override
  void initState() {
    super.initState();
    _reviewTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _reviewTabController.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: DesignTokens.textWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text('Product Analytics', style: DesignTokens.oneLinerSemibold),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date filter chips
            _DateFilterRow(
              filters: _filters,
              selected: _selectedFilter,
              onSelected: (i) => setState(() => _selectedFilter = i),
            ),
            // Date range label
            const Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16, vertical: DesignTokens.s4),
              child: Text(
                'Date Range: Dec 1 - 18, 2025',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DesignTokens.s8),
                  // Product card
                  _ProductHeader(product: widget.product),
                  const SizedBox(height: DesignTokens.s20),
                  // Earnings chart + stats
                  _EarningsSection(),
                  const SizedBox(height: DesignTokens.s20),
                  // Age group donut
                  const _AgeTrafficSection(),
                  const SizedBox(height: DesignTokens.s20),
                  // Reviews
                  _ReviewsSection(tabController: _reviewTabController),
                  const SizedBox(height: DesignTokens.s20),
                  // Gender bar
                  const _GenderTrafficSection(),
                  const SizedBox(height: DesignTokens.s20),
                  // Creator list
                  const _CreatorTrafficSection(),
                  const SizedBox(height: DesignTokens.s20),
                  // Location donut
                  const _LocationTrafficSection(),
                  const SizedBox(height: DesignTokens.s32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Date filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.s8),
        itemBuilder: (_, i) {
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s12, vertical: DesignTokens.s6),
              decoration: BoxDecoration(
                color: isSelected
                    ? DesignTokens.primaryGreen.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.primaryGreen
                      : DesignTokens.borderDefault,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i == 0) ...[
                    const Icon(Icons.calendar_month_outlined,
                        size: 14, color: DesignTokens.textMuted),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    filters[i],
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      color: isSelected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// â”€â”€ Product header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final VendorProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Image.network(
              product.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(Icons.image, color: DesignTokens.textMuted),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: DesignTokens.mediumSemibold,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  product.commissionRate != null
                      ? '${formatMoney(product.price)} Â· ${product.commissionRate!.toStringAsFixed(0)}% Commission'
                      : formatMoney(product.price),
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Earnings section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _EarningsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart card
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Earnings Overview', style: DesignTokens.mediumSemibold),
              const SizedBox(height: 2),
              Text('Sales Trend Graph',
                  style: DesignTokens.tiny
                      .copyWith(color: DesignTokens.textMuted)),
              const SizedBox(height: DesignTokens.s16),
              SizedBox(
                height: 160,
                child: CustomPaint(
                  painter: _EarningsChartPainter(),
                  size: const Size(double.infinity, 160),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        // Total Revenue â€” full width
        _StatCard(
          icon: Icons.monetization_on_outlined,
          value: 'Rs 15,56,784.69',
          label: 'Total Revenue',
          fullWidth: true,
        ),
        const SizedBox(height: DesignTokens.s8),
        // Conversion Rate | Avg. Order Value
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.sync_alt_outlined,
                value: '10.25%',
                label: 'Conversion Rate',
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                icon: Icons.credit_card_outlined,
                value: formatMoney(const Money(amount: 5478, currency: 'NPR')),
                label: 'Avg. Order Value',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        // Added Cart | Units Sold
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.shopping_cart_outlined,
                value: '562 (0.24%)',
                label: 'Added Cart',
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_outlined,
                value: '187',
                label: 'Units Sold',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        // View to Purchase Ratio â€” full width
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.remove_red_eye_outlined,
                      size: 22, color: DesignTokens.textMuted),
                  SizedBox(width: DesignTokens.s8),
                  Text(':',
                      style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 18,
                          color: DesignTokens.textMuted)),
                  SizedBox(width: DesignTokens.s8),
                  Icon(Icons.inventory_2_outlined,
                      size: 22, color: DesignTokens.textMuted),
                ],
              ),
              const SizedBox(height: DesignTokens.s4),
              Text('10 : 4',
                  style: DesignTokens.mediumSemibold.copyWith(fontSize: 18)),
              const SizedBox(height: 2),
              Text('View to Purchase Ratio',
                  style: DesignTokens.tiny
                      .copyWith(color: DesignTokens.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.fullWidth = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: Icon(icon, size: 20, color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(value,
              style: DesignTokens.mediumSemibold.copyWith(fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  DesignTokens.tiny.copyWith(color: DesignTokens.textMuted)),
        ],
      ),
    );
  }
}

// â”€â”€ Age group donut â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AgeTrafficSection extends StatelessWidget {
  const _AgeTrafficSection();

  static const _segments = [
    _PieSegment('18-24', 0.55, Color(0xFFFB923C)),
    _PieSegment('25-34', 0.20, Color(0xFF38BDF8)),
    _PieSegment('35-44', 0.09, Color(0xFF4ADE80)),
    _PieSegment('45+',   0.16, Color(0xFFFBBF24)),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Traffic Source as per Age group',
      subtitle: 'Customer Demographic according to different age groups',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _DonutWithLabelsPainter(_segments),
              size: const Size(double.infinity, 200),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          _LegendRow(segments: _segments),
        ],
      ),
    );
  }
}

// â”€â”€ Reviews â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.tabController});

  final TabController tabController;

  static const _reelViews = ['12.3m', '408k', '1.5m', '989k', '989k', '12.3m'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating row
          Row(
            children: [
              const Icon(Icons.star, color: DesignTokens.secondaryYellow, size: 16),
              const SizedBox(width: 4),
              Text('4.9',
                  style: DesignTokens.smallRegular
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 6),
              Text('Â·  Customer Reviews & Rating (1,275)',
                  style: DesignTokens.tiny
                      .copyWith(color: DesignTokens.textMuted)),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          // Tabs
          TabBar(
            controller: tabController,
            indicatorColor: DesignTokens.primaryGreen,
            indicatorWeight: 2,
            labelColor: DesignTokens.primaryGreen,
            unselectedLabelColor: DesignTokens.textMuted,
            labelStyle: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w400),
            dividerColor: DesignTokens.borderDefault,
            tabs: const [Tab(text: 'Reel Reviews'), Tab(text: 'Written Reviews')],
          ),
          const SizedBox(height: DesignTokens.s12),
          // 3Ã—2 grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: DesignTokens.s6,
              mainAxisSpacing: DesignTokens.s6,
              childAspectRatio: 1,
            ),
            itemCount: _reelViews.length,
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: DesignTokens.bgAppBodyLight),
                  const Icon(Icons.play_circle_outline,
                      color: DesignTokens.textMuted),
                  Positioned(
                    left: 4,
                    bottom: 4,
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye_outlined,
                            size: 10, color: Colors.white70),
                        const SizedBox(width: 2),
                        Text(_reelViews[i],
                            style: const TextStyle(
                                fontFamily: DesignTokens.fontFamily,
                                fontSize: 10,
                                color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DesignTokens.borderDefault),
                foregroundColor: DesignTokens.textWhite,
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.buttonRadius)),
              ),
              child: Text('See all reviews', style: DesignTokens.mediumSemibold),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Gender bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _GenderTrafficSection extends StatelessWidget {
  const _GenderTrafficSection();

  static const _segments = [
    _PieSegment('Female', 0.54, Color(0xFF38BDF8)),
    _PieSegment('Male',   0.26, Color(0xFF4ADE80)),
    _PieSegment('Others', 0.20, Color(0xFFFBBF24)),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Traffic Source as per Gender',
      subtitle: 'Customer Demographic according to different genders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 20,
              child: Row(
                children: _segments.map((s) {
                  return Expanded(
                    flex: (s.value * 100).round(),
                    child: Container(color: s.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          // Labels
          ..._segments.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Row(
                  children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: Text(s.label,
                          style: DesignTokens.smallRegular
                              .copyWith(color: DesignTokens.textLight)),
                    ),
                    Text('${(s.value * 100).toStringAsFixed(0)}%',
                        style: DesignTokens.smallRegular.copyWith(
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.textWhite)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// â”€â”€ Creator list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CreatorTrafficSection extends StatelessWidget {
  const _CreatorTrafficSection();

  static const _creators = [
    _Creator('@rabia.zin',          '23 Sales', '12 Reels'),
    _Creator('@eljanes',            '18 Sales', '9 Reels'),
    _Creator('@mikethestoryteller', '15 Sales', '7 Reels'),
    _Creator('@immovableroyale',    '11 Sales', '6 Reels'),
    _Creator('@lucassinss',         '9 Sales',  '6 Reels'),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Traffic Source as per Creator',
      subtitle: 'Customer Demographic according to different creators',
      child: Column(
        children: _creators.asMap().entries.map((e) {
          final i = e.key;
          final c = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s16),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Text('${i + 1}',
                      style: DesignTokens.smallRegular
                          .copyWith(color: DesignTokens.textMuted)),
                ),
                const SizedBox(width: DesignTokens.s8),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: DesignTokens.bgAppBodyLight,
                  child: const Icon(Icons.person,
                      color: DesignTokens.textMuted, size: 20),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.handle,
                          style: DesignTokens.smallRegular
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.shopping_bag_outlined,
                              size: 12, color: DesignTokens.textMuted),
                          const SizedBox(width: 4),
                          Text(c.sales,
                              style: DesignTokens.tiny
                                  .copyWith(color: DesignTokens.textMuted)),
                          const SizedBox(width: DesignTokens.s12),
                          const Icon(Icons.play_circle_outline,
                              size: 12, color: DesignTokens.textMuted),
                          const SizedBox(width: 4),
                          Text(c.reels,
                              style: DesignTokens.tiny
                                  .copyWith(color: DesignTokens.textMuted)),
                        ],
                      ),
                    ],
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

class _Creator {
  const _Creator(this.handle, this.sales, this.reels);
  final String handle;
  final String sales;
  final String reels;
}

// â”€â”€ Location donut â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LocationTrafficSection extends StatelessWidget {
  const _LocationTrafficSection();

  static const _segments = [
    _PieSegment('New York', 0.22, Color(0xFF38BDF8)),
    _PieSegment('Chicago',  0.28, Color(0xFFFB923C)),
    _PieSegment('Miami',    0.25, Color(0xFFEF4444)),
    _PieSegment('Berlin',   0.16, Color(0xFFFBBF24)),
    _PieSegment('Others',   0.09, Color(0xFF4ADE80)),
  ];

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Traffic Source as per Location',
      subtitle: 'Customer Demographic according to different locations',
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: _DonutWithLabelsPainter(_segments),
              size: const Size(double.infinity, 200),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          _LegendRow(segments: _segments),
        ],
      ),
    );
  }
}

// â”€â”€ Shared widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DesignTokens.mediumSemibold),
        const SizedBox(height: 2),
        Text(subtitle,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted)),
        const SizedBox(height: DesignTokens.s12),
        Container(
          width: double.infinity,
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: child,
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segments});

  final List<_PieSegment> segments;

  @override
  Widget build(BuildContext context) {
    // arrange in rows of 3
    final rows = <List<_PieSegment>>[];
    for (var i = 0; i < segments.length; i += 3) {
      rows.add(segments.sublist(i, math.min(i + 3, segments.length)));
    }
    return Column(
      children: rows
          .map((row) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s6),
                child: Row(
                  children: row
                      .map((s) => Expanded(
                            child: Row(
                              children: [
                                Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                        color: s.color,
                                        shape: BoxShape.circle)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(s.label,
                                      style: DesignTokens.tiny.copyWith(
                                          color: DesignTokens.textLight),
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ))
          .toList(),
    );
  }
}

// â”€â”€ Data model â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PieSegment {
  const _PieSegment(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

// â”€â”€ Painters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _DonutWithLabelsPainter extends CustomPainter {
  const _DonutWithLabelsPainter(this.segments);

  final List<_PieSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeW = 28.0;
    const gap = 0.03;

    var startAngle = -math.pi / 2;

    for (final seg in segments) {
      final sweepAngle = seg.value * 2 * math.pi - gap;

      // Arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeW / 2),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );

      // Percentage label on arc midpoint
      final midAngle = startAngle + sweepAngle / 2;
      final labelR = radius - strokeW / 2;
      final labelOffset = Offset(
        center.dx + labelR * math.cos(midAngle),
        center.dy + labelR * math.sin(midAngle),
      );

      final pct = '${(seg.value * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: pct,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        labelOffset - Offset(tp.width / 2, tp.height / 2),
      );

      startAngle += sweepAngle + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EarningsChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const yLabels = ['25k', '20k', '15k', '10k', '5k', '0'];
    const xLabels = ['Dec 1', 'Dec 7', 'Dec 14', 'Dec 21', 'Dec 28', 'Today'];
    const yValues = [0.32, 0.42, 0.24, 0.60, 0.40, 0.76];

    const leftPad = 36.0;
    const bottomPad = 24.0;
    const topPad = 8.0;

    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;

    // Grid lines + Y labels
    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    final labelStyle = TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 10,
      color: DesignTokens.textMuted,
    );

    for (var i = 0; i < yLabels.length; i++) {
      final y = topPad + chartH * i / (yLabels.length - 1);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(text: yLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // X labels
    for (var i = 0; i < xLabels.length; i++) {
      final x = leftPad + chartW * i / (xLabels.length - 1);
      final tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas,
          Offset(x - tp.width / 2,
              topPad + chartH + 6));
    }

    // Data points
    final pts = List.generate(
      yValues.length,
      (i) => Offset(
        leftPad + chartW * i / (yValues.length - 1),
        topPad + chartH * (1 - yValues[i]),
      ),
    );

    // Area fill
    final areaPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      areaPath.cubicTo(
          cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    areaPath
      ..lineTo(pts.last.dx, topPad + chartH)
      ..lineTo(pts.first.dx, topPad + chartH)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignTokens.primaryGreen.withValues(alpha: 0.5),
            DesignTokens.primaryGreen.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH)),
    );

    // Line
    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      linePath.cubicTo(
          cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = DesignTokens.primaryGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Dot at last point
    canvas.drawCircle(
      pts.last,
      4,
      Paint()..color = DesignTokens.primaryGreen,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
