import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/auth/jwt_roles.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';
import 'package:stylemint_mobile_frontend/features/notifications/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/root_back_guard.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCreator = ref.watch(isCreatorProvider);
    return RootBackGuard(
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        bottomNavigationBar: const _CreatorBottomNav(),
        body: SafeArea(
          child: isCreator.when(
            loading: _loader,
            error: (_, _) => const _BecomeCreatorCta(),
            data: (creator) =>
                creator ? const _CreatorDashboardView() : const _BecomeCreatorCta(),
          ),
        ),
      ),
    );
  }

  Widget _loader() =>
      const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
}

class _CreatorDashboardView extends ConsumerWidget {
  const _CreatorDashboardView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(creatorDashboardNotifierProvider);
    return state.when(
      initial: _loader,
      loadInProgress: _loader,
      loadSuccess: (dashboard) => _DashboardContent(
        dashboard: dashboard,
        onRefresh: () => ref.read(creatorDashboardNotifierProvider.notifier).load(),
      ),
      loadFailure: (_) => SmErrorView(
        message: 'Failed to load your dashboard.',
        onRetry: () => ref.read(creatorDashboardNotifierProvider.notifier).load(),
      ),
    );
  }

  Widget _loader() =>
      const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
}

class _BecomeCreatorCta extends StatelessWidget {
  const _BecomeCreatorCta();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: DesignTokens.primaryGreen, size: 48),
            const SizedBox(height: DesignTokens.s16),
            Text('Become a Creator',
                style: DesignTokens.sectionInnerTitle, textAlign: TextAlign.center),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Start earning by sharing reels and tagging products. '
              'It only takes a moment to get set up.',
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.s24),
            SizedBox(
              width: double.infinity,
              child: SmPrimaryButton(
                label: 'Get Started',
                height: DesignTokens.buttonHeight,
                borderRadius: DesignTokens.buttonRadius,
                onPressed: () async => context.push(RouteNames.creatorApply),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dashboard content ─────────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard, required this.onRefresh});

  final CreatorDashboard dashboard;
  final VoidCallback onRefresh;

  // MOCK — replace with profile name once the dashboard payload carries it.
  static const String _firstName = 'Creator';

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s16,
          DesignTokens.s32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(firstName: _firstName),
            const SizedBox(height: DesignTokens.s20),
            _QuickMetricsCard(
              earnings: dashboard.earnings,
              deltaPercent: dashboard.earningsDeltaPercent,
              pendingBalance: dashboard.pendingBalance,
              // MOCK — use a real pendingSalesCount field when the backend exposes it.
              pendingSalesCount: dashboard.totalSales,
            ),
            const SizedBox(height: DesignTokens.s16),
            _StatsSection(
              sales: dashboard.totalSales,
              reels: dashboard.topReels.length,
              totalViews: dashboard.totalViews,
            ),
            const SizedBox(height: DesignTokens.s24),
            _TopPerformingReels(reels: dashboard.topReels),
            const SizedBox(height: DesignTokens.s24),
            const _RecentActivity(),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: DesignTokens.bgAppBodyLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.person_rounded, size: 22, color: DesignTokens.textMuted),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back $firstName',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Quick insights to your progress and earnings',
                style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        _HeaderIconBtn(icon: Icons.search_rounded, onTap: () => context.push(RouteNames.search)),
        const SizedBox(width: DesignTokens.s8),
        _HeaderIconBtn(icon: Icons.notifications_none_rounded, onTap: () {}),
        const SizedBox(width: DesignTokens.s8),
        _HeaderIconBtn(icon: Icons.menu_rounded, onTap: () {}),
      ],
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: DesignTokens.buttonGrayFill,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: DesignTokens.textWhite),
      ),
    );
  }
}

// ── Quick Metrics + Payout (single two-tone card) ─────────────────────────────

class _QuickMetricsCard extends StatelessWidget {
  const _QuickMetricsCard({
    required this.earnings,
    required this.deltaPercent,
    required this.pendingBalance,
    required this.pendingSalesCount,
  });

  final Money earnings;
  final double? deltaPercent;
  final Money pendingBalance;
  final int pendingSalesCount;

  static String? _formatDelta(double? pct) {
    if (pct == null) return null;
    final r = pct.round();
    return '${r >= 0 ? '+' : ''}$r%';
  }

