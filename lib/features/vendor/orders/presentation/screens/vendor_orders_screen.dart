import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart' show Either;
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_return_request.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_warranty_workspace.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_order_status_badge.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_return_card.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_bottom_nav.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_menu_button.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/root_back_guard.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_skeleton.dart';

class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

/// Sub-filter of the "To Ship" tab by seller step.
enum _ToShipFilter {
  all('All'),
  fresh('New'),
  accepted('Accepted'),
  packed('Packed');

  const _ToShipFilter(this.label);

  final String label;

  bool matches(VendorOrder order) => switch (this) {
    _ToShipFilter.all => true,
    _ToShipFilter.fresh =>
      order.status == VendorOrderStatus.pending ||
          order.status == VendorOrderStatus.confirmed ||
          order.status == VendorOrderStatus.processing,
    _ToShipFilter.accepted => order.status == VendorOrderStatus.accepted,
    _ToShipFilter.packed => order.status == VendorOrderStatus.packed,
  };
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  _ToShipFilter _toShipFilter = _ToShipFilter.all;

  /// Bulk accept, same select pattern as Orders Ready to Ship.
  bool _selectMode = false;
  final Set<String> _selectedIds = {};
  bool _busy = false;

  void _enterSelectMode() {
    _tabController.animateTo(0);
    setState(() {
      _selectMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelectMode() => setState(() {
    _selectMode = false;
    _selectedIds.clear();
  });

  void _toggleSelection(String id) => setState(() {
    if (!_selectedIds.remove(id)) _selectedIds.add(id);
  });

  Future<void> _bulkAccept() async {
    if (_selectedIds.isEmpty || _busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(vendorOrdersNotifierProvider.notifier)
        .bulkAccept(_selectedIds.toList(growable: false));
    if (!mounted) return;
    setState(() {
      _busy = false;
      _selectMode = false;
      _selectedIds.clear();
    });
    final message = result == null
        ? 'Couldn’t accept those orders. Please try again.'
        : result.failureCount == 0
        ? '${result.successCount} order(s) accepted.'
        : '${result.successCount} accepted, ${result.failureCount} failed.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
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

    final toShip = orders
        .where((o) => o.status.isPreShipment)
        .toList(growable: false);
    final inTransit = orders
        .where((o) => o.status.isInTransit)
        .toList(growable: false);
    // NOTE: backend only exposes one intermediate "shipped" status, so
    // "Shipped" currently mirrors "In Transit" until a finer distinction is
    // available.
    final shipped = inTransit;
    final completed = orders
        .where((o) => o.status.isCompleted)
        .toList(growable: false);
    final toShipVisible = toShip
        .where(_toShipFilter.matches)
        .toList(growable: false);
    final canBulkAccept = toShip.any((o) => o.canAccept);

    return RootBackGuard(
      fallback: RouteNames.vendorHome,
      child: Scaffold(
        backgroundColor: DesignTokens.bgAppFoundation,
        appBar: AppBar(
          backgroundColor: DesignTokens.bgAppFoundation,
          elevation: 0,
          centerTitle: false,
          // Reached via context.go() from the dashboard's bottom nav, which
          // clears back history — there's nothing for GoRouter to auto-detect,
          // so the leading back arrow needs to be explicit, not just re-enabled.
          automaticallyImplyLeading: false,
          leading: _selectMode
              ? IconButton(
                  tooltip: 'Cancel selection',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DesignTokens.textWhite,
                  ),
                  onPressed: _busy ? null : _exitSelectMode,
                )
              : IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: DesignTokens.textWhite,
                    size: 20,
                  ),
                  onPressed: () => context.canPop()
                      ? context.popOrHome()
                      : context.go(RouteNames.vendorHome),
                ),
          title: Text(
            _selectMode ? 'Select orders to accept' : 'Your Orders',
            style: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: DesignTokens.textWhite,
              height: 1.3,
            ),
          ),
          actions: [
            if (!_selectMode && canBulkAccept)
              IconButton(
                tooltip: 'Accept several orders',
                icon: const Icon(
                  Icons.checklist_rounded,
                  color: DesignTokens.textWhite,
                ),
                onPressed: _enterSelectMode,
              ),
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => const _FilterSheet(),
              ),
            ),
            // The store tools (Partnerships, Brand Studio, Payouts, …) used to
            // hang off the Home tab alone, so a vendor standing here had to go
            // back Home to reach any of them.
            const VendorMenuButton(),
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
              const Tab(text: 'Returns'),
              const Tab(text: 'Warranty'),
            ],
          ),
        ),
        body: state.maybeWhen(
          loadInProgress: () => const SmListSkeleton(itemCount: 6),
          loadFailure: (_) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load orders.',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s8),
                TextButton(
                  onPressed: () => ref
                      .read(vendorOrdersNotifierProvider.notifier)
                      .loadOrders(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          orElse: () => TabBarView(
            controller: _tabController,
            children: [
              _OrderList(
                orders: toShipVisible,
                header: _ToShipFilterChips(
                  selected: _toShipFilter,
                  onSelected: (f) => setState(() => _toShipFilter = f),
                ),
                selectMode: _selectMode,
                selectedIds: _selectedIds,
                onToggle: _toggleSelection,
              ),
              _OrderList(orders: inTransit),
              _OrderList(orders: shipped),
              _OrderList(orders: completed),
              const _VendorReturnsWorkspace(),
              const VendorWarrantyWorkspace(),
            ],
          ),
        ),
        bottomNavigationBar: _selectMode
            ? _AcceptSelectBar(
                count: _selectedIds.length,
                busy: _busy,
                onCancel: _exitSelectMode,
                onAccept: _bulkAccept,
              )
            : VendorBottomNav(
                selectedIndex: 1,
                onTap: (i) {
                  if (i == 0) context.go(RouteNames.vendorHome);
                  if (i == 2) context.go(RouteNames.vendorProducts);
                  if (i == 3) context.push(RouteNames.vendorProfile);
                },
              ),
      ),
    );
  }
}

