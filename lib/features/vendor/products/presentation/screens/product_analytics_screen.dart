import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/domain/entities/vendor_product_analytics.dart';
import 'package:stylemint_mobile_frontend/features/vendor/product_analytics/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class ProductAnalyticsScreen extends ConsumerStatefulWidget {
  const ProductAnalyticsScreen({required this.product, super.key});

  final VendorProduct product;

  @override
  ConsumerState<ProductAnalyticsScreen> createState() =>
      _ProductAnalyticsScreenState();
}

class _ProductAnalyticsScreenState
    extends ConsumerState<ProductAnalyticsScreen> {
  int _selectedFilter = 1;
  DateTimeRange? _customRange;

  static const _filters = [
    'Custom Date',
    'Last 7 days',
    'Last 30 days',
    'Last 90 days',
  ];

  @override
  void initState() {
    super.initState();
    // Riverpod forbids modifying a provider's state synchronously during
    // the widget tree's initial build — initState still counts. Defer to
    // the post-frame callback like the other screens that load on mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  (DateTime, DateTime) _rangeFor(int filterIndex) {
    final now = DateTime.now().toUtc();
    switch (filterIndex) {
      case 0:
        final range = _customRange;
        return range == null
            ? (now.subtract(const Duration(days: 7)), now)
            : (range.start, range.end);
      case 2:
        return (now.subtract(const Duration(days: 30)), now);
      case 3:
        return (now.subtract(const Duration(days: 90)), now);
      case 1:
      default:
        return (now.subtract(const Duration(days: 7)), now);
    }
  }

  void _load() {
    final (fromUtc, toUtc) = _rangeFor(_selectedFilter);
    ref
        .read(vendorProductAnalyticsNotifierProvider.notifier)
        .load(productId: widget.product.id, fromUtc: fromUtc, toUtc: toUtc);
  }

  Future<void> _selectFilter(int index) async {
    if (index == 0) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(now.year - 2),
        lastDate: now,
        initialDateRange: _customRange,
      );
      if (picked == null) return;
      setState(() {
        _selectedFilter = 0;
        _customRange = picked;
      });
    } else {
      setState(() => _selectedFilter = index);
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorProductAnalyticsNotifierProvider);
    final (fromUtc, toUtc) = _rangeFor(_selectedFilter);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Product Analytics', style: DesignTokens.oneLinerSemibold),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateFilterRow(
              filters: _filters,
              selected: _selectedFilter,
              onSelected: _selectFilter,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s16,
                vertical: DesignTokens.s4,
              ),
              child: Text(
                'Date Range: ${DateFormat('MMM d').format(fromUtc.toLocal())} - '
                '${DateFormat('MMM d, yyyy').format(toUtc.toLocal())}',
                style: const TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontSize: 12,
                  color: DesignTokens.textMuted,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: DesignTokens.s8),
                  _ProductHeader(product: widget.product),
                  const SizedBox(height: DesignTokens.s20),
                  state.when(
                    initial: _loader,
                    loadInProgress: _loader,
                    loadFailure: (_) => _FailureView(onRetry: _load),
                    loadSuccess: (analytics) => _AnalyticsBody(
                      analytics: analytics,
                      productId: widget.product.id,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.s32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loader() => const Padding(
    padding: EdgeInsets.symmetric(vertical: DesignTokens.s32),
    child: Center(
      child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
    ),
  );
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: DesignTokens.s32),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load product analytics.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.analytics, required this.productId});

  final VendorProductAnalytics analytics;
  final String productId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EarningsSection(analytics: analytics),
        const SizedBox(height: DesignTokens.s20),
        const _AgeGroupTrafficSection(),
        const SizedBox(height: DesignTokens.s20),
        if (analytics.reviews != null) ...[
          _ReviewsSection(
            reviews: analytics.reviews!,
            productId: productId,
          ),
          const SizedBox(height: DesignTokens.s20),
        ],
        const _GenderTrafficSection(),
        const SizedBox(height: DesignTokens.s20),
        _CreatorTrafficSection(creators: analytics.topCreators),
        const SizedBox(height: DesignTokens.s20),
        _LocationTrafficSection(locations: analytics.locations),
      ],
    );
  }
}

