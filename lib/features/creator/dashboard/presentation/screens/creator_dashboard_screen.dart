import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/presentation/widgets/dashboard_stat_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creatorDashboardNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: state.when(
          initial: _loader,
          loadInProgress: _loader,
          loadSuccess: (dashboard) => _DashboardContent(
            dashboard: dashboard,
            onRefresh: () =>
                ref.read(creatorDashboardNotifierProvider.notifier).load(),
          ),
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load your dashboard.',
            onRetry: () =>
                ref.read(creatorDashboardNotifierProvider.notifier).load(),
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

  final CreatorDashboard dashboard;
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
              Text('Creator Dashboard', style: DesignTokens.titleLarge),
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
                  DashboardStatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Earnings',
                    value: formatMoney(dashboard.earnings),
                    color: DesignTokens.primaryGreen,
                  ),
                  DashboardStatCard(
                    icon: Icons.play_circle_outline,
                    label: 'Reels',
                    value: _compactCount(dashboard.totalReels),
                    color: DesignTokens.colorInfo,
                  ),
                  DashboardStatCard(
                    icon: Icons.visibility_outlined,
                    label: 'Total Views',
                    value: _compactCount(dashboard.totalViews),
                    color: DesignTokens.secondaryYellow,
                  ),
                  DashboardStatCard(
                    icon: Icons.favorite_outline,
                    label: 'Engagement',
                    value: _compactCount(dashboard.totalEngagement),
                    color: DesignTokens.colorError,
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
                    label: 'Import Reel',
                    onTap: () => context.push(RouteNames.reelImport),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  _QuickActionChip(
                    icon: Icons.handshake_outlined,
                    label: 'Partnerships',
                    onTap: () {},
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  _QuickActionChip(
                    icon: Icons.trending_up,
                    label: 'Earnings',
                    onTap: () => context.push(RouteNames.earnings),
                  ),
                ],
              ),

              const SizedBox(height: DesignTokens.s24),

              // --- Recent Reels ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Top Performing Reels', style: DesignTokens.sectionInnerTitle),
                  GestureDetector(
                    onTap: () => context.push(RouteNames.reelImport),
                    child: Text(
                      'View All',
                      style: DesignTokens.mediumSemibold.copyWith(
                        color: DesignTokens.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.s12),
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dashboard.recentReels.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: DesignTokens.s12),
                  itemBuilder: (_, i) => _RecentReelCard(
                    reel: dashboard.recentReels[i],
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.s28),

              // --- Reel Studio Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.push(RouteNames.reelImport),
                  style: DesignTokens.primaryButtonStyle(),
                  icon: const Icon(Icons.movie_creation_outlined, size: 20),
                  label: Text(
                    'Reel Studio',
                    style: DesignTokens.oneLinerSemibold.copyWith(
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: DesignTokens.s16),
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

class _RecentReelCard extends StatelessWidget {
  const _RecentReelCard({required this.reel});

  final CreatorReel reel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      decoration: DesignTokens.cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              color: DesignTokens.bgAppBodyLight,
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: DesignTokens.textWhite.withOpacity(0.4),
                  size: 32,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: DesignTokens.textMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _compactViews(reel.views),
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: DesignTokens.colorError,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reel.likes}',
                      style: DesignTokens.smallRegular,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _compactViews(int views) {
    if (views >= 1000) return '${(views / 1000).toStringAsFixed(1)}K';
    return views.toString();
  }
}