class _ToShipFilterChips extends StatelessWidget {
  const _ToShipFilterChips({required this.selected, required this.onSelected});

  final _ToShipFilter selected;
  final ValueChanged<_ToShipFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (final filter in _ToShipFilter.values) ...[
            ChoiceChip(
              label: Text(filter.label),
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              backgroundColor: DesignTokens.bgAppBodyLight,
              selectedColor: DesignTokens.primaryGreen,
              side: BorderSide.none,
              shape: const StadiumBorder(),
              labelStyle: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: filter == selected
                    ? DesignTokens.buttonPrimaryText
                    : DesignTokens.textLight,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _AcceptSelectBar extends StatelessWidget {
  const _AcceptSelectBar({
    required this.count,
    required this.busy,
    required this.onCancel,
    required this.onAccept,
  });

  final int count;
  final bool busy;
  final VoidCallback onCancel;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        boxShadow: DesignTokens.shadowLifted,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: busy ? null : onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: DesignTokens.textLight,
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: count == 0 || busy ? null : onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.primaryGreen,
                    foregroundColor: DesignTokens.buttonPrimaryText,
                    disabledBackgroundColor: DesignTokens.bgAppBodyLight,
                    disabledForegroundColor: DesignTokens.textMuted,
                    minimumSize: const Size.fromHeight(50),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DesignTokens.buttonPrimaryText,
                          ),
                        )
                      : Text(count == 0 ? 'Accept' : 'Accept ($count)'),
                ),
              ),
            ],
          ),
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

  static const _products = [
    'All Products',
    'Dress',
    'T-Shirt',
    'Jeans',
    'Jacket',
  ];

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
      child: SafeArea(
        top: false,
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
                    icon: const Icon(
                      Icons.close,
                      color: DesignTokens.textWhite,
                      size: 20,
                    ),
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
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF9F9FA9),
                        ),
                        style: const TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 14,
                          color: DesignTokens.textWhite,
                        ),
                        items: _products
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
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
                                    hintStyle: TextStyle(
                                      color: Color(0xFF9F9FA9),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF9F9FA9),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '—',
                          style: TextStyle(
                            color: Color(0xFF9F9FA9),
                            fontSize: 16,
                          ),
                        ),
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
                                    hintStyle: TextStyle(
                                      color: Color(0xFF9F9FA9),
                                    ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Color(0xFF9F9FA9),
                                size: 16,
                              ),
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
                        child: Text(
                          '—',
                          style: TextStyle(
                            color: Color(0xFF9F9FA9),
                            fontSize: 16,
                          ),
                        ),
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
                      side: const BorderSide(
                        color: Color(0xFF9F9FA9),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
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
                                borderRadius: BorderRadius.circular(30),
                              ),
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
                                borderRadius: BorderRadius.circular(30),
                              ),
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
  const _OrderList({
    required this.orders,
    this.header,
    this.selectMode = false,
    this.selectedIds = const {},
    this.onToggle,
  });

  final List<VendorOrder> orders;

  /// Shown above the rows (and above the empty message).
  final Widget? header;
  final bool selectMode;
  final Set<String> selectedIds;
  final ValueChanged<String>? onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = header;
    if (orders.isEmpty && top == null) {
      return const Center(
        child: Text(
          'No orders',
          style: TextStyle(color: DesignTokens.textMuted),
        ),
      );
    }
    final offset = top == null ? 0 : 1;
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () =>
          ref.read(vendorOrdersNotifierProvider.notifier).loadOrders(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: orders.isEmpty ? offset + 1 : orders.length + offset,
        itemBuilder: (_, i) {
          if (top != null && i == 0) return top;
          if (orders.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No orders',
                  style: TextStyle(color: DesignTokens.textMuted),
                ),
              ),
            );
          }
          final order = orders[i - offset];
          return _OrderTile(
            order: order,
            selectMode: selectMode,
            selected: selectedIds.contains(order.id),
            onToggle: onToggle == null ? null : () => onToggle!(order.id),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({
    required this.order,
    this.selectMode = false,
    this.selected = false,
    this.onToggle,
  });

  final VendorOrder order;
  final bool selectMode;
  final bool selected;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    // In select mode only paid orders can be picked; the rest dim.
    final selectable = selectMode && order.canAccept;
    return Opacity(
      opacity: selectMode && !selectable ? 0.45 : 1,
      child: Semantics(
        selected: selectable ? selected : null,
        child: InkWell(
          onTap: selectMode
              ? (selectable ? onToggle : null)
              : () => context.push(
                  RouteNames.vendorOrderDetail.replaceFirst(
                    ':orderId',
                    order.id,
                  ),
                ),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 12),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 24,
                      color: selected
                          ? DesignTokens.primaryGreen
                          : DesignTokens.textMuted,
                    ),
                  ),
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
                      // Order number — white 14px semibold — and status badge.
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
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
                          VendorOrderStatusBadge(status: order.status),
                        ],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                if (!selectMode)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF9F9FA9),
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime utc) {
    final local = utc.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
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

class _VendorReturnsWorkspace extends ConsumerStatefulWidget {
  const _VendorReturnsWorkspace();

  @override
  ConsumerState<_VendorReturnsWorkspace> createState() =>
      _VendorReturnsWorkspaceState();
}

class _VendorReturnsWorkspaceState
    extends ConsumerState<_VendorReturnsWorkspace> {
  String? _busyId;

  Future<void> _approve(VendorReturnRequest request) async {
    await _mutate(
      request,
      () => ref.read(vendorOrdersRepositoryProvider).acceptReturn(request.id),
      'Return approved. Ask the customer to send the item back.',
    );
  }

  Future<void> _reject(VendorReturnRequest request) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.surfaceRaised,
        title: const Text('Why can’t this return be accepted?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Give the customer a clear reason',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Reject return'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    await _mutate(
      request,
      () => ref
          .read(vendorOrdersRepositoryProvider)
          .rejectReturn(request.id, reason),
      'Return rejected with the reason shared to the customer.',
    );
  }

  Future<void> _complete(VendorReturnRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.surfaceRaised,
        icon: const Icon(
          Icons.inventory_2_outlined,
          color: DesignTokens.primaryGreen,
        ),
        title: const Text('Item received and checked?'),
        content: const Text(
          'Confirm only after the returned item is physically received. '
          'This completes the return and starts the customer’s exact refund.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm & refund'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _mutate(
      request,
      () => ref.read(vendorOrdersRepositoryProvider).completeReturn(request.id),
      'Return completed. The refund has been started.',
    );
  }

  Future<void> _mutate(
    VendorReturnRequest request,
    Future<Either<NetworkExceptions, VendorReturnRequest>> Function() operation,
    String successMessage,
  ) async {
    if (_busyId != null) return;
    setState(() => _busyId = request.id);
    final result = await operation();
    if (!mounted) return;
    var message = successMessage;
    result.fold(
      (_) => message = 'Could not update this return. Please try again.',
      (_) => ref.invalidate(vendorReturnsProvider),
    );
    setState(() => _busyId = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final returns = ref.watch(vendorReturnsProvider);
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () async {
        ref.invalidate(vendorReturnsProvider);
        await ref.read(vendorReturnsProvider.future);
      },
      child: returns.when(
        loading: () => ListView(
          physics: AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: 300, child: SmPageLoader())],
        ),
        error: (_, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32),
          children: [
            const Icon(Icons.error_outline, color: DesignTokens.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Could not load returns.',
              textAlign: TextAlign.center,
            ),
            TextButton(
              onPressed: () => ref.invalidate(vendorReturnsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
        data: (result) => result.fold(
          (_) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(32),
            children: const [
              Text('Could not load returns.', textAlign: TextAlign.center),
            ],
          ),
          (page) {
            if (page.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(32),
                children: const [
                  Icon(
                    Icons.assignment_turned_in_outlined,
                    size: 52,
                    color: DesignTokens.primaryGreen,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No returns need attention',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(DesignTokens.s16),
              itemCount: page.items.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: DesignTokens.s12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${page.totalCount} return${page.totalCount == 1 ? '' : 's'} · '
                      'review evidence, then confirm only after receipt.',
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  );
                }
                final request = page.items[index - 1];
                return VendorReturnCard(
                  request: request,
                  busy: _busyId == request.id,
                  onApprove: () => _approve(request),
                  onReject: () => _reject(request),
                  onComplete: () => _complete(request),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
