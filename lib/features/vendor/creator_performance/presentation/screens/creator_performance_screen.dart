import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/domain/entities/creator_performance.dart';
import 'package:stylemint_mobile_frontend/features/vendor/creator_performance/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorPerformanceScreen extends ConsumerStatefulWidget {
  const CreatorPerformanceScreen({super.key});

  @override
  ConsumerState<CreatorPerformanceScreen> createState() =>
      _CreatorPerformanceScreenState();
}

class _CreatorPerformanceScreenState
    extends ConsumerState<CreatorPerformanceScreen> {
  String _sortBy = 'Revenue';
  String _metric = 'Performance';

  static const Map<String, String> _sortApiMap = {
    'Revenue': 'revenue',
    'Sales': 'sales',
    'Views': 'views',
    'Commission': 'commission',
  };

  static const Map<String, String?> _windowApiMap = {
    'Performance': null,
    'Last 30 days': '30d',
    'Last 90 days': '90d',
  };

  void _reload() {
    unawaited(
      ref.read(creatorPerformanceNotifierProvider.notifier).load(
            sortBy: _sortApiMap[_sortBy],
            window: _windowApiMap[_metric],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creatorPerformanceNotifierProvider);

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
            child: state.when(
              initial: _loader,
              loadInProgress: _loader,
              loadSuccess: (creators) => creators.isEmpty
                  ? const Center(
                      child: Text(
                        'No creator data available.',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.s16,
                          vertical: DesignTokens.s12),
                      itemCount: creators.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: DesignTokens.s12),
                      itemBuilder: (_, i) =>
                          _CreatorCard(creator: creators[i]),
                    ),
              loadFailure: (failure) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to load creator performance.',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _reload,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loader() => const Center(child: CircularProgressIndicator());

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
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF1C1C1E),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => _PickSheet(
          title: 'Sort By',
          options: const ['Revenue', 'Sales', 'Views', 'Commission'],
          selected: _sortBy,
          onPick: (v) {
            setState(() => _sortBy = v);
            _reload();
          },
        ),
      ),
    );
  }

  void _showMetricSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF1C1C1E),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (_) => _PickSheet(
          title: 'Metric',
          options: const ['Performance', 'Last 30 days', 'Last 90 days'],
          selected: _metric,
          onPick: (v) {
            setState(() => _metric = v);
            _reload();
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Creator card
// ---------------------------------------------------------------------------

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.creator});
  final CreatorPerformance creator;

  String _formatMoney(double amount, String currency) {
    final prefix = currency == 'NPR' ? 'Rs ' : '$currency ';
    return '$prefix${amount.toStringAsFixed(2)}';
  }

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
                _Avatar(url: creator.creatorAvatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        creator.label,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        creator.formattedHandle,
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

          _dashedDivider(),

          _StatRow(
            assetIcon: 'assets/images/vendordashboard/Revenue.png',
            label: 'Revenue Generated',
            trailing: _blueChip(
                _formatMoney(creator.attributedRevenue, creator.currency)),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            assetIcon: 'assets/images/vendordashboard/icon_reels.png',
            label: 'Active Reels',
            trailing: _plainValue('${creator.distinctReelCount}'),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            icon: Icons.shopping_bag_outlined,
            label: 'Sales',
            trailing: _plainValue('${creator.unitsSold}'),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            assetIcon:
                'assets/images/vendordashboard/icon_pending_inquiries.png',
            label: 'Commission Paid',
            trailing: _plainValue(
                _formatMoney(creator.commissionPaid, creator.currency)),
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
      const dashW = 6.0;
      const dashGap = 4.0;
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
  const _StatRow(
      {required this.label, required this.trailing, this.icon, this.assetIcon});
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
  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF2C2C2E),
        ),
        child: const Icon(Icons.person, color: Color(0xFF9F9FA9), size: 24),
      );
    }
    return ClipOval(
      child: Image.network(
        url!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
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
