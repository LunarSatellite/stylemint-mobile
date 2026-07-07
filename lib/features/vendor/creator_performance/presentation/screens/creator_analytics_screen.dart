import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/domain/entities/vendor_analytics_summary.dart';
import 'package:stylemint_mobile_frontend/features/vendor/analytics/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── Args ─────────────────────────────────────────────────────────────────────

class CreatorAnalyticsArgs {
  const CreatorAnalyticsArgs({required this.partnershipId});

  final String partnershipId;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class CreatorAnalyticsScreen extends ConsumerWidget {
  const CreatorAnalyticsScreen({super.key, required this.args});

  final CreatorAnalyticsArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      creatorAnalyticsDeepDiveProvider(args.partnershipId),
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Creator Analytics',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
          ),
        ),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadFailure: (_) => SmErrorView(
          message: 'Failed to load creator analytics.',
          onRetry: () => ref
              .read(
                creatorAnalyticsDeepDiveProvider(args.partnershipId).notifier,
              )
              .load(),
        ),
        loadSuccess: (deepDive) => _DeepDiveBody(deepDive: deepDive),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _DeepDiveBody extends StatefulWidget {
  const _DeepDiveBody({required this.deepDive});

  final CreatorAnalyticsDeepDive deepDive;

  @override
  State<_DeepDiveBody> createState() => _DeepDiveBodyState();
}

class _DeepDiveBodyState extends State<_DeepDiveBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deepDive;
    return NestedScrollView(
      headerSliverBuilder: (ctx, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.s16,
              DesignTokens.s12,
              DesignTokens.s16,
              DesignTokens.s16,
            ),
            child: _CreatorCard(deepDive: d),
          ),
        ),
        if (d.revenueTrend.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s16,
                0,
                DesignTokens.s16,
                DesignTokens.s16,
              ),
              child: _RevenueTrendCard(
                points: d.revenueTrend,
                currency: d.currency,
              ),
            ),
          ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(tabCtrl: _tabCtrl),
        ),
      ],
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _ProductsTab(products: d.topProducts, currency: d.currency),
          _ReelsTab(reels: d.topReels, currency: d.currency),
        ],
      ),
    );
  }
}

// ─── Creator card ─────────────────────────────────────────────────────────────

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.deepDive});

  final CreatorAnalyticsDeepDive deepDive;

  @override
  Widget build(BuildContext context) {
    final d = deepDive;
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Container(
                    width: 56,
                    height: 56,
                    color: DesignTokens.bgAppFoundation,
                    alignment: Alignment.center,
                    child: Text(
                      d.creatorLabel[0].toUpperCase(),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        color: DesignTokens.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.creatorLabel,
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textWhite,
                        ),
                      ),
                      const SizedBox(height: DesignTokens.s8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: DesignTokens.primaryGreen.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Commission: '
                          '${(d.commissionMinPercent * 100).round()}%'
                          '–${(d.commissionMaxPercent * 100).round()}%',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: DesignTokens.primaryGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: DesignTokens.borderDefault,
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.payments_outlined,
                  iconBgColor: const Color(0xFF1A3A1A),
                  label: 'Attributed Revenue',
                  value:
                      '${d.currency} ${d.attributedRevenue.current.toStringAsFixed(2)}',
                  deltaPercent: d.attributedRevenue.deltaPercent,
                ),
                const SizedBox(height: DesignTokens.s16),
                _StatRow(
                  icon: Icons.shopping_bag_outlined,
                  iconBgColor: const Color(0xFF0D2137),
                  label: 'Units Sold',
                  value: '${d.unitsSold.current}',
                  deltaPercent: d.unitsSold.deltaPercent,
                ),
                const SizedBox(height: DesignTokens.s16),
                _StatRow(
                  icon: Icons.account_balance_wallet_outlined,
                  iconBgColor: const Color(0xFF3A1A2A),
                  label: 'Commission Paid',
                  value:
                      '${d.currency} ${d.commissionPaid.current.toStringAsFixed(2)}',
                  deltaPercent: d.commissionPaid.deltaPercent,
                ),
                const SizedBox(height: DesignTokens.s16),
                _StatRow(
                  icon: Icons.movie_outlined,
                  iconBgColor: const Color(0xFF1A2A4A),
                  label: 'Reels With Sales',
                  value: '${d.distinctReelCount.current}',
                  deltaPercent: d.distinctReelCount.deltaPercent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconBgColor,
    required this.label,
    required this.value,
    this.deltaPercent,
  });

  final IconData icon;
  final Color iconBgColor;
  final String label;
  final String value;
  final double? deltaPercent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 44,
            height: 44,
            color: iconBgColor,
            alignment: Alignment.center,
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textWhite,
                ),
              ),
            ],
          ),
        ),
        if (deltaPercent != null)
          Text(
            '${deltaPercent! >= 0 ? '+' : ''}${deltaPercent!.round()}%',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: deltaPercent! >= 0
                  ? DesignTokens.primaryGreen
                  : DesignTokens.colorError,
            ),
          ),
      ],
    );
  }
}

