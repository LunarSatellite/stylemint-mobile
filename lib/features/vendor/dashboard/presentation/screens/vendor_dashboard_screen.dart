import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/domain/entities/vendor_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/presentation/widgets/vendor_stat_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/dashboard/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorDashboardNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (dashboard) => _DashboardContent(
            dashboard: dashboard,
            onRefresh: () =>
                ref.read(vendorDashboardNotifierProvider.notifier).load(),
          ),
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load vendor dashboard.',
            onRetry: () =>
                ref.read(vendorDashboardNotifierProvider.notifier).load(),
          ),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard, required this.onRefresh});

  final VendorDashboard dashboard;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vendor Dashboard', style: DesignTokens.titleLarge),
              const SizedBox(height: DesignTokens.s20),

              // --- Stats 2x2 Grid ---
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: DesignTokens.s12,
                crossAxisSpacing: DesignTokens.s12,
                childAspectRatio: 1.4,
                children: [
                  VendorStatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Revenue',
                    value: formatMoney(dashboard.totalRevenue),
                    color: DesignTokens.primaryGreen,
                  ),
                  VendorStatCard(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Orders',
                    value: _compactCount(dashboard.totalOrders),
                    color: DesignTokens.colorInfo,
                  ),
                  VendorStatCard(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    value: _compactCount(dashboard.totalProducts),
                    color: DesignTokens.secondaryYellow,
                  ),
                  VendorStatCard(
                    icon: Icons.star_outline,
                    label: 'Rating',
                    value: dashboard.averageRating.toStringAsFixed(1),
                    color: DesignTokens.colorWarning,
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.s24),

              // --- Alert Cards ---
              Row(
                children: [
                  Expanded(
                    child: VendorStatCard(
                      icon: Icons.pending_outlined,
                      label: 'Pending Fulfillment',
                      value: dashboard.pendingFulfillment.toString(),
                      color: DesignTokens.colorWarning,
                      badge: dashboard.pendingFulfillment,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: VendorStatCard(
                      icon: Icons.warning_amber_outlined,
                      label: 'Low Stock',
                      value: dashboard.lowStockProducts.toString(),
                      color: DesignTokens.colorError,
                      badge: dashboard.lowStockProducts,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.s24),

              // --- Quick Actions ---
              Text('Quick Actions', style: DesignTokens.sectionInnerTitle),
              const SizedBox(height: DesignTokens.s12),
              Row(
                children: [
                  _QuickActionChip(
                    icon: Icons.add_circle_outline,
                    label: 'Add Product',
                    onTap: () => context.push(RouteNames.addProduct),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  _QuickActionChip(
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    onTap: () {},
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  _QuickActionChip(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    onTap: () => context.push(RouteNames.vendorOrders),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s8),
              Row(
                children: [
                  _QuickActionChip(
                    icon: Icons.handshake_outlined,
                    label: 'Partnerships',
                    onTap: () {},
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  _QuickActionChip(
                    icon: Icons.trending_up_outlined,
                    label: 'Earnings',
                    onTap: () => context.push(RouteNames.vendorEarnings),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  const Spacer(flex: 1),
                ],
              ),

              const SizedBox(height: DesignTokens.s24),

              // --- Recent Orders ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Orders', style: DesignTokens.sectionInnerTitle),
                  GestureDetector(
                    onTap: () => context.push(RouteNames.vendorOrders),
                    child: Text(
                      'See All',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),

              if (dashboard.recentOrders.isEmpty)
                _EmptyOrdersView()
              else
                ...dashboard.recentOrders
                    .map((order) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: DesignTokens.s8),
                          child: _RecentOrderTile(order: order),
                        ))
                    .toList(growable: false),

              const SizedBox(height: DesignTokens.s28),
            ],
          ),
        ),
      ),
    );
  }

  static String _compactCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.s12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: DesignTokens.primaryGreen, size: 24),
              const SizedBox(height: DesignTokens.s8),
              Text(
                label,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});

  final VendorOrderSummary order;

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return DesignTokens.secondaryYellow;
      case 'confirmed':
        return DesignTokens.colorInfo;
      case 'processing':
        return DesignTokens.colorInfo;
      case 'shipped':
        return DesignTokens.colorInfo;
      case 'delivered':
        return DesignTokens.colorSuccess;
      case 'cancelled':
        return DesignTokens.colorError;
      case 'returned':
        return DesignTokens.colorWarning;
      default:
        return DesignTokens.textMuted;
    }
  }

  static String _statusLabel(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              color: DesignTokens.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.itemName,
                  style: DesignTokens.mediumSemibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: DesignTokens.smallRegular,
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Text(
                      'x${order.quantity}',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s8,
              vertical: DesignTokens.s4,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _statusLabel(order.status),
              style: DesignTokens.smallRegular.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(order.amount),
                style: DesignTokens.mediumSemibold,
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(order.placedAt),
                style: DesignTokens.smallRegular,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}';
  }
}

class _EmptyOrdersView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s24),
      decoration: DesignTokens.cardDecoration(
        borderColor: DesignTokens.borderDefault.withOpacity(0.4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: DesignTokens.textMuted.withOpacity(0.5),
            size: 40,
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            'No orders yet',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'Orders from your customers will appear here.',
            style: DesignTokens.smallRegular,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
