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

/// Creator Dashboard — rebuilt to the design spec: welcome header, green/yellow
/// earnings+payout hero card, a Sales/Reels/Clicks + Total Views stat row, a
/// "Top Performing Reels" list, and a day-grouped "Recent Activity" feed.
///
/// Real data (earnings, reels, views, recent reels) comes from
/// [CreatorDashboard]. Fields the API does not yet expose — first name, the
/// "+% vs last" delta, pending-sales count, Sales/Clicks counts, reel titles,
/// and the activity feed — are rendered from clearly-marked `MOCK` placeholders
/// until the backend surfaces them.
class CreatorDashboardScreen extends ConsumerWidget {
  const CreatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gate on the Creator role. A Customer-only token would get 403 from
    // /v1/creator/analytics/dashboard, so we never fire that call without the
    // role — we show a "Become a creator" CTA instead. The dashboard notifier
    // is only instantiated (lazily) inside [_CreatorDashboardView].
    final isCreator = ref.watch(isCreatorProvider);

    return RootBackGuard(
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        body: SafeArea(
          child: isCreator.when(
            loading: _loader,
            error: (_, __) => const _BecomeCreatorCta(),
            data: (creator) => creator
                ? const _CreatorDashboardView()
                : const _BecomeCreatorCta(),
          ),
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

/// The actual dashboard, only built once the Creator role is confirmed — so
/// `creatorDashboardNotifierProvider` (which auto-loads) never fires for a
/// non-creator.
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
        onRefresh: () =>
            ref.read(creatorDashboardNotifierProvider.notifier).load(),
      ),
      loadFailure: (failure) => SmErrorView(
        message: 'Failed to load your dashboard.',
        onRetry: () =>
            ref.read(creatorDashboardNotifierProvider.notifier).load(),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

/// Shown to a signed-in user who does not yet hold the Creator role. Routes
/// into the creator activation flow.
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
            const Icon(
              Icons.auto_awesome,
              color: DesignTokens.primaryGreen,
              size: 48,
            ),
            const SizedBox(height: DesignTokens.s16),
            Text(
              'Become a Creator',
              style: DesignTokens.sectionInnerTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Start earning by sharing reels and tagging products. '
              'It only takes a moment to get set up.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textLight,
              ),
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

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.dashboard, required this.onRefresh});

  final CreatorDashboard dashboard;
  final VoidCallback onRefresh;

  // MOCK — wire to the account profile once the dashboard payload carries it.
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
            _EarningsHeroCard(
              earnings: dashboard.earnings,
              deltaPercent: dashboard.earningsDeltaPercent,
              pendingBalance: dashboard.pendingBalance,
            ),
            const SizedBox(height: DesignTokens.s24),
            _StatsRow(
              sales: dashboard.totalSales,
              reels: dashboard.topReels.length,
              totalViews: dashboard.totalViews,
            ),
            const SizedBox(height: DesignTokens.s24),
            const _ConnectAccountsCard(),
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

// ── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back $firstName',
                style: DesignTokens.sectionInnerTitle,
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Quick insights to your progress and earnings',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        // Spec: 32x32 circular action button, #3F3F46, 20px white icon.
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: DesignTokens.buttonGrayFill,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: DesignTokens.textWhite,
          ),
        ),
      ],
    );
  }
}

// ── Earnings + payout hero card ───────────────────────────────────────────────
class _EarningsHeroCard extends StatelessWidget {
  const _EarningsHeroCard({
    required this.earnings,
    required this.pendingBalance,
    this.deltaPercent,
  });

  final Money earnings;
  final Money pendingBalance;

  /// Percent change vs the previous window; `null` when the backend has no
  /// comparison baseline yet (new creator), in which case we omit the badge.
  final double? deltaPercent;

  static String? _formatDelta(double? pct) {
    if (pct == null) return null;
    final rounded = pct.round();
    return '${rounded >= 0 ? '+' : ''}$rounded%';
  }

