import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorPerformanceScreen extends StatefulWidget {
  const CreatorPerformanceScreen({super.key});

  @override
  State<CreatorPerformanceScreen> createState() =>
      _CreatorPerformanceScreenState();
}

class _CreatorPerformanceScreenState extends State<CreatorPerformanceScreen> {
  String _sortBy = 'Revenue';
  String _metric = 'Performance';

  static const _creators = [
    _Creator(
      name: 'Nhuga Fitness',
      handle: '@nhuga_fitness',
      avatarUrl:
          'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=100',
      revenue: 'Rs 4,56,770.09',
      activeReels: 5,
      sales: 389,
      views: '127.8m',
      commissionPaid: 'Rs 23,889.98',
      conversionRate: '88%',
    ),
    _Creator(
      name: 'Zin Rabia',
      handle: '@rabia.zin',
      avatarUrl:
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100',
      revenue: 'Rs 3,56,876',
      reelsPublished: 8,
      sales: 345,
      views: '16.8m',
      commissionPaid: 'Rs 23,889.98',
      conversionRate: '78%',
    ),
    _Creator(
      name: 'Shree Teen',
      handle: '@alieen.ace43',
      avatarUrl:
          'https://images.unsplash.com/photo-1499952127939-9bbf5af6c51c?w=100',
      revenue: 'Rs 1,25,569.96',
      reelsPublished: 12,
      sales: 201,
      views: '9.4m',
      commissionPaid: 'Rs 12,445.50',
      conversionRate: '61%',
    ),
  ];

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
          onPressed: () => context.pop(),
        ),
        title: const Text('Creator Performance',
            style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: const Icon(Icons.search,
                color: DesignTokens.textWhite, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
              itemCount: _creators.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: DesignTokens.s12),
              itemBuilder: (_, i) => _CreatorCard(creator: _creators[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
      child: Row(
        children: [
          _Chip(label: 'Filter', leadingIcon: Icons.tune, onTap: () {}),
          const SizedBox(width: DesignTokens.s8),
          _Chip(
            label: 'Sort By',
            trailingIcon: Icons.keyboard_arrow_down,
            onTap: _showSortSheet,
          ),
          const SizedBox(width: DesignTokens.s8),
          _Chip(
            label: _metric,
            trailingIcon: Icons.keyboard_arrow_down,
            onTap: _showMetricSheet,
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PickSheet(
        title: 'Sort By',
        options: const ['Revenue', 'Sales', 'Views', 'Commission'],
        selected: _sortBy,
        onPick: (v) => setState(() => _sortBy = v),
      ),
    );
  }

  void _showMetricSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _PickSheet(
        title: 'Metric',
        options: const ['Performance', 'Last 30 days', 'Last 90 days'],
        selected: _metric,
        onPick: (v) => setState(() => _metric = v),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Creator card
// ---------------------------------------------------------------------------

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.creator});
  final _Creator creator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: avatar + name/handle + 3-dot
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
            child: Row(
              children: [
                _Avatar(url: creator.avatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creator.name,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        creator.handle,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 12,
                          color: Color(0xFF9F9FA9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Color(0xFF9F9FA9), size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Dashed divider
          _dashedDivider(),

          // Stats rows
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/Revenue.png',
            label: 'Revenue Generated',
            trailing: _blueChip(creator.revenue),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/icon_reels.png',
            label: creator.activeReels != null ? 'Active Reels' : 'Reels Published',
            trailing: _plainValue(
                '${creator.activeReels ?? creator.reelsPublished}'),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            icon: Icons.shopping_bag_outlined,
            label: 'Sales',
            trailing: _plainValue('${creator.sales}'),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            icon: Icons.visibility_outlined,
            label: 'Views',
            trailing: _plainValue(creator.views),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/icon_pending_inquiries.png',
            label: 'Commission Paid',
            trailing: _plainValue(creator.commissionPaid),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            icon: Icons.trending_up,
            label: 'Conversion Rate',
            trailing: _plainValue(creator.conversionRate),
          ),
        ],
      ),
    );
  }

  Widget _blueChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFB8E6FE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D1B2A),
        ),
      ),
    );
  }

  Widget _plainValue(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: DesignTokens.textWhite,
      ),
    );
  }

  Widget _dashedDivider() {
    return LayoutBuilder(builder: (_, constraints) {
      const dashW = 6.0, dashGap = 4.0;
      final count = (constraints.maxWidth / (dashW + dashGap)).floor();
      return Row(
        children: List.generate(
          count,
          (_) => Container(
            width: dashW,
            height: 1,
            margin: const EdgeInsets.only(right: dashGap),
            color: DesignTokens.borderDefault,
          ),
        ),
      );
    });
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({this.icon, this.assetIcon, required this.label, required this.trailing});
  final IconData? icon;
  final String? assetIcon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (assetIcon != null)
            Image.asset(assetIcon!, width: 15, height: 15)
          else if (icon != null)
            Icon(icon, size: 15, color: const Color(0xFF9F9FA9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                color: Color(0xFF9F9FA9),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 48,
          height: 48,
          color: const Color(0xFF2C2C2E),
          child: const Icon(Icons.person, color: Color(0xFF9F9FA9), size: 24),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip widget
// ---------------------------------------------------------------------------

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.onTap,
      this.leadingIcon,
      this.trailingIcon});
  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF3A3A3C)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: DesignTokens.textMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 12,
                color: DesignTokens.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 2),
              Icon(trailingIcon, size: 16, color: DesignTokens.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet for picking a sort/metric option
// ---------------------------------------------------------------------------

class _PickSheet extends StatelessWidget {
  const _PickSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onPick,
  });
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textWhite,
                    )),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: Color(0xFF9F9FA9), size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...options.map((opt) => RadioListTile<String>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: opt,
                  groupValue: selected,
                  activeColor: DesignTokens.primaryGreen,
                  title: Text(opt,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 13,
                        color: DesignTokens.textWhite,
                      )),
                  onChanged: (v) {
                    if (v != null) {
                      onPick(v);
                      Navigator.pop(context);
                    }
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class _Creator {
  const _Creator({
    required this.name,
    required this.handle,
    required this.avatarUrl,
    required this.revenue,
    this.activeReels,
    this.reelsPublished,
    required this.sales,
    required this.views,
    required this.commissionPaid,
    required this.conversionRate,
  });

  final String name;
  final String handle;
  final String avatarUrl;
  final String revenue;
  final int? activeReels;
  final int? reelsPublished;
  final int sales;
  final String views;
  final String commissionPaid;
  final String conversionRate;
}
