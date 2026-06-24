import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TopProductsScreen extends StatefulWidget {
  const TopProductsScreen({super.key});

  @override
  State<TopProductsScreen> createState() => _TopProductsScreenState();
}

class _TopProductsScreenState extends State<TopProductsScreen> {
  String _sortBy = 'Revenue';
  String _period = 'Last 30 days';

  bool get _isSortActive => _sortBy != 'Revenue';
  bool get _isPeriodActive => _period != 'Last 30 days';
  bool get _isFiltered => _isSortActive || _isPeriodActive;
  int get _filterCount => (_isSortActive ? 1 : 0) + (_isPeriodActive ? 1 : 0);

  static final _products = [
    _Product(
      name: 'Nike Air Max 2025',
      assetImage: null,
      rating: 4.8,
      totalSales: 45,
      revenue: 'Rs 1,35,345',
      creators: 8,
      unitsSold: 324,
      stockCount: 12,
      isLowStock: true,
    ),
    _Product(
      name: 'Nike Air Jordan Travis Scott Limited Edition',
      assetImage: null,
      rating: 4.8,
      totalSales: 45,
      revenue: 'Rs 1,35,345',
      creators: 8,
      unitsSold: 324,
      stockCount: 128,
      isLowStock: false,
    ),
    _Product(
      name: 'Nike Air Wind Sheeter Goretrex Ultra Thin Edition',
      assetImage: null,
      rating: 4.8,
      totalSales: 45,
      revenue: 'Rs 1,35,345',
      creators: 8,
      unitsSold: 324,
      stockCount: 432,
      isLowStock: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: DesignTokens.textWhite),
          onPressed: () => context.pop(),
        ),
        title: Text(_isFiltered ? 'Top Products' : 'Top Products(This Month)', style: DesignTokens.oneLinerSemibold),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterChips(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s12),
              itemCount: _products.length,
              separatorBuilder: (_, __) => const SizedBox(height: DesignTokens.s12),
              itemBuilder: (_, i) => _ProductCard(product: _products[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filterLabel = _filterCount > 0 ? 'Filter ($_filterCount)' : 'Filter';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16, vertical: DesignTokens.s8),
      child: Row(
        children: [
          _Chip(
            label: filterLabel,
            leadingIcon: Icons.tune,
            isActive: _filterCount > 0,
            onTap: _showFilterSheet,
          ),
          const SizedBox(width: DesignTokens.s8),
          _Chip(
            label: _sortBy,
            trailingIcon: Icons.keyboard_arrow_down,
            isActive: _isSortActive,
            onTap: _showFilterSheet,
            onRemove: _isSortActive ? () => setState(() => _sortBy = 'Revenue') : null,
          ),
          const SizedBox(width: DesignTokens.s8),
          _Chip(
            label: _period,
            isActive: _isPeriodActive,
            onTap: _showFilterSheet,
            onRemove: _isPeriodActive ? () => setState(() => _period = 'Last 30 days') : null,
          ),
          const SizedBox(width: DesignTokens.s8),
          _Chip(label: 'Last 90 days', onTap: () => setState(() => _period = 'Last 90 days')),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _FilterSheet(
        selectedSort: _sortBy,
        selectedTime: _period,
        onApply: (sort, time) => setState(() { _sortBy = sort; _period = time; }),
        onClear: () => setState(() { _sortBy = 'Revenue'; _period = 'Last 30 days'; }),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap, this.leadingIcon, this.trailingIcon, this.isActive = false, this.onRemove});

  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isActive;
  final VoidCallback? onRemove;

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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(label, style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 12, color: color, fontWeight: FontWeight.w500)),
            if (trailingIcon != null) ...[
              const SizedBox(width: 2),
              Icon(trailingIcon, size: 16, color: color),
            ],
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close, size: 14, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final _Product product;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: DesignTokens.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: image + name + rating + stock
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
                    child: product.assetImage != null
                        ? Image.asset(
                            product.assetImage!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(),
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            color: DesignTokens.textMuted,
                            size: 28,
                          ),
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
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Color(0xFFFFB800)),
                          const SizedBox(width: 3),
                          Text(
                            '${product.rating} · Total Sales: ${product.totalSales}',
                            style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _StockChip(count: product.stockCount, isLow: product.isLowStock),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dashed divider
          const _DashedDivider(),
          // Total Revenue
          _StatRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Total Revenue',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFF0D2A3A), borderRadius: BorderRadius.circular(999)),
              child: Text(product.revenue, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.colorInfo, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          // Sales via
          _StatRow(
            icon: Icons.person_outline,
            label: 'Sales via',
            trailing: Text('${product.creators} creators', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontSize: 12)),
          ),
          const Divider(color: DesignTokens.borderDefault, height: 1),
          // Units Sold
          _StatRow(
            icon: Icons.inventory_2_outlined,
            label: 'Units Sold',
            trailing: Text('${product.unitsSold}', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({required this.count, required this.isLow});
  final int count;
  final bool isLow;

  @override
  Widget build(BuildContext context) {
    final bg = isLow ? const Color(0xFF2A1A00) : const Color(0xFF003A3A);
    final border = isLow ? const Color(0xFFFFB800) : const Color(0xFF00BCD4);
    final textColor = isLow ? const Color(0xFFFFB800) : const Color(0xFF00BCD4);
    final label = isLow ? 'Low Stock ($count)' : 'In Stock ($count)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(label, style: TextStyle(fontFamily: DesignTokens.fontFamily, fontSize: 11, color: textColor, fontWeight: FontWeight.w600)),
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

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.selectedSort, required this.selectedTime, required this.onApply, required this.onClear});
  final String selectedSort;
  final String selectedTime;
  final void Function(String sort, String time) onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  final _sortOptions = ['Revenue', 'Units Sold', 'Rating', 'Recent'];
  final _timeOptions = ['This Month', 'Last 30 days', 'Last 90 days', 'Custom Date'];
  late String _sort;
  late String _time;

  @override
  void initState() {
    super.initState();
    _sort = widget.selectedSort;
    _time = widget.selectedTime;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(DesignTokens.s16, DesignTokens.s16, DesignTokens.s16, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filter Products', style: DesignTokens.mediumSemibold),
                IconButton(
                  icon: const Icon(Icons.close, color: DesignTokens.textMuted, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),
            Text('Sort By', style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w700, color: DesignTokens.textWhite)),
            ..._sortOptions.map((opt) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: opt,
              groupValue: _sort,
              activeColor: DesignTokens.primaryGreen,
              title: Text(opt, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite)),
              onChanged: (v) => setState(() => _sort = v!),
            )),
            const SizedBox(height: DesignTokens.s8),
            Text('Time:', style: DesignTokens.smallRegular.copyWith(fontWeight: FontWeight.w700, color: DesignTokens.textWhite)),
            ..._timeOptions.map((opt) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: opt,
              groupValue: _time,
              activeColor: DesignTokens.primaryGreen,
              title: Text(opt, style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite)),
              onChanged: (v) => setState(() => _time = v!),
            )),
            const SizedBox(height: DesignTokens.s16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: DesignTokens.buttonHeight,
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onClear();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2E),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text('Clear', style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textWhite, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: SizedBox(
                    height: DesignTokens.buttonHeight,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_sort, _time);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text('Apply', style: DesignTokens.smallRegular.copyWith(color: Colors.black, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s16),
          ],
        ),
      ),
    );
  }
}

class _Product {
  const _Product({
    required this.name,
    this.assetImage,
    required this.rating,
    required this.totalSales,
    required this.revenue,
    required this.creators,
    required this.unitsSold,
    required this.stockCount,
    required this.isLowStock,
  });

  final String name;
  final String? assetImage;
  final double rating;
  final int totalSales;
  final String revenue;
  final int creators;
  final int unitsSold;
  final int stockCount;
  final bool isLowStock;
}
