import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/domain/entities/vendor_top_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/top_products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

enum _Period { thisMonth, last30Days, last90Days, custom }

extension on _Period {
  String get label => switch (this) {
    _Period.thisMonth => 'This Month',
    _Period.last30Days => 'Last 30 days',
    _Period.last90Days => 'Last 90 days',
    _Period.custom => 'Custom Date',
  };
}

class TopProductsScreen extends ConsumerStatefulWidget {
  const TopProductsScreen({super.key});

  @override
  ConsumerState<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends ConsumerState<TopProductsScreen> {
  _Period _period = _Period.last30Days;
  DateTimeRange? _customRange;

  (DateTime?, DateTime?) _rangeFor(_Period period) {
    final now = DateTime.now().toUtc();
    switch (period) {
      case _Period.thisMonth:
        return (DateTime.utc(now.year, now.month, 1), now);
      case _Period.last30Days:
        return (now.subtract(const Duration(days: 30)), now);
      case _Period.last90Days:
        return (now.subtract(const Duration(days: 90)), now);
      case _Period.custom:
        final range = _customRange;
        return range == null ? (null, now) : (range.start, range.end);
    }
  }

  void _applyPeriod(_Period period, {DateTimeRange? customRange}) {
    setState(() {
      _period = period;
      if (customRange != null) _customRange = customRange;
    });
    final (fromUtc, toUtc) = _rangeFor(period);
    ref
        .read(vendorTopProductsNotifierProvider.notifier)
        .load(fromUtc: fromUtc, toUtc: toUtc);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _customRange,
    );
    if (picked != null) _applyPeriod(_Period.custom, customRange: picked);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorTopProductsNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: const Text('Top Products', style: DesignTokens.oneLinerSemibold),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: DesignTokens.textWhite, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChips(),
          Expanded(
            child: state.when(
              initial: _loader,
              loadInProgress: _loader,
              loadSuccess: (products) => products.isEmpty
                  ? Center(
                      child: Text(
                        'No product sales in this window.',
                        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
                      itemBuilder: (_, i) => _ProductCard(product: products[i]),
                    ),
              loadFailure: (_) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load top products.',
                      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
                    ),
                    const SizedBox(height: DesignTokens.s8),
                    TextButton(
                      onPressed: () => _applyPeriod(_period),
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

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
      child: Row(
        children: [
          for (final period in _Period.values) ...[
            if (period != _Period.values.first) const SizedBox(width: DesignTokens.s8),
            _Chip(
              label: period.label,
              isActive: _period == period,
              onTap: () => period == _Period.custom ? _pickCustomRange() : _applyPeriod(period),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.isActive = false});

  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? DesignTokens.primaryGreen : DesignTokens.textMuted;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: DesignTokens.s6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A3A1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? DesignTokens.primaryGreen : const Color(0xFF3A3A3C)),
        ),
        child: Text(label, style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final VendorTopProduct product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: image + name + units sold
          Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.inputRadius),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: DesignTokens.bgAppBodyLight,
                    child: product.thumbnailUrl != null
                        ? Image.network(
                            product.thumbnailUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag_outlined,
                              color: DesignTokens.textMuted,
                              size: 28,
                            ),
                          )
                        : const Icon(Icons.shopping_bag_outlined, color: DesignTokens.textMuted, size: 28),
                  ),
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w600, color: DesignTokens.textWhite),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new, color: DesignTokens.textMuted, size: 16),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Units Sold: ${product.unitsSold}',
                        style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const _DashedDivider(),
          _StatRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Total Revenue',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFB8E6FE), borderRadius: BorderRadius.circular(999)),
              child: Text(formatMoney(product.totalRevenue), style: DesignTokens.smallRegular.copyWith(color: const Color(0xFF0D1B2A), fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          _StatRow(
            icon: Icons.person_outline,
            label: 'Sales via',
            trailing: Text('${product.distinctCreatorCount} creators', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label, required this.trailing});
  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s12, vertical: DesignTokens.s8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: DesignTokens.textMuted),
              const SizedBox(width: 6),
              Text(label, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 12)),
            ],
          ),
          trailing,
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 6.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(count, (_) => Container(
            width: dashWidth,
            height: 1,
            margin: const EdgeInsets.only(right: dashSpace),
            color: DesignTokens.borderDefault,
          )),
        );
      },
    );
  }
}
