import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/domain/entities/creator_dashboard.dart';
import 'package:stylemint_mobile_frontend/features/creator/dashboard/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
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

  // MOCK — wire to the account profile once the dashboard payload carries it.
  static const String _firstName = 'Creator';

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s16,
            DesignTokens.s16, DesignTokens.s32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(firstName: _firstName),
            const SizedBox(height: DesignTokens.s20),
            _EarningsHeroCard(earnings: dashboard.earnings),
            const SizedBox(height: DesignTokens.s24),
            _StatsRow(
              reels: dashboard.totalReels,
              totalViews: dashboard.totalViews,
            ),
            const SizedBox(height: DesignTokens.s24),
            _TopPerformingReels(reels: dashboard.recentReels),
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
              Text('Welcome Back $firstName',
                  style: DesignTokens.sectionInnerTitle),
              const SizedBox(height: DesignTokens.s4),
              Text('Quick insights to your progress and earnings',
                  style: DesignTokens.smallRegular
                      .copyWith(color: DesignTokens.textLight)),
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
          child: const Icon(Icons.notifications_none_rounded,
              size: 20, color: DesignTokens.textWhite),
        ),
      ],
    );
  }
}

// ── Earnings + payout hero card ───────────────────────────────────────────────
class _EarningsHeroCard extends StatelessWidget {
  const _EarningsHeroCard({required this.earnings});

  final Money earnings;

  // MOCK — delta %, pending-sales count, and pending amount are not yet on the
  // dashboard payload. Total Earned uses the real `earnings` value.
  static const String _deltaPct = '+23%';
  static const int _pendingSales = 12;

  @override
  Widget build(BuildContext context) {
    final amount = formatMoney(earnings);
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
                    Text('Total Earned ',
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.buttonPrimaryText)),
                    Text('($_deltaPct vs last)',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.buttonPrimaryText,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(amount,
                    style: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: DesignTokens.buttonPrimaryText,
                    )),
                const SizedBox(height: DesignTokens.s8),
                Text('Pending from $_pendingSales sales',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.buttonPrimaryText)),
                Text(amount,
                    style: DesignTokens.mediumSemibold
                        .copyWith(color: DesignTokens.buttonPrimaryText)),
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
                Text('Payouts are processed weekly on fridays.',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.buttonPrimaryText)),
                Text('The minimum withdraw amount is Rs 5,000.00',
                    style: DesignTokens.smallRegular
                        .copyWith(color: DesignTokens.buttonPrimaryText)),
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
  const _StatsRow({required this.reels, required this.totalViews});

  final int reels;
  final int totalViews;

  // MOCK — Sales and Clicks aren't on the dashboard payload yet.
  static const int _sales = 20;
  static const int _clicks = 105;

  @override
  Widget build(BuildContext context) {
    final comma = NumberFormat('#,###');
    return Column(
      children: [
        Row(
          children: [
            _StatBlock(label: 'Sales', value: '$_sales'),
            const SizedBox(width: DesignTokens.s12),
            _StatBlock(label: 'Reels', value: '$reels'),
            const SizedBox(width: DesignTokens.s12),
            _StatBlock(label: 'Clicks', value: '$_clicks'),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        _StatBlock(
            label: 'Total Views', value: comma.format(totalViews), wide: true),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock(
      {required this.label, required this.value, this.wide = false});

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
          Text(value,
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: DesignTokens.textWhite,
              )),
          const SizedBox(height: DesignTokens.s4),
          Text(label,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textLight)),
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

  // MOCK — reel titles aren't on CreatorReel yet; fall back per index.
  static const List<String> _mockTitles = [
    'Mheecha: The Bag that Matches Your Aesthetics',
    'Nike Structure 26 - Be the Trail Blazzer Runner',
    'Winter Haul — 5 pieces under Rs 3,000',
  ];

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
              child: Text('View All',
                  style: DesignTokens.mediumSemibold
                      .copyWith(color: DesignTokens.primaryGreen)),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        if (reels.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.s16),
            child: Text('No reels yet — import one to get started.',
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textMuted)),
          )
        else
          ...List.generate(reels.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s12),
              child: _TopReelCard(
                reel: reels[i],
                title:
                    i < _mockTitles.length ? _mockTitles[i] : 'Untitled reel',
              ),
            );
          }),
      ],
    );
  }
}

class _TopReelCard extends StatelessWidget {
  const _TopReelCard({required this.reel, required this.title});

  final CreatorReel reel;
  final String title;

  @override
  Widget build(BuildContext context) {
    final posted = DateFormat('d MMM, yyyy hh:mm a').format(reel.createdAt);
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
                  child: const Icon(Icons.play_circle_fill,
                      color: DesignTokens.iconLight, size: 28),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: DesignTokens.mediumSemibold
                            .copyWith(color: DesignTokens.textWhite)),
                    const SizedBox(height: DesignTokens.s4),
                    Text('Posted on: $posted',
                        style: DesignTokens.smallRegular
                            .copyWith(color: DesignTokens.textLight)),
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
        Text(_compact(value),
            style: DesignTokens.smallRegular
                .copyWith(color: DesignTokens.textLight)),
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
class _Activity {
  const _Activity(this.icon, this.text, this.timeAgo);
  final IconData icon;
  final String text;
  final String timeAgo;
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  // MOCK — the activity feed isn't on the dashboard payload yet. Day-grouped.
  static const Map<String, List<_Activity>> _feed = {
    'Thu 23 Jan 2026': [
      _Activity(Icons.movie_outlined,
          'Your reel "Winter Haul" earned Rs 5,567.00 today!', '2h ago'),
      _Activity(Icons.payments_outlined,
          'Your commission of Rs 24,575.00 was paid', '8h ago'),
    ],
    'Wed 22 Jan 2026': [
      _Activity(Icons.handshake_outlined,
          'A new brand partnership request from Puma', '22h ago'),
      _Activity(Icons.trending_up,
          'Your reel "Nike Structure 26" hit 100k views', '1d ago'),
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity', style: DesignTokens.sectionInnerTitle),
        const SizedBox(height: DesignTokens.s12),
        for (final entry in _feed.entries) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s8),
            child: Text(entry.key,
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textMuted)),
          ),
          ...entry.value.map((a) => _ActivityRow(activity: a)),
          const SizedBox(height: DesignTokens.s12),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final _Activity activity;

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
            child:
                Icon(activity.icon, size: 18, color: DesignTokens.primaryGreen),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Text(activity.text,
                style: DesignTokens.smallRegular
                    .copyWith(color: DesignTokens.textWhite, height: 1.4)),
          ),
          const SizedBox(width: DesignTokens.s8),
          Text(activity.timeAgo,
              style: DesignTokens.smallRegular
                  .copyWith(color: DesignTokens.textMuted)),
        ],
      ),
    );
  }
}
