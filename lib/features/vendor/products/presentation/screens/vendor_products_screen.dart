import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/notifiers/vendor_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/widgets/vendor_product_actions.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/widgets/vendor_product_tile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

final _sampleProducts = {
  'active': [
    VendorProduct(id: '1', name: 'Nike Sportswear Lightweight Synthetic Fill', imageUrl: '', price: const Money(amount: 18000, currency: 'NPR'), stockCount: 56, status: VendorProductStatus.active, totalSales: 47, rating: 4.8, createdAt: DateTime(2025, 1, 1), commissionRate: 20, reviewCount: 234, reelCount: 12),
    VendorProduct(id: '2', name: 'Nike Air Jordan Travis Scott Limited Edition', imageUrl: '', price: const Money(amount: 25000, currency: 'NPR'), stockCount: 20000, status: VendorProductStatus.active, totalSales: 45, rating: 4.9, createdAt: DateTime(2025, 1, 1), commissionRate: 15, reviewCount: 234, reelCount: 88),
    VendorProduct(id: '3', name: 'Nike Air Max 2025', imageUrl: '', price: const Money(amount: 18000, currency: 'NPR'), stockCount: 12787, status: VendorProductStatus.active, totalSales: 45, rating: 4.4, createdAt: DateTime(2025, 1, 1), commissionRate: 18, reviewCount: 234, reelCount: 109),
    VendorProduct(id: '4', name: 'Nike Sportswear Tech Fleece', imageUrl: '', price: const Money(amount: 12500, currency: 'NPR'), stockCount: 690, status: VendorProductStatus.active, totalSales: 45, rating: 4.6, createdAt: DateTime(2025, 1, 1), commissionRate: 12, reviewCount: 234, reelCount: 22),
  ],
  'draft': [
    VendorProduct(id: '5', name: 'Nike Dri-FIT Training T-Shirt', imageUrl: '', price: const Money(amount: 4500, currency: 'NPR'), stockCount: 0, status: VendorProductStatus.draft, totalSales: 0, rating: 0, createdAt: DateTime(2025, 1, 1)),
    VendorProduct(id: '6', name: 'Nike Air Force 1 Low White', imageUrl: '', price: const Money(amount: 15000, currency: 'NPR'), stockCount: 0, status: VendorProductStatus.draft, totalSales: 0, rating: 0, createdAt: DateTime(2025, 1, 1)),
  ],
  'out_of_stock': [
    VendorProduct(id: '7', name: 'Nike React Infinity Run Flyknit 3', imageUrl: '', price: const Money(amount: 22000, currency: 'NPR'), stockCount: 0, status: VendorProductStatus.outOfStock, totalSales: 38, rating: 4.7, createdAt: DateTime(2025, 1, 1), reviewCount: 189, reelCount: 45),
  ],
};

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

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: DesignTokens.s16,
        title: const CircleAvatar(
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
            icon: const Icon(Icons.search, color: DesignTokens.iconLight),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: DesignTokens.iconLight,
            ),
            onPressed: () {},
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
          products: products,
          hasMore: hasMore,
          onRefresh: () => ref
              .read(vendorProductsNotifierProvider.notifier)
              .loadProducts(status: _tabs[_tabController.index].$1),
          onLoadMore: () => ref
              .read(vendorProductsNotifierProvider.notifier)
              .loadMoreProducts(),
          onMore: (p) => showVendorProductActions(context, ref, p),
        ),
        loadFailure: (_) => _ProductList(
          products: _sampleProducts[_tabs[_tabController.index].$1] ?? [],
          hasMore: false,
          onRefresh: () => ref
              .read(vendorProductsNotifierProvider.notifier)
              .loadProducts(status: _tabs[_tabController.index].$1),
          onLoadMore: () {},
          onMore: (p) => showVendorProductActions(context, ref, p),
        ),
        actionInProgress: (products) => _ProductList(
          products: products,
          hasMore: false,
          onRefresh: () {},
          onLoadMore: () {},
          onMore: (p) => showVendorProductActions(context, ref, p),
        ),
        actionFailure: (products, _) => _ProductList(
          products: products,
          hasMore: false,
          onRefresh: () {},
          onLoadMore: () {},
          onMore: (p) => showVendorProductActions(context, ref, p),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DesignTokens.primaryGreen,
        shape: const StadiumBorder(),
        onPressed: () => context.push(RouteNames.addProduct),
        icon: const Icon(Icons.add, color: DesignTokens.textDark),
        label: Text(
          'Add Product',
          style: DesignTokens.oneLinerSemibold.copyWith(
            color: DesignTokens.textDark,
          ),
        ),
      ),
      bottomNavigationBar: _VendorBottomNav(
        selectedIndex: 2,
        onTap: (i) {
          if (i == 0) context.go(RouteNames.vendorDash);
          if (i == 1) context.go(RouteNames.vendorOrders);
          if (i == 3) context.go(RouteNames.settings);
        },
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
            onTap: () {},
            onMore: () => onMore(products[i]),
          );
        },
      ),
    );
  }
}

// ── Bottom nav ────────────────────────────────────────────────────────────────

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.assetIcon,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? assetIcon;
}

class _VendorBottomNav extends StatelessWidget {
  const _VendorBottomNav({
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    _NavItem(icon: Icons.home_outlined,       activeIcon: Icons.home,        label: 'Home'),
    _NavItem(icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: 'Orders'),
    _NavItem(icon: Icons.grid_view_outlined,   activeIcon: Icons.grid_view,   label: 'Products', assetIcon: 'assets/images/vendordashboard/nav_products.png'),
    _NavItem(icon: Icons.person_outline,       activeIcon: Icons.person,      label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppFoundation,
        border: Border(
          top: BorderSide(
            color: DesignTokens.borderDefault.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final selected = selectedIndex == i;
              final color = selected
                  ? DesignTokens.primaryGreen
                  : DesignTokens.textMuted;
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 72,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      item.assetIcon != null
                          ? Image.asset(
                              item.assetIcon!,
                              width: 24,
                              height: 24,
                              color: color,
                            )
                          : Icon(
                              selected ? item.activeIcon : item.icon,
                              color: color,
                              size: 24,
                            ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontFamily: DesignTokens.fontFamily,
                          fontSize: 11,
                          color: color,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
