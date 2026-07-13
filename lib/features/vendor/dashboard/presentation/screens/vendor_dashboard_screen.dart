import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/activity/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/vendor_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/widgets/vendor_more_menu_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/root_back_guard.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// Bottom nav tap destinations (null = current screen, stay)
const _navRoutes = [
  null, // 0 Home (current)
  RouteNames.vendorOrders, // 1 Orders
  RouteNames.vendorProducts, // 2 Products
  RouteNames.settings, // 3 Profile
];

class VendorDashboardScreen extends ConsumerStatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  ConsumerState<VendorDashboardScreen> createState() =>
      _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorDashboardNotifierProvider);
    final activityState = ref.watch(vendorActivityPreviewNotifierProvider);
    final pendingActionCounts = ref.watch(vendorPendingActionsNotifierProvider);

    return RootBackGuard(
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgAppFoundation,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: ClipOval(
              child: Image.asset(
                'assets/images/vendordashboard/stylemint logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: DesignTokens.textWhite,
                size: 22,
              ),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(
                Icons.notifications_outlined,
                color: DesignTokens.textWhite,
                size: 22,
              ),
              onPressed: () {},
            ),
            Consumer(
              builder: (ctx, ref, _) => IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  color: DesignTokens.textWhite,
                  size: 22,
                ),
                onPressed: () => showVendorMoreMenu(ctx, ref),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: state.when(
            initial: _loader,
            loadInProgress: _loader,
            loadSuccess: (dashboard) => _DashboardContent(
              dashboard: dashboard,
              activityState: activityState,
              pendingActionCounts: pendingActionCounts,
              onRefresh: () {
                ref.read(vendorDashboardNotifierProvider.notifier).load();
                ref.read(vendorPendingActionsNotifierProvider.notifier).load();
              },
            ),
            loadFailure: (_) => SmErrorView(
              message: 'Failed to load dashboard.',
              onRetry: () =>
                  ref.read(vendorDashboardNotifierProvider.notifier).load(),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      _NavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ),
      _NavItem(
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2,
        label: 'Orders',
        assetIcon: 'assets/images/vendordashboard/nav_orders.png',
      ),
      _NavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: 'Products',
        assetIcon: 'assets/images/vendordashboard/nav_products.png',
      ),
      _NavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
        assetIcon: 'assets/images/vendordashboard/nav_profile.png',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
          top: BorderSide(
            color: DesignTokens.borderDefault.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final selected = _selectedIndex == i;
              return GestureDetector(
                onTap: () {
                  final route = _navRoutes[i];
                  if (route != null) {
                    context.go(route);
                  } else {
                    setState(() => _selectedIndex = i);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      item.assetIcon != null
                          ? Image.asset(
                              item.assetIcon!,
                              width: 24,
                              height: 24,
                              color: selected
                                  ? DesignTokens.primaryGreen
                                  : DesignTokens.textMuted,
                            )
                          : Icon(
                              selected ? item.activeIcon : item.icon,
                              color: selected
                                  ? DesignTokens.primaryGreen
                                  : DesignTokens.textMuted,
                              size: 24,
                            ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          color: selected
                              ? DesignTokens.primaryGreen
                              : DesignTokens.textMuted,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.assetIcon,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? assetIcon;
}

// ── Main content ──────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.dashboard,
    required this.activityState,
    required this.pendingActionCounts,
    required this.onRefresh,
  });

  final VendorDashboard dashboard;
  final VendorActivityState activityState;
  final VendorPendingActionCounts pendingActionCounts;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Quick insights to your progress and earnings of last 30 days',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            _buildRevenueCard(),
            const SizedBox(height: DesignTokens.s16),
            _buildAlertCards(context),
            const SizedBox(height: DesignTokens.s20),
            _buildTopProducts(context),
            const SizedBox(height: DesignTokens.s20),
            _buildRecentActivity(context),
            const SizedBox(height: DesignTokens.s32),
          ],
        ),
      ),
    );
  }

  // ── Revenue card ────────────────────────────────────────────────────────────

  static String? _formatDelta(double? pct) {
    if (pct == null) return null;
    final r = pct.round();
    return '${r >= 0 ? '+' : ''}$r%';
  }

  Widget _buildRevenueCard() {
    final grossSalesDelta = _formatDelta(dashboard.grossSalesDeltaPercent);
    return Column(
      children: [
        // Dark stats card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gross Sales row
              _buildRevenueRow(
                assetIcon: 'assets/images/vendordashboard/icon_gross_sales.png',
                iconBg: const Color(0xFF1A3A1A),
                label: grossSalesDelta != null
                    ? 'Gross Sales ($grossSalesDelta vs last)'
                    : 'Gross Sales',
                amount: formatMoney(dashboard.grossSales),
              ),
              const SizedBox(height: DesignTokens.s16),
              // Net Revenue row
              _buildRevenueRow(
                assetIcon: 'assets/images/vendordashboard/icon_net_revenue.png',
                iconBg: const Color(0xFF0D2137),
                label: 'Net Revenue (After fees & commissions)',
                amount: formatMoney(dashboard.netRevenue),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        // Total Orders Completed green card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: BoxDecoration(
            color: DesignTokens.primaryGreen,
            borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Orders Completed',
                      style: DesignTokens.smallRegular.copyWith(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      _compactCount(dashboard.totalOrders),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Image.asset(
                'assets/images/vendordashboard/total order completed.png',
                width: 64,
                height: 64,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueRow({
    required String assetIcon,
    required Color iconBg,
    required String label,
    required String amount,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Image.asset(assetIcon, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amount,
                style: DesignTokens.mediumSemibold.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _compactCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  // ── Pending Actions ──────────────────────────────────────────────────────────

  Widget _buildAlertCards(BuildContext context) {
    final alerts = [
      _Alert(
        assetIcon: 'assets/images/vendordashboard/icon_order_ship.png',
        title: 'Orders Ready to Ship',
        subtitle: _countSubtitle(
          pendingActionCounts.readyToShip,
          singular: 'order ready to ship',
          plural: 'orders ready to ship',
          zero: 'No orders ready to ship',
          fallback: 'Review and ship pending orders',
        ),
        route: RouteNames.vendorOrdersReadyToShip,
      ),
      _Alert(
        assetIcon: 'assets/images/vendordashboard/icon_order_waiting.png',
        title: 'Order Waiting Tracking Numbers',
        subtitle: _countSubtitle(
          pendingActionCounts.waitingTracking,
          singular: 'order waiting for a tracking number',
          plural: 'orders waiting for tracking numbers',
          zero: 'No orders waiting for tracking numbers',
          fallback: 'Assign tracking numbers to shipped orders',
        ),
        route: RouteNames.vendorOrdersWaitingTracking,
      ),
      _Alert(
        assetIcon: 'assets/images/vendordashboard/icon_chat.png',
        title: 'Pending Customer Inquiries',
        subtitle: _countSubtitle(
          pendingActionCounts.pendingInquiries,
          singular: 'open product question',
          plural: 'open product questions',
          zero: 'No open product questions',
          fallback: 'Reply to open product questions',
        ),
        route: RouteNames.vendorPendingInquiries,
      ),
      _Alert(
        assetIcon: 'assets/images/vendordashboard/icon_partnership.png',
        title: 'Creator Partnership Requests',
        subtitle: _countSubtitle(
          pendingActionCounts.pendingCreatorRequests,
          singular: 'Creator Partnership Request',
          plural: 'Creator Partnership Requests',
          zero: 'No pending requests from creators',
          fallback: 'Review requests from creators',
        ),
        route: RouteNames.vendorCreatorPartnershipRequests,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pending Actions', style: DesignTokens.mediumSemibold),
        const SizedBox(height: DesignTokens.s12),
        Container(
          decoration: DesignTokens.cardDecoration(),
          child: Column(
            children: alerts.asMap().entries.map((entry) {
              final i = entry.key;
              final alert = entry.value;
              return Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: DesignTokens.bgAppBodyLight,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.inputRadius,
                          ),
                        ),
                        child: alert.assetIcon != null
                            ? Padding(
                                padding: const EdgeInsets.all(8),
                                child: Image.asset(
                                  alert.assetIcon!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : const Icon(
                                Icons.notifications_outlined,
                                color: DesignTokens.textWhite,
                                size: 20,
                              ),
                      ),
                      title: Text(
                        alert.title,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        alert.subtitle,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        color: DesignTokens.textMuted,
                        size: 14,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s16,
                        vertical: DesignTokens.s4,
                      ),
                      onTap: alert.route != null
                          ? () => context.push(alert.route!)
                          : null,
                    ),
                  ),
                  if (i < alerts.length - 1)
                    const Divider(
                      color: DesignTokens.borderDefault,
                      height: 1,
                      indent: DesignTokens.s16,
                      endIndent: DesignTokens.s16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// `null` (still loading, or the count call failed) falls back to a
  /// generic description rather than showing a stale/fabricated number.
  static String _countSubtitle(
    int? count, {
    required String singular,
    required String plural,
    required String zero,
    required String fallback,
  }) {
    if (count == null) return fallback;
    if (count == 0) return zero;
    if (count == 1) return '1 $singular';
    return '$count $plural';
  }

  // ── Top Products ────────────────────────────────────────────────────────────

  Widget _buildTopProducts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Top Products (This Month)',
              style: DesignTokens.mediumSemibold,
            ),
            GestureDetector(
              onTap: () => context.push(RouteNames.vendorTopProducts),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: DesignTokens.primaryGreen,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        if (dashboard.topProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
            child: Text(
              'No product sales yet this month.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dashboard.topProducts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: DesignTokens.s12),
            itemBuilder: (_, i) =>
                _ProductCard(product: _toTopProduct(dashboard.topProducts[i])),
          ),
      ],
    );
  }

  static _TopProduct _toTopProduct(VendorTopProduct p) => _TopProduct(
    name: p.name.isEmpty ? 'Unnamed product' : p.name,
    sales: p.unitsSold,
    revenue: formatMoney(p.totalRevenue),
    creators: p.distinctCreatorCount,
    thumbnailUrl: p.thumbnailUrl,
  );

  // ── Recent Activity ──────────────────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: DesignTokens.mediumSemibold.copyWith(
                color: const Color(0xFFD4D4D8),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(RouteNames.vendorRecentActivity),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: DesignTokens.primaryGreen,
                    size: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        if (_activityGroups().isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
            child: Text(
              'No recent activity yet.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          )
        else
          ..._activityGroups().expand(
            (group) => [
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Text(
                  group.date,
                  style: DesignTokens.smallRegular.copyWith(
                    color: const Color(0xFFD4D4D8),
                    fontSize: 12,
                  ),
                ),
              ),
              ...group.items.map((a) => _ActivityTile(activity: a)),
              const SizedBox(height: DesignTokens.s8),
            ],
          ),
      ],
    );
  }

  List<_ActivityGroup> _activityGroups() {
    return activityState.maybeWhen(
      loadSuccess: (entries) {
        final byDate = <String, List<_Activity>>{};
        for (final e in entries) {
          final label = _dateGroupLabel(e.occurredUtc);
          (byDate[label] ??= []).add(
            _Activity(
              title: e.headline?.isNotEmpty == true ? e.headline! : 'Activity',
              description: e.body ?? '',
              time: formatRelative(e.occurredUtc),
              actionLabel: e.actionUrl != null ? 'View' : null,
            ),
          );
        }
        return byDate.entries
            .map((e) => _ActivityGroup(date: e.key, items: e.value))
            .toList();
      },
      orElse: () => const [],
    );
  }

  static String _dateGroupLabel(DateTime utc) {
    final local = utc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    switch (today.difference(day).inDays) {
      case 0:
        return 'Today';
      case 1:
        return 'Yesterday';
      default:
        return DateFormat('EEE d MMM yyyy').format(local);
    }
  }
}

// ── Product card ──────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final _TopProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          // Top row: image + name + arrow
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  child: Container(
                    width: 56,
                    height: 56,
                    color: DesignTokens.bgAppBodyLight,
                    child: product.thumbnailUrl != null
                        ? Image.network(
                            product.thumbnailUrl!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag_outlined,
                              color: DesignTokens.textMuted,
                              size: 24,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            color: DesignTokens.textMuted,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: DesignTokens.smallRegular.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Sales: ${product.sales}',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.open_in_new,
                  color: DesignTokens.textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          // Revenue + creators row
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s12,
              vertical: DesignTokens.s8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.savings_outlined,
                      color: DesignTokens.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Total Revenue',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.s8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2A3A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    product.revenue,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.colorInfo,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s12,
              vertical: DesignTokens.s8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      color: DesignTokens.textMuted,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Sales via',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${product.creators} creators',
                  style: DesignTokens.smallRegular.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Activity tile ─────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final _Activity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: DesignTokens.borderDefault),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_outlined,
                color: DesignTokens.textMuted,
                size: 18,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: DesignTokens.smallRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.description,
                    style: DesignTokens.smallRegular.copyWith(
                      color: const Color(0xFFD4D4D8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.time,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (activity.actionLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      activity.actionLabel!,
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.primaryGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _Alert {
  const _Alert({
    required this.title,
    required this.subtitle,
    this.assetIcon,
    this.route,
  });
  final String? assetIcon;
  final String title;
  final String subtitle;
  final String? route;
}

class _TopProduct {
  const _TopProduct({
    required this.name,
    required this.sales,
    required this.revenue,
    required this.creators,
    this.thumbnailUrl,
  });
  final String name;
  final int sales;
  final String revenue;
  final int creators;
  final String? thumbnailUrl;
}

class _Activity {
  const _Activity({
    required this.title,
    required this.description,
    required this.time,
    this.actionLabel,
  });
  final String title;
  final String description;
  final String time;
  final String? actionLabel;
}

class _ActivityGroup {
  const _ActivityGroup({required this.date, required this.items});
  final String date;
  final List<_Activity> items;
}