// ── Date filter chips ───────────────────────────────────────────────────────

class _DateFilterRow extends StatelessWidget {
  const _DateFilterRow({
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  final List<String> filters;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.s8),
        itemBuilder: (_, i) {
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.s12,
                vertical: DesignTokens.s6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? DesignTokens.primaryGreen.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.primaryGreen
                      : DesignTokens.borderDefault,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (i == 0) ...[
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 14,
                      color: DesignTokens.textMuted,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    filters[i],
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 12,
                      color: isSelected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Product header ──────────────────────────────────────────────────────────

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final VendorProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.s8),
            child: Image.network(
              product.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                color: DesignTokens.bgAppBodyLight,
                child: const Icon(Icons.image, color: DesignTokens.textMuted),
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
                  style: DesignTokens.mediumSemibold,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.commissionRate != null
                      ? '${formatMoney(product.price)} · ${product.commissionRate!.toStringAsFixed(0)}% Commission'
                      : formatMoney(product.price),
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

// ── Earnings section ─────────────────────────────────────────────────────────

class _EarningsSection extends StatelessWidget {
  const _EarningsSection({required this.analytics});

  final VendorProductAnalytics analytics;

  static String? _formatDelta(double? pct) {
    if (pct == null) return null;
    final r = pct.round();
    return '${r >= 0 ? '+' : ''}$r%';
  }

  @override
  Widget build(BuildContext context) {
    final revenueDelta = _formatDelta(analytics.revenueDeltaPercent);
    final unitsDelta = _formatDelta(analytics.unitsSoldDeltaPercent);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart card
        Container(
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Earnings Overview', style: DesignTokens.mediumSemibold),
              const SizedBox(height: 2),
              Text(
                'Revenue Trend',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              const SizedBox(height: DesignTokens.s16),
              SizedBox(
                height: 160,
                child: analytics.revenueTrend.length < 2
                    ? Center(
                        child: Text(
                          'Not enough data for this window.',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      )
                    : CustomPaint(
                        painter: _EarningsChartPainter(analytics.revenueTrend),
                        size: const Size(double.infinity, 160),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.s12),
        _RevenueHeroCard(
          value: formatMoney(analytics.revenue),
          badge: revenueDelta,
        ),
        const SizedBox(height: DesignTokens.s12),
        // Conversion rate, AOV, and cart adds have no backing field on this
        // endpoint (see the note on VendorProductAnalytics) — shown as
        // explicit placeholders rather than fabricated numbers.
        const Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.percent_outlined,
                value: '—',
                label: 'Conversion Rate',
                unavailable: true,
              ),
            ),
            SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                icon: Icons.receipt_outlined,
                value: '—',
                label: 'Avg. Order Value',
                unavailable: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        Row(
          children: [
            const Expanded(
              child: _StatCard(
                icon: Icons.add_shopping_cart_outlined,
                value: '—',
                label: 'Added to Cart',
                unavailable: true,
              ),
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: _StatCard(
                icon: Icons.inventory_2_outlined,
                value: '${analytics.unitsSold}',
                badge: unitsDelta,
                label: 'Units Sold',
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.s12),
        const _ViewToPurchaseRatioCard(),
      ],
    );
  }
}

class _RevenueHeroCard extends StatelessWidget {
  const _RevenueHeroCard({required this.value, this.badge});

  final String value;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: const Icon(
              Icons.monetization_on_outlined,
              size: 20,
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    value,
                    style: DesignTokens.mediumSemibold.copyWith(fontSize: 20),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      badge!,
                      style: DesignTokens.tiny.copyWith(
                        color: badge!.startsWith('-')
                            ? DesignTokens.colorError
                            : DesignTokens.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Total Revenue',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The backend doesn't compute a view-to-purchase ratio anywhere — this
/// always renders the empty state (see the note on VendorProductAnalytics).
class _ViewToPurchaseRatioCard extends StatelessWidget {
  const _ViewToPurchaseRatioCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 18,
                color: DesignTokens.textMuted,
              ),
              SizedBox(width: DesignTokens.s8),
              Text(
                ':',
                style: TextStyle(
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textMuted,
                ),
              ),
              SizedBox(width: DesignTokens.s8),
              Icon(
                Icons.description_outlined,
                size: 18,
                color: DesignTokens.textMuted,
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s8),
          Text('—', style: DesignTokens.mediumSemibold.copyWith(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            'View to Purchase Ratio',
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            'Not available yet',
            style: DesignTokens.tiny.copyWith(
              color: DesignTokens.textMuted,
              fontStyle: FontStyle.italic,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    this.badge,
    this.unavailable = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? badge;

  /// The backend doesn't provide this metric yet — render the placeholder
  /// value/label but skip the badge and add a muted note so vendors don't
  /// mistake "—" for a real zero.
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s12),
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
            ),
            child: Icon(icon, size: 20, color: DesignTokens.textMuted),
          ),
          const SizedBox(height: DesignTokens.s8),
          Row(
            children: [
              Text(
                value,
                style: DesignTokens.mediumSemibold.copyWith(fontSize: 18),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Text(
                  badge!,
                  style: DesignTokens.tiny.copyWith(
                    color: badge!.startsWith('-')
                        ? DesignTokens.colorError
                        : DesignTokens.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
          ),
          if (unavailable) ...[
            const SizedBox(height: 2),
            Text(
              'Not available yet',
              style: DesignTokens.tiny.copyWith(
                color: DesignTokens.textMuted,
                fontStyle: FontStyle.italic,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Reviews — Reel Reviews / Written Reviews tabs ───────────────────────────
//
// "Written Reviews" renders the real star-distribution aggregate from
// GET /v1/vendor/products/{id}/analytics. "Reel Reviews" has no backing
// endpoint (no per-review reel media anywhere in the API) — it shows an
// honest placeholder instead of fabricated thumbnails/view counts.

class _ReviewsSection extends StatefulWidget {
  const _ReviewsSection({required this.reviews, required this.productId});

  final ProductReviewSummary reviews;
  final String productId;

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  bool _showReelReviews = true;

  @override
  Widget build(BuildContext context) {
    final reviews = widget.reviews;
    final maxCount = reviews.starDistribution.values.isEmpty
        ? 0
        : reviews.starDistribution.values.reduce(math.max);

    return Container(
      decoration: DesignTokens.cardDecoration(),
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: DesignTokens.secondaryYellow,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                reviews.averageRating.toStringAsFixed(1),
                style: DesignTokens.smallRegular.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· Customer Reviews & Rating (${reviews.reviewCount})',
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Row(
            children: [
              _ReviewTabButton(
                label: 'Reel Reviews',
                selected: _showReelReviews,
                onTap: () => setState(() => _showReelReviews = true),
              ),
              const SizedBox(width: DesignTokens.s20),
              _ReviewTabButton(
                label: 'Written Reviews',
                selected: !_showReelReviews,
                onTap: () => setState(() => _showReelReviews = false),
              ),
            ],
          ),
          const Divider(
            color: DesignTokens.borderDefault,
            height: DesignTokens.s20,
          ),
          if (_showReelReviews)
            _unavailableNote('Not available yet.')
          else if (maxCount > 0)
            for (var star = 5; star >= 1; star--)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      child: Text(
                        '$star',
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.star,
                      size: 10,
                      color: DesignTokens.secondaryYellow,
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value:
                              (reviews.starDistribution[star] ?? 0) / maxCount,
                          minHeight: 6,
                          backgroundColor: DesignTokens.bgAppBodyLight,
                          valueColor: const AlwaysStoppedAnimation(
                            DesignTokens.secondaryYellow,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${reviews.starDistribution[star] ?? 0}',
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              )
          else
            _unavailableNote('No written reviews yet.'),
          const SizedBox(height: DesignTokens.s16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push(
                RouteNames.productReviews.replaceFirst(
                  ':productId',
                  widget.productId,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: DesignTokens.borderDefault),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.s12,
                ),
              ),
              child: Text(
                'See all reviews',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTabButton extends StatelessWidget {
  const _ReviewTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(bottom: DesignTokens.s8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? DesignTokens.primaryGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: selected
                ? DesignTokens.primaryGreen
                : DesignTokens.textMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ── Demographic + reel-review placeholders ──────────────────────────────────
//
// None of these have a backing field on the product analytics endpoint (see
// the note on VendorProductAnalytics) — the sections are built to match the
// design and light up the moment the backend adds the data, but show an
// honest "not available" state rather than fabricated numbers.

Widget _unavailableNote(String message) => Text(
  message,
  style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
);

class _AgeGroupTrafficSection extends StatelessWidget {
  const _AgeGroupTrafficSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Traffic Source as per Age Group',
      subtitle: 'Customer demographic according to different age groups',
      child: _unavailableNote('Not available yet.'),
    );
  }
}

class _GenderTrafficSection extends StatelessWidget {
  const _GenderTrafficSection();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Traffic Source as per Gender',
      subtitle: 'Customer demographic according to different genders',
      child: _unavailableNote('Not available yet.'),
    );
  }
}

// ── Creator list ─────────────────────────────────────────────────────────────

class _CreatorTrafficSection extends StatelessWidget {
  const _CreatorTrafficSection({required this.creators});

  final List<ProductTopCreator> creators;

  static String _label(String accountId) => accountId.length >= 8
      ? 'Creator ••${accountId.substring(accountId.length - 4)}'
      : 'Creator';

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Top Creators',
      subtitle: 'Creators driving sales of this product',
      child: creators.isEmpty
          ? Text(
              'No creator-attributed sales in this window.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            )
          : Column(
              children: creators.asMap().entries.map((e) {
                final i = e.key;
                final c = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.s16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text(
                          '${i + 1}',
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: DesignTokens.bgAppBodyLight,
                        child: const Icon(
                          Icons.person,
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
                              _label(c.creatorAccountId),
                              style: DesignTokens.smallRegular.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 12,
                                  color: DesignTokens.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${c.unitsSold} sales',
                                  style: DesignTokens.tiny.copyWith(
                                    color: DesignTokens.textMuted,
                                  ),
                                ),
                                const SizedBox(width: DesignTokens.s12),
                                const Icon(
                                  Icons.play_circle_outline,
                                  size: 12,
                                  color: DesignTokens.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${c.distinctReelCount} reels',
                                  style: DesignTokens.tiny.copyWith(
                                    color: DesignTokens.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatMoney(c.attributedRevenue),
                        style: DesignTokens.tiny.copyWith(
                          color: DesignTokens.textWhite,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ── Location donut ───────────────────────────────────────────────────────────

class _LocationTrafficSection extends StatelessWidget {
  const _LocationTrafficSection({required this.locations});

  final List<ProductLocationBucket> locations;

  static const _palette = [
    Color(0xFF38BDF8),
    Color(0xFFFB923C),
    Color(0xFFEF4444),
    Color(0xFFFBBF24),
    Color(0xFF4ADE80),
  ];

  @override
  Widget build(BuildContext context) {
    final total = locations.fold<double>(0, (a, b) => a + b.revenue.amount);
    final segments = total <= 0
        ? const <_PieSegment>[]
        : locations
              .asMap()
              .entries
              .map(
                (e) => _PieSegment(
                  e.value.region,
                  e.value.revenue.amount / total,
                  _palette[e.key % _palette.length],
                ),
              )
              .toList();

    return _SectionCard(
      title: 'Sales by Location',
      subtitle: 'Where this product\'s orders shipped from in this window',
      child: segments.isEmpty
          ? Text(
              'No location data in this window.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 200,
                  child: CustomPaint(
                    painter: _DonutWithLabelsPainter(segments),
                    size: const Size(double.infinity, 200),
                  ),
                ),
                const SizedBox(height: DesignTokens.s16),
                _LegendRow(segments: segments),
              ],
            ),
    );
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DesignTokens.mediumSemibold),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
        ),
        const SizedBox(height: DesignTokens.s12),
        Container(
          width: double.infinity,
          decoration: DesignTokens.cardDecoration(),
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: child,
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.segments});

  final List<_PieSegment> segments;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_PieSegment>>[];
    for (var i = 0; i < segments.length; i += 3) {
      rows.add(segments.sublist(i, math.min(i + 3, segments.length)));
    }
    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s6),
              child: Row(
                children: row
                    .map(
                      (s) => Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                s.label,
                                style: DesignTokens.tiny.copyWith(
                                  color: DesignTokens.textLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _PieSegment {
  const _PieSegment(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

// ── Painters ──────────────────────────────────────────────────────────────────

class _DonutWithLabelsPainter extends CustomPainter {
  const _DonutWithLabelsPainter(this.segments);

  final List<_PieSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    const strokeW = 28.0;
    const gap = 0.03;

    var startAngle = -math.pi / 2;

    for (final seg in segments) {
      final sweepAngle = seg.value * 2 * math.pi - gap;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeW / 2),
        startAngle,
        sweepAngle,
        false,
        Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.butt,
      );

      final midAngle = startAngle + sweepAngle / 2;
      final labelR = radius - strokeW / 2;
      final labelOffset = Offset(
        center.dx + labelR * math.cos(midAngle),
        center.dy + labelR * math.sin(midAngle),
      );

      final pct = '${(seg.value * 100).toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(
          text: pct,
          style: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        labelOffset - Offset(tp.width / 2, tp.height / 2),
      );

      startAngle += sweepAngle + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EarningsChartPainter extends CustomPainter {
  const _EarningsChartPainter(this.points);

  final List<ProductRevenueTrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 36.0;
    const bottomPad = 24.0;
    const topPad = 8.0;

    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;

    final maxAmount = points.fold<double>(
      0,
      (a, p) => math.max(a, p.amount.amount),
    );
    final yMax = maxAmount <= 0 ? 1.0 : maxAmount;

    final gridPaint = Paint()
      ..color = DesignTokens.borderDefault.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    final labelStyle = TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: 10,
      color: DesignTokens.textMuted,
    );

    const ySteps = 5;
    for (var i = 0; i <= ySteps; i++) {
      final y = topPad + chartH * i / ySteps;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);

      final value = yMax * (ySteps - i) / ySteps;
      // Rounding to 0 decimals collapses adjacent gridlines onto the same
      // label (e.g. 1800 and 2400 both showing "2k") — use 1 decimal
      // whenever the value isn't a whole number of thousands.
      final thousands = value / 1000;
      final label = value >= 1000
          ? (thousands == thousands.roundToDouble()
                ? '${thousands.toStringAsFixed(0)}k'
                : '${thousands.toStringAsFixed(1)}k')
          // Same collision just below the 1000 threshold.
          : (value == value.roundToDouble()
                ? value.toStringAsFixed(0)
                : value.toStringAsFixed(1));
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // X labels — first, middle, last date only to avoid crowding.
    final labelIndices = {0, points.length ~/ 2, points.length - 1};
    for (final i in labelIndices) {
      final x = leftPad + chartW * i / (points.length - 1);
      final tp = TextPainter(
        text: TextSpan(
          text: DateFormat('MMM d').format(points[i].date.toLocal()),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, topPad + chartH + 6));
    }

    final pts = List.generate(
      points.length,
      (i) => Offset(
        leftPad + chartW * i / (points.length - 1),
        topPad + chartH * (1 - points[i].amount.amount / yMax),
      ),
    );

    final areaPath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      areaPath.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    areaPath
      ..lineTo(pts.last.dx, topPad + chartH)
      ..lineTo(pts.first.dx, topPad + chartH)
      ..close();

    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            DesignTokens.primaryGreen.withValues(alpha: 0.5),
            DesignTokens.primaryGreen.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH)),
    );

    final linePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final cx = (pts[i - 1].dx + pts[i].dx) / 2;
      linePath.cubicTo(cx, pts[i - 1].dy, cx, pts[i].dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = DesignTokens.primaryGreen
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(pts.last, 4, Paint()..color = DesignTokens.primaryGreen);
  }

  @override
  bool shouldRepaint(covariant _EarningsChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