  @override
  Widget build(BuildContext context) {
    final amount = formatMoney(earnings);
    final pending = formatMoney(pendingBalance);
    final delta = _formatDelta(deltaPercent);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(DesignTokens.cardRadius)),
      child: Column(
        children: [
          // ── Top half — dark ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: DesignTokens.bgAppBody,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.s16,
              vertical: DesignTokens.s20,
            ),
            child: Column(
              children: [
                _MetricRow(
                  iconBg: DesignTokens.primaryGreenDark,
                  icon: Icons.account_balance_wallet_outlined,
                  iconColor: DesignTokens.primaryGreen,
                  labelWidget: Row(
                    children: [
                      Text(
                        'Total Earned ',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textLight,
                        ),
                      ),
                      if (delta != null)
                        Text(
                          '($delta vs last)',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  value: amount,
                ),
                const SizedBox(height: DesignTokens.s16),
                _MetricRow(
                  iconBg: DesignTokens.warningFillDark,
                  icon: Icons.monetization_on_outlined,
                  iconColor: DesignTokens.secondaryYellow,
                  labelWidget: Text(
                    'Pending from $pendingSalesCount sales',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                  value: pending,
                ),
              ],
            ),
          ),
          // ── Bottom half — yellow ──────────────────────────────────────────
          GestureDetector(
            onTap: () => context.push(RouteNames.earningsPayout),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: double.infinity,
              color: DesignTokens.secondaryYellow,
              padding: const EdgeInsets.all(DesignTokens.s16),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/creatordash/Payout.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Request Payout Withdrawal',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: DesignTokens.textDark,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        const Text(
                          'Payouts are processed weekly on fridays. '
                          'The minimum withdraw amount is Rs 5,000.00',
                          style: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                            color: DesignTokens.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: DesignTokens.iconDark,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.iconBg,
    required this.icon,
    required this.iconColor,
    required this.labelWidget,
    required this.value,
  });

  final Color iconBg;
  final IconData icon;
  final Color iconColor;
  final Widget labelWidget;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(DesignTokens.s4),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(DesignTokens.s8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              labelWidget,
              const SizedBox(height: DesignTokens.s4),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
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

// ── Stats section ─────────────────────────────────────────────────────────────

class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.sales,
    required this.reels,
    required this.totalViews,
  });

  final int sales;
  final int reels;
  final int totalViews;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.favorite_outline_rounded,
                label: 'Sales',
                value: '$sales',
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                icon: Icons.people_outline_rounded,
                label: 'Reels',
                value: '$reels',
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            // MOCK — backend click signals pipeline not yet live.
            const Expanded(
              child: _StatCard(
                icon: Icons.open_in_new_rounded,
                label: 'Clicks',
                value: '0',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        _TotalViewsCard(value: NumberFormat('#,###').format(totalViews)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(DesignTokens.s8),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 24, color: DesignTokens.textWhite),
          ),
          const SizedBox(height: DesignTokens.s8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textLight),
          ),
        ],
      ),
    );
  }
}

class _TotalViewsCard extends StatelessWidget {
  const _TotalViewsCard({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DesignTokens.primaryGreen,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s20,
                DesignTokens.s16,
                DesignTokens.s20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Views',
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: DesignTokens.primaryGreenDark,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: DesignTokens.buttonPrimaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s12),
            child: Image.asset(
              'assets/images/creatordash/hands.png',
              width: 90,
              height: 90,
              fit: BoxFit.contain,
              alignment: Alignment.bottomCenter,
            ),
          ),
          
        ],
      ),
    );
  }
}

// ── Top Performing Reels ──────────────────────────────────────────────────────

class _TopPerformingReels extends StatelessWidget {
  const _TopPerformingReels({required this.reels});

  final List<CreatorReel> reels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Top Performing Reels',
          onViewAll: () => context.push(RouteNames.creatorTopReels),
        ),
        const SizedBox(height: DesignTokens.s12),
        if (reels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
            child: Text(
              'No reels yet — import one to get started.',
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
            ),
          )
        else
          ...reels.map(
            (reel) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s12),
              child: _TopReelCard(reel: reel),
            ),
          ),
      ],
    );
  }
}

class _TopReelCard extends StatelessWidget {
  const _TopReelCard({required this.reel});

  final CreatorReel reel;

