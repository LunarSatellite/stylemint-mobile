import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/vendor_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/widgets/vendor_more_menu_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/root_back_guard.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final _sampleDashboard = VendorDashboard(
  totalRevenue: const Money(amount: 24512569.98, currency: 'NPR'),
  totalOrders: 250,
  totalProducts: 45,
  averageRating: 4.8,
  pendingFulfillment: 12,
  lowStockProducts: 3,
  recentOrders: [],
);

class VendorDashboardScreen extends ConsumerStatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  ConsumerState<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends ConsumerState<VendorDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorDashboardNotifierProvider);

    return RootBackGuard(
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgAppFoundation,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
            onPressed: () => context.pop(),
          ),
          title: Text('Vendor Dashboard', style: DesignTokens.oneLinerSemibold),
          actions: [
            Consumer(
              builder: (ctx, ref, _) => IconButton(
                icon: const Icon(Icons.settings_outlined, color: DesignTokens.textWhite, size: 22),
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
              onRefresh: () => ref.read(vendorDashboardNotifierProvider.notifier).load(),
            ),
            loadFailure: (_) => _DashboardContent(
              dashboard: _sampleDashboard,
              onRefresh: () => ref.read(vendorDashboardNotifierProvider.notifier).load(),
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    const items = [
      _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Orders', assetIcon: 'assets/images/nav_orders.png'),
      _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Products', assetIcon: 'assets/images/nav_products.png'),
      _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', assetIcon: 'assets/images/nav_profile.png'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(top: BorderSide(color: DesignTokens.borderDefault.withOpacity(0.3))),
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
                onTap: () => setState(() => _selectedIndex = i),
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
                              color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
                            )
                          : Icon(
                              selected ? item.activeIcon : item.icon,
                              color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
                              size: 24,
                            ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          color: selected ? DesignTokens.primaryGreen : DesignTokens.textMuted,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
  const _NavItem({required this.icon, required this.activeIcon, required this.label, this.assetIcon});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? assetIcon;
}

// ── Main content ──────────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard, required this.onRefresh});

  final VendorDashboard dashboard;
  final VoidCallback onRefresh;

  static final _sampleProducts = [
    _TopProduct(name: 'Nike Air Max 2025', sales: 45, revenue: 'Rs 1,35,345', creators: 8, brandColor: const Color(0xFFCC2200), assetImage: 'assets/images/product_nike_air_max.png'),
    _TopProduct(name: 'Nike Air Jordan Travis Scott Limited Edition', sales: 45, revenue: 'Rs 88,550', creators: 4, brandColor: const Color(0xFF3A3A2A), assetImage: 'assets/images/product_nike_air_jordan.png'),
    _TopProduct(name: 'Adidas Ultraboost 24', sales: 28, revenue: 'Rs 55,200', creators: 3, brandColor: const Color(0xFF1A1A2E)),
  ];

  static final _sampleActivities = [
    _ActivityGroup(date: 'Today', items: [
      _Activity(type: _ActivityType.order, title: 'New Order', description: 'New Order #NK2024-8912 - Rs 12,909 via @fashion_sarah', time: '5h ago', actionLabel: 'View Order'),
      _Activity(type: _ActivityType.payout, title: 'Payout Completed', description: 'Your Payout of Rs 12,24,575.00 was processed', time: '5h ago · Bank A/C ******8799', actionLabel: null),
      _Activity(type: _ActivityType.partnership, title: 'Creator Partnership Request', description: 'New Creator Partnership: @style_guru applied to promote your products', time: '5h ago · Bank A/C ******8799', actionLabel: 'Review Application'),
    ]),
    _ActivityGroup(date: 'Wed 23 Jan 2026', items: [
      _Activity(type: _ActivityType.shipped, title: 'Order Shipped', description: 'New Order #NK2024-8905 - Rs 44,909 has been shipped via FedEx', time: '23 Jan at 11:45 PM', actionLabel: 'View Order'),
      _Activity(type: _ActivityType.order, title: 'New Order', description: 'New Order #NK2024-8909 - Rs 18,904 via @fashion_sarah', time: '23 Jan at 06:07 PM', actionLabel: 'View Order'),
    ]),
  ];

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
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12),
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

  Widget _buildRevenueCard() {
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
                assetIcon: 'assets/images/icon_gross_sales.png',
                iconBg: const Color(0xFF1A3A1A),
                label: 'Gross Sales (+23% vs last)',
                amount: formatMoney(const Money(amount: 34512589.98, currency: 'NPR')),
              ),
              const SizedBox(height: DesignTokens.s16),
              // Net Revenue row
              _buildRevenueRow(
                assetIcon: 'assets/images/icon_net_revenue.png',
                iconBg: const Color(0xFF0D2137),
                label: 'Net Revenue (After fees & commissions)',
                amount: formatMoney(dashboard.totalRevenue),
              ),
              const SizedBox(height: DesignTokens.s16),
              // Stat chips
              Row(
                children: [
                  _statChip(assetIcon: 'assets/images/icon_star.png', value: dashboard.averageRating.toStringAsFixed(1), label: 'Rating'),
                  const SizedBox(width: DesignTokens.s8),
                  _statChip(icon: Icons.videocam_outlined, value: '230', label: 'Creators'),
                  const SizedBox(width: DesignTokens.s8),
                  _statChip(assetIcon: 'assets/images/icon_reels.png', value: '89', label: 'Reels'),
                ],
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
                      style: DesignTokens.smallRegular.copyWith(color: Colors.black87, fontSize: 13),
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
              Image.asset('assets/images/icon_orders_completed.png', width: 64, height: 64),
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
                style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11),
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

  Widget _statChip({String? assetIcon, IconData? icon, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (assetIcon != null)
              Image.asset(assetIcon, width: 22, height: 22)
            else if (icon != null)
              Icon(icon, color: DesignTokens.textWhite, size: 22),
            const SizedBox(height: DesignTokens.s4),
            Text(value, style: DesignTokens.mediumSemibold.copyWith(fontSize: 16)),
            Text(label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ── Pending Actions ──────────────────────────────────────────────────────────

  Widget _buildAlertCards(BuildContext context) {
    final alerts = [
      _Alert(assetIcon: 'assets/images/icon_order_ship.png', title: 'Orders Ready to Ship', subtitle: 'You have ${dashboard.pendingFulfillment} orders ready to ship', route: RouteNames.vendorOrdersReadyToShip),
      _Alert(assetIcon: 'assets/images/icon_order_waiting.png', title: 'Order Waiting Tracking Numbers', subtitle: 'You have 5 orders waiting tracking numbers', route: RouteNames.vendorOrdersWaitingTracking),
      _Alert(assetIcon: 'assets/images/icon_pending_inquiries.png', title: 'Pending Customer Inquiries', subtitle: 'You have 3 customer enquiries pending', route: RouteNames.vendorPendingInquiries),
      _Alert(assetIcon: 'assets/images/icon_handshake.png', title: 'Creator Partnership Requests', subtitle: 'You have 2 Creator Partnership Requests', route: RouteNames.vendorCreatorPartnershipRequests),
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
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DesignTokens.bgAppBodyLight,
                        borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                      ),
                      child: alert.assetIcon != null
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: Image.asset(alert.assetIcon!, fit: BoxFit.contain),
                            )
                          : Icon(alert.icon, color: DesignTokens.textWhite, size: 20),
                    ),
                    title: Text(
                      alert.title,
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      alert.subtitle,
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: DesignTokens.textMuted, size: 14),
                    contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s4),
                    onTap: alert.route != null ? () => context.push(alert.route!) : null,
                  ),
                  if (i < alerts.length - 1)
                    const Divider(color: DesignTokens.borderDefault, height: 1, indent: DesignTokens.s16, endIndent: DesignTokens.s16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Top Products ────────────────────────────────────────────────────────────

  Widget _buildTopProducts(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Top Products (This Month)', style: DesignTokens.mediumSemibold),
            GestureDetector(
              onTap: () => context.push(RouteNames.vendorTopProducts),
              child: Row(
                children: [
                  Text('View All', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.primaryGreen)),
                  const Icon(Icons.arrow_forward_ios, color: DesignTokens.primaryGreen, size: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _sampleProducts.length,
          separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
          itemBuilder: (_, i) => _ProductCard(product: _sampleProducts[i]),
        ),
      ],
    );
  }

  // ── Recent Activity ──────────────────────────────────────────────────────────

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Activity', style: DesignTokens.mediumSemibold.copyWith(color: const Color(0xFFD4D4D8))),
            GestureDetector(
              onTap: () => context.push(RouteNames.vendorRecentActivity),
              child: Row(
                children: [
                  Text('View All', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.primaryGreen)),
                  const Icon(Icons.arrow_forward_ios, color: DesignTokens.primaryGreen, size: 12),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        ..._sampleActivities.expand((group) => [
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s8),
            child: Text(
              group.date,
              style: DesignTokens.smallRegular.copyWith(color: const Color(0xFFD4D4D8), fontSize: 12),
            ),
          ),
          ...group.items.map((a) => _ActivityTile(activity: a)),
          const SizedBox(height: DesignTokens.s8),
        ]),
      ],
    );
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
                  child: product.assetImage != null
                      ? Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFFFFFFFF),
                          child: Image.asset(product.assetImage!, width: 56, height: 56, fit: BoxFit.cover),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: product.brandColor,
                          child: Icon(Icons.shopping_bag_outlined, color: Colors.white.withOpacity(0.6), size: 24),
                        ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total Sales: ${product.sales}',
                        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.open_in_new, color: DesignTokens.textMuted, size: 16),
              ],
            ),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          // Revenue + creators row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: DesignTokens.s8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.savings_outlined, color: DesignTokens.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text('Total Revenue', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2A3A),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    product.revenue,
                    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.colorInfo, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: DesignTokens.s8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: DesignTokens.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text('Sales via', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
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
              child: const Icon(Icons.access_time_outlined, color: DesignTokens.textMuted, size: 18),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title, style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w600, color: const Color(0xFFFFFFFF))),
                  const SizedBox(height: 2),
                  Text(
                    activity.description,
                    style: DesignTokens.smallRegular.copyWith(color: const Color(0xFFD4D4D8), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(activity.time, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11)),
                  if (activity.actionLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      activity.actionLabel!,
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.primaryGreen, fontWeight: FontWeight.w600, fontSize: 12),
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
  const _Alert({this.icon, this.assetIcon, required this.title, required this.subtitle, this.route});
  final IconData? icon;
  final String? assetIcon;
  final String title;
  final String subtitle;
  final String? route;
}

class _TopProduct {
  const _TopProduct({required this.name, required this.sales, required this.revenue, required this.creators, required this.brandColor, this.assetImage});
  final String name;
  final int sales;
  final String revenue;
  final int creators;
  final Color brandColor;
  final String? assetImage;
}

enum _ActivityType { order, payout, partnership, shipped }

class _Activity {
  const _Activity({required this.type, required this.title, required this.description, required this.time, this.actionLabel});
  final _ActivityType type;
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

class _AppBarIconButton extends StatelessWidget {
  const _AppBarIconButton({required this.icon, required this.onTap});
  final IconData icon;
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
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: DesignTokens.textWhite, size: 18),
      ),
    );
  }
}