// ─── Revenue trend ────────────────────────────────────────────────────────────

class _RevenueTrendCard extends StatelessWidget {
  const _RevenueTrendCard({required this.points, required this.currency});

  final List<DeepDiveRevenuePoint> points;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Trend',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          SizedBox(
            height: 160,
            child: CustomPaint(
              painter: _TrendPainter(points: points),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.points});

  final List<DeepDiveRevenuePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxY = points
        .map((p) => p.amount)
        .fold<double>(
          0,
          (a, b) => b > a ? b : a,
        );
    if (maxY <= 0) return;

    final pts = List.generate(points.length, (i) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final y = size.height * (1 - points[i].amount / maxY);
      return Offset(x, y);
    });

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = DesignTokens.primaryGreen
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points != points;
}

// ─── Tab bar delegate (pinned) ────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate({required this.tabCtrl});

  final TabController tabCtrl;

  @override
  double get maxExtent => 48;
  @override
  double get minExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: DesignTokens.bgAppFoundation,
      child: TabBar(
        controller: tabCtrl,
        tabs: const [
          Tab(text: 'Products'),
          Tab(text: 'Reels'),
        ],
        indicatorColor: DesignTokens.primaryGreen,
        indicatorWeight: 2,
        labelColor: DesignTokens.primaryGreen,
        unselectedLabelColor: DesignTokens.textMuted,
        dividerColor: DesignTokens.borderDefault,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabCtrl != tabCtrl;
}

// ─── Products tab ─────────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.products, required this.currency});

  final List<DeepDiveTopProduct> products;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          'No product sales in this window yet.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s16,
      ),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) => _ProductRow(
        rank: i + 1,
        product: products[i],
        currency: currency,
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.rank,
    required this.product,
    required this.currency,
  });

  final int rank;
  final DeepDiveTopProduct product;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            '$rank',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: DesignTokens.textMuted,
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: product.thumbnailUrl != null
              ? Image.network(
                  product.thumbnailUrl!,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumbFallback,
                )
              : _thumbFallback,
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: DesignTokens.textWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$currency ${product.totalRevenue.toStringAsFixed(2)} · '
                '${product.unitsSold} sales',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget get _thumbFallback => Container(
    width: 64,
    height: 64,
    color: DesignTokens.bgAppBodyLight,
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_outlined,
      color: DesignTokens.textMuted,
      size: 24,
    ),
  );
}

// ─── Reels tab ────────────────────────────────────────────────────────────────

class _ReelsTab extends StatelessWidget {
  const _ReelsTab({required this.reels, required this.currency});

  final List<DeepDiveTopReel> reels;
  final String currency;

  @override
  Widget build(BuildContext context) {
    if (reels.isEmpty) {
      return Center(
        child: Text(
          'No reels data available',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s16,
      ),
      itemCount: reels.length,
      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
      itemBuilder: (_, i) => _ReelRow(reel: reels[i], currency: currency),
    );
  }
}

class _ReelRow extends StatelessWidget {
  const _ReelRow({required this.reel, required this.currency});

  final DeepDiveTopReel reel;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reel.caption?.isNotEmpty ?? false
                      ? reel.caption!
                      : reel.sourcePlatform,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  '${reel.viewCount} views · ${reel.unitsSold} sales · '
                  '$currency ${reel.attributedRevenue.toStringAsFixed(2)}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
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
