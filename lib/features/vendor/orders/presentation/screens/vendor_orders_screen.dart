import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorOrdersNotifierProvider);
    final orders = state.maybeWhen(
      loadSuccess: (orders, nextCursor, hasMore, activeFilter) => orders,
      orElse: () => const <VendorOrder>[],
    );

    final toShip = orders.where((o) => o.status.isToShip).toList(growable: false);
    final inTransit = orders.where((o) => o.status.isInTransit).toList(growable: false);
    // NOTE: backend only exposes one intermediate "shipped" status, so
    // "Shipped" currently mirrors "In Transit" until a finer distinction is
    // available.
    final shipped = inTransit;
    final completed = orders.where((o) => o.status.isCompleted).toList(growable: false);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: const Text(
          'Your Orders',
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: DesignTokens.textWhite,
            height: 1.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.filter_list,
              color: DesignTokens.textWhite,
              size: 24,
            ),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              backgroundColor: const Color(0xFF1C1C1E),
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) => const _FilterSheet(),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: const EdgeInsets.only(left: 16),
          labelPadding: const EdgeInsets.only(right: 20),
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          indicatorColor: DesignTokens.primaryGreen,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: [
            Tab(text: 'To Ship(${toShip.length})'),
            Tab(text: 'In Transit(${inTransit.length})'),
            Tab(text: 'Shipped(${shipped.length})'),
            Tab(text: 'Completed(${completed.length})'),
          ],
        ),
      ),
      body: state.maybeWhen(
        loadInProgress: () => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
        ),
        loadFailure: (_) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to load orders.',
                style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
              ),
              const SizedBox(height: DesignTokens.s8),
              TextButton(
                onPressed: () => ref.read(vendorOrdersNotifierProvider.notifier).loadOrders(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        orElse: () => TabBarView(
          controller: _tabController,
          children: [
            _OrderList(orders: toShip),
            _OrderList(orders: inTransit),
            _OrderList(orders: shipped),
            _OrderList(orders: completed),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bottom sheet
// ---------------------------------------------------------------------------
// NOTE: Product / Date Range / Order Value / Shipping Method filters here are
// cosmetic only — the backend's GET /v1/vendor/sub-orders filter parameters
// beyond `status` aren't confirmed against Swagger, so this sheet doesn't
// wire into a real query yet.

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _selectedProduct;
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  final _shippingMethods = <String, bool>{
    'Standard': false,
    'Express': false,
    'Overnight': false,
  };

  static const _products = ['All Products', 'Dress', 'T-Shirt', 'Jeans', 'Jacket'];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _selectedProduct = null;
      _fromController.clear();
      _toController.clear();
      _minController.clear();
      _maxController.clear();
      for (final k in _shippingMethods.keys) {
        _shippingMethods[k] = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF48484A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Orders',
                  style: TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: DesignTokens.textWhite, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product dropdown
                _FieldShell(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedProduct,
                      hint: const Text(
                        'Product',
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: Color(0xFF9F9FA9),
                        ),
                      ),
                      isExpanded: true,
                      dropdownColor: const Color(0xFF2C2C2E),
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF9F9FA9)),
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: DesignTokens.textWhite,
                      ),
                      items: _products
                          .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedProduct = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date Range
                const _SectionLabel('Date Range'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _FieldShell(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _fromController,
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 14,
                                  color: DesignTokens.textWhite,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'From',
                                  hintStyle: TextStyle(color: Color(0xFF9F9FA9)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                color: Color(0xFF9F9FA9), size: 16),
                          ],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—',
                          style: TextStyle(color: Color(0xFF9F9FA9), fontSize: 16)),
                    ),
                    Expanded(
                      child: _FieldShell(
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _toController,
                                style: const TextStyle(
                                  fontFamily: DesignTokens.fontFamily,
                                  fontSize: 14,
                                  color: DesignTokens.textWhite,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'To',
                                  hintStyle: TextStyle(color: Color(0xFF9F9FA9)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined,
                                color: Color(0xFF9F9FA9), size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Order Value
                const _SectionLabel('Order Value (In NPR)'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _FieldShell(
                        child: TextField(
                          controller: _minController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            color: DesignTokens.textWhite,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Min',
                            hintStyle: TextStyle(color: Color(0xFF9F9FA9)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('—',
                          style: TextStyle(color: Color(0xFF9F9FA9), fontSize: 16)),
                    ),
                    Expanded(
                      child: _FieldShell(
                        child: TextField(
                          controller: _maxController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 14,
                            color: DesignTokens.textWhite,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Max',
                            hintStyle: TextStyle(color: Color(0xFF9F9FA9)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Shipping Method checkboxes
                const _SectionLabel('Shipping Method'),
                const SizedBox(height: 4),
                ..._shippingMethods.keys.map((method) {
                  return CheckboxListTile(
                    value: _shippingMethods[method],
                    onChanged: (v) =>
                        setState(() => _shippingMethods[method] = v ?? false),
                    title: Text(
                      method,
                      style: const TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        color: DesignTokens.textWhite,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: DesignTokens.primaryGreen,
                    checkColor: Colors.black,
                    side: const BorderSide(color: Color(0xFF9F9FA9), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  );
                }),
                const SizedBox(height: 20),

                // Clear / Apply buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _clear,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A3A3C),
                            foregroundColor: DesignTokens.textWhite,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DesignTokens.primaryGreen,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldShell extends StatelessWidget {
  const _FieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: DesignTokens.textWhite,
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders});

  final List<VendorOrder> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return const Center(
        child: Text('No orders', style: TextStyle(color: DesignTokens.textMuted)),
      );
    }
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () => ref.read(vendorOrdersNotifierProvider.notifier).loadOrders(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: orders.length,
        itemBuilder: (_, i) => _OrderTile(order: orders[i]),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final VendorOrder order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        RouteNames.vendorOrderDetail.replaceFirst(':orderId', order.id),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 48×48 icon container
          Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.bgAppBodyLight,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/vendordashboard/package.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),

          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order number — white 14px semibold
                Text(
                  'Order #${order.orderNumber}',
                  style: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: DesignTokens.textWhite,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Amount · date · items — muted 12px
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 0,
                  children: [
                    _MutedText(formatMoney(order.total)),
                    if (order.placedAt != null) ...[
                      _DotSep(),
                      _MutedText(_formatDate(order.placedAt!)),
                    ],
                    _DotSep(),
                    _MutedText('${order.itemCount} items'),
                  ],
                ),
                const SizedBox(height: 6),

                // Customer chip — #B8E6FE bg, #024A70 text, person icon
                if (order.customerName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8E6FE),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          size: 12,
                          color: Color(0xFF024A70),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Customer: ${order.customerName}',
                          style: const TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF024A70),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Chevron — muted 16px
          const Icon(
            Icons.arrow_forward_ios,
            color: Color(0xFF9F9FA9),
            size: 16,
          ),
        ],
      ),
      ),
    );
  }

  static String _formatDate(DateTime utc) {
    final local = utc.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: DesignTokens.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: Color(0xFF9F9FA9),
        height: 1.3,
      ),
    );
  }
}

class _DotSep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF71717B),
        shape: BoxShape.circle,
      ),
    );
  }
}