  @override
  Widget build(BuildContext context) {
    final amount = formatMoney(earnings);
    final pending = formatMoney(pendingBalance);
    final delta = _formatDelta(deltaPercent);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Green top half — earnings summary.
          Container(
            width: double.infinity,
            color: DesignTokens.primaryGreen,
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Total Earned ',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.buttonPrimaryText,
                      ),
                    ),
                    if (delta != null)
                      Text(
                        '($delta vs last)',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.buttonPrimaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  amount,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Pending Balance',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
                Text(
                  pending,
                  style: DesignTokens.mediumSemibold.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
              ],
            ),
          ),
          // Yellow bottom half — payout CTA + helper copy.
          Container(
            width: double.infinity,
            color: DesignTokens.secondaryYellow,
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmPrimaryButton(
                  label: 'Request Payout Withdrawal',
                  height: DesignTokens.buttonHeight,
                  borderRadius: DesignTokens.buttonRadius,
                  color: DesignTokens.buttonPrimaryText,
                  labelColor: DesignTokens.secondaryYellow,
                  onPressed: () async => context.push(RouteNames.earnings),
                ),
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Payouts are processed weekly on fridays.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.buttonPrimaryText,
                  ),
                ),
                Text(
                  'The minimum withdraw amount is Rs 5,000.00',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.buttonPrimaryText,
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

// ── Quick stats row ───────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.sales,
    required this.reels,
    required this.totalViews,
  });

  final int sales;
  final int reels;
  final int totalViews;

  @override
  Widget build(BuildContext context) {
    final comma = NumberFormat('#,###');
    return Column(
      children: [
        // Clicks intentionally omitted — the backend does not track click
        // signals yet (would always be 0). Re-add when the signals pipeline
        // lands.
        Row(
          children: [
            _StatBlock(label: 'Sales', value: '$sales'),
            const SizedBox(width: DesignTokens.s12),
            _StatBlock(label: 'Reels', value: '$reels'),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        _StatBlock(
          label: 'Total Views',
          value: comma.format(totalViews),
          wide: true,
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.2,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            label,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
    return wide ? card : Expanded(child: card);
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
        if (reels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
            child: Text(
              'No reels yet — import one to get started.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
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
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.s12),
                child: Container(
                  width: 64,
                  height: 64,
                  color: DesignTokens.bgAppBodyLight,
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
                      style: DesignTokens.mediumSemibold.copyWith(
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
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          // Metric row — real values where we have them.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Metric(icon: Icons.visibility_outlined, value: reel.views),
              _Metric(icon: Icons.favorite_outline, value: reel.likes),
              _Metric(icon: Icons.chat_bubble_outline, value: reel.comments),
              _Metric(icon: Icons.share_outlined, value: reel.shares),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: DesignTokens.textMuted),
        const SizedBox(width: DesignTokens.s4),
        Text(
          _compact(value),
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textLight,
          ),
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
/// Fed by the notification inbox (`GET /api/v1/notifications/inbox`) via
/// [recentActivityProvider]. Degrades to an empty state on error/empty — which
/// is also the current reality while the backend inbox auth bug is outstanding.
class _RecentActivity extends ConsumerWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(recentActivityProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s12),
        activity.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: DesignTokens.s8),
            child: Center(
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
          error: (_, __) => const _EmptyActivity(),
          data: (items) => items.isEmpty
              ? const _EmptyActivity()
              : Column(
                  children: items
                      .map((a) => _ActivityRow(item: a))
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
    child: Text(
      'No recent activity yet.',
      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 18,
              color: DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(
              item.title,
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textWhite,
                height: 1.4,
              ),
            ),
          ),
          if (item.occurredAt != null) ...[
            const SizedBox(width: DesignTokens.s8),
            Text(
              _timeAgo(item.occurredAt!),
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
          ],
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

// ── Connect Accounts entry ────────────────────────────────────────────────────
/// Permanent doorway into the social-connect OAuth flow. Opens the screen in
/// normal (back-navigable) mode — distinct from the post-approval onboarding
/// entry which passes `?onboarding=true`.
class _ConnectAccountsCard extends StatelessWidget {
  const _ConnectAccountsCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RouteNames.socialConnect),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: DesignTokens.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: DesignTokens.primaryGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(DesignTokens.s8),
              ),
              child: const Icon(
                Icons.link,
                color: DesignTokens.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect Accounts',
                    style: DesignTokens.oneLinerSemibold,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Link Instagram, TikTok & more to import reels',
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: DesignTokens.textMuted,
              size: DesignTokens.iconSmall,
            ),
          ],
        ),
      ),
    );
  }
}
