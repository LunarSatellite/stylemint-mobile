import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/notifiers/vendor_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/widgets/vendor_product_actions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/widgets/vendor_product_tile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/shared/widgets/vendor_bottom_nav.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/root_back_guard.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorProductsScreen extends ConsumerStatefulWidget {
  const VendorProductsScreen({super.key});

  @override
  ConsumerState<VendorProductsScreen> createState() =>
      _VendorProductsScreenState();
}

class _VendorProductsScreenState extends ConsumerState<VendorProductsScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = [
    ('active', 'Active'),
    ('draft', 'Draft'),
    ('out_of_stock', 'Out of Stock'),
  ];

  late final TabController _tabController;
  bool _searching = false;
  String _query = '';
  final _searchCtrl = TextEditingController();

  List<VendorProduct> _filtered(List<VendorProduct> products) => _query.isEmpty
      ? products
      : products
            .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
            .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(vendorProductsNotifierProvider.notifier)
          .loadProducts(status: _tabs[0].$1);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    ref
        .read(vendorProductsNotifierProvider.notifier)
        .loadProducts(status: _tabs[_tabController.index].$1);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorProductsNotifierProvider);

    ref.listen<ProductsState>(vendorProductsNotifierProvider, (_, next) {
      next.maybeWhen(
        actionFailure: (_, __) =>
            SmSnackbar.error(context, 'Action failed. Please try again.'),
        orElse: () {},
      );
    });

    return RootBackGuard(
      fallback: RouteNames.vendorHome,
      child: Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        // Reached via context.go() from the dashboard's bottom nav, which
        // clears back history — GoRouter has nothing to auto-detect a
        // leading arrow from, so it's explicit here instead.
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DesignTokens.textWhite, size: 20),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.vendorHome),
        ),
        titleSpacing: DesignTokens.s16,
        title: _searching
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: DesignTokens.oneLinerRegular,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: DesignTokens.textMuted),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              )
            : const CircleAvatar(
                radius: 18,
                backgroundColor: DesignTokens.bgAppBodyLight,
                child: Icon(
                  Icons.store_outlined,
                  color: DesignTokens.textMuted,
                  size: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _searching ? Icons.close : Icons.search,
              color: DesignTokens.iconLight,
            ),
            onPressed: () => setState(() {
              _searching = !_searching;
              if (!_searching) {
                _searchCtrl.clear();
                _query = '';
              }
            }),
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: DesignTokens.iconLight,
            ),
            onPressed: () => context.push(RouteNames.vendorRecentActivity),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: DesignTokens.primaryGreen,
          indicatorWeight: 2,
          labelColor: DesignTokens.primaryGreen,
          unselectedLabelColor: DesignTokens.textMuted,
          labelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          dividerColor: Colors.transparent,
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: state.when(
        initial: _loader,
        loadInProgress: _loader,
        loadSuccess: (products, _, hasMore, __) => _ProductList(
          products: _filtered(products),
          hasMore: _query.isEmpty && hasMore,
          onRefresh: () => ref
              .read(vendorProductsNotifierProvider.notifier)
              .loadProducts(status: _tabs[_tabController.index].$1),
          onLoadMore: () => ref
              .read(vendorProductsNotifierProvider.notifier)
              .loadMoreProducts(),
          onMore: (p) => showVendorProductActions(context, ref, p),
        ),
        loadFailure: (_) => SmErrorView(
          message: 'Failed to load products.',
          onRetry: () => ref
              .read(vendorProductsNotifierProvider.notifier)
              .loadProducts(status: _tabs[_tabController.index].$1),
        ),
        actionInProgress: (products) => _ProductList(
          products: _filtered(products),
          hasMore: false,
          onRefresh: () {},
          onLoadMore: () {},
          onMore: (p) => showVendorProductActions(context, ref, p),
        ),
        actionFailure: (products, _) => _ProductList(
          products: _filtered(products),
          hasMore: false,
          onRefresh: () {},
          onLoadMore: () {},
          onMore: (p) => showVendorProductActions(context, ref, p),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DesignTokens.primaryGreen,
        shape: const StadiumBorder(),
        onPressed: () async {
          // The wizard is one route (IndexedStack over its 5 steps), so
          // popping back here doesn't remount this screen — without an
          // explicit refresh, a just-published product wouldn't show up
          // until a manual pull-to-refresh or leaving/reentering the tab.
          final published = await context.push<bool>(RouteNames.addProduct);
          if (published == true && context.mounted) {
            ref
                .read(vendorProductsNotifierProvider.notifier)
                .loadProducts(status: _tabs[_tabController.index].$1);
          }
        },
        icon: const Icon(Icons.add, color: DesignTokens.textDark),
        label: Text(
          'Add Product',
          style: DesignTokens.oneLinerSemibold.copyWith(
            color: DesignTokens.textDark,
          ),
        ),
      ),
      bottomNavigationBar: VendorBottomNav(
        selectedIndex: 2,
        onTap: (i) {
          if (i == 0) context.go(RouteNames.vendorHome);
          if (i == 1) context.go(RouteNames.vendorOrders);
            if (i == 3) context.push(RouteNames.vendorProfile);
        },
      ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

// ── Product list ──────────────────────────────────────────────────────────────

class _ProductList extends StatelessWidget {
  const _ProductList({
    required this.products,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onMore,
  });

  final List<VendorProduct> products;
  final bool hasMore;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<VendorProduct> onMore;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SmEmptyState(
        message: 'No products yet.',
        icon: Icons.inventory_2_outlined,
      );
    }
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(
          top: DesignTokens.s8,
          bottom: 100,
        ),
        itemCount: products.length + (hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= products.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(DesignTokens.s16),
                child: CircularProgressIndicator(
                  color: DesignTokens.primaryGreen,
                ),
              ),
            );
          }
          return VendorProductTile(
            product: products[i],
            onTap: () => context.push(
              RouteNames.vendorProductAnalytics,
              extra: products[i],
            ),
            onMore: () => onMore(products[i]),
          );
        },
      ),
    );
  }
}

// Bottom nav — see VendorBottomNav (shared/widgets/vendor_bottom_nav.dart).