  @override
  Widget build(BuildContext context) {
    final title = reel.title.isEmpty ? 'Untitled reel' : reel.title;
    final posted = DateFormat('d MMM, yyyy hh:mm a').format(reel.publishedAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s16,
        DesignTokens.s12,
      ),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail + title + external-link icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.s4),
                child: Container(
                  width: 64,
                  height: 64,
                  color: DesignTokens.bgAppBody,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.play_circle_fill,
                    color: DesignTokens.iconLight,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.s4),
                    Text(
                      'Posted on: $posted',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.s8),
              const Icon(
                Icons.open_in_new_rounded,
                color: DesignTokens.iconLight,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          const Divider(color: DesignTokens.borderDefault, height: 1, thickness: 1),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ReelStat(icon: Icons.visibility_outlined, value: reel.views),
              _ReelStat(icon: Icons.favorite_outline, value: reel.likes),
              _ReelStat(icon: Icons.chat_bubble_outline, value: reel.comments),
              _ReelStat(icon: Icons.share_outlined, value: reel.shares),
            ],
          ),
          // Chevron — visual affordance for expand/navigate
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s20),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 12,
                color: DesignTokens.iconLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelStat extends StatelessWidget {
  const _ReelStat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: DesignTokens.textWhite),
        const SizedBox(height: DesignTokens.s4),
        Text(
          _compact(value),
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.3,
            color: DesignTokens.textWhite,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(2)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(2)}k';
    return '$n';
  }
}

// ── Recent Activity ───────────────────────────────────────────────────────────

class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(recentActivityProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Recent Activity',
          onViewAll: () => context.push(RouteNames.creatorActivity),
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(DesignTokens.s16),
          decoration: DesignTokens.cardDecoration(),
          child: activity.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: DesignTokens.s8),
                child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
              ),
            ),
            error: (_, _) => const _EmptyActivity(),
            data: (items) =>
                items.isEmpty ? const _EmptyActivity() : _GroupedActivityList(items: items),
          ),
        ),
      ],
    );
  }
}

class _GroupedActivityList extends StatelessWidget {
  const _GroupedActivityList({required this.items});

  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<ActivityItem>>{};
    for (final item in items) {
      if (item.occurredAt == null) continue;
      final key = DateFormat('EEE d MMM yyyy').format(item.occurredAt!.toLocal());
      (grouped[key] ??= []).add(item);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s12),
            child: Text(
              entry.key,
              style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
            ),
          ),
          for (var i = 0; i < entry.value.length; i++)
            _ActivityItem(
              item: entry.value[i],
              showConnector: i < entry.value.length - 1,
            ),
          const SizedBox(height: DesignTokens.s8),
        ],
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.item, required this.showConnector});

  final ActivityItem item;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon + optional vertical connector line
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: DesignTokens.bgAppBodyLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: DesignTokens.textWhite,
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1,
                        color: DesignTokens.borderDefault,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          // Activity text + time-ago
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: DesignTokens.s8,
                bottom: showConnector ? DesignTokens.s16 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                  ),
                  if (item.occurredAt != null) ...[
                    const SizedBox(width: DesignTokens.s8),
                    Text(
                      _timeAgo(item.occurredAt!),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _timeAgo(DateTime when) {
    final diff = DateTime.now().toUtc().difference(when.toUtc());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) => Text(
    'No recent activity yet.',
    style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
  );
}

// ── Shared section header ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onViewAll});

  final String title;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: DesignTokens.mediumRegular.copyWith(color: DesignTokens.textLight),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            children: [
              Text(
                'View All',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: DesignTokens.s4),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: DesignTokens.primaryGreen,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────────────────

class _CreatorBottomNav extends StatelessWidget {
  const _CreatorBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(top: BorderSide(color: DesignTokens.borderDefault, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBtn(
            icon: Icons.home_rounded,
            label: 'Home',
            active: true,
            onTap: null,
          ),
          _NavBtn(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            onTap: () => context.push(RouteNames.earnings),
          ),
          GestureDetector(
            onTap: () => context.push(RouteNames.reelImport),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: DesignTokens.primaryGreen,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_rounded,
                color: DesignTokens.buttonPrimaryText,
                size: 26,
              ),
            ),
          ),
          _NavBtn(
            icon: Icons.storefront_outlined,
            label: 'Brands',
            onTap: () => context.push(RouteNames.partnerships),
          ),
          _NavBtn(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            onTap: () => context.push(RouteNames.profile),
          ),
        ],
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? DesignTokens.primaryGreen : DesignTokens.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
