import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/notifiers/vendor_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/presentation/widgets/vendor_product_tile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorProductsScreen extends ConsumerWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorProductsNotifierProvider);

    ref.listen<ProductsState>(vendorProductsNotifierProvider, (prev, next) {
      next.maybeWhen(
        actionFailure: (_, __) {
          SmSnackbar.error(context, 'Action failed. Please try again.');
        },
        orElse: () {},
      );
    });

    final activeFilter = state.maybeWhen(
      loadSuccess: (products, nextCursor, hasMore, filter) => filter,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text('My Products',
            style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search,
                color: DesignTokens.iconLight),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _FilterChips(
            selected: activeFilter,
            onSelected: (filter) {
              ref
                  .read(vendorProductsNotifierProvider.notifier)
                  .loadProducts(status: filter);
            },
          ),
          Expanded(
            child: state.when(
              initial: _loader,
              loadInProgress: _loader,
              loadSuccess: (products, nextCursor, hasMore, activeFilter) {
                if (products.isEmpty) {
                  return const SmEmptyState(
                    message: 'No products yet.',
                    icon: Icons.inventory_2_outlined,
                  );
                }
                return RefreshIndicator(
                  color: DesignTokens.primaryGreen,
                  onRefresh: () =>
                      ref.read(vendorProductsNotifierProvider.notifier).loadProducts(),
                  child: ListView.builder(
                    itemCount: products.length + (hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= products.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(vendorProductsNotifierProvider.notifier)
                              .loadMoreProducts();
                        });
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: DesignTokens.primaryGreen),
                          ),
                        );
                      }
                      return VendorProductTile(
                        product: products[i],
                        onTap: () {},
                        onEdit: () {},
                        onDelete: () {
                          ref
                              .read(vendorProductsNotifierProvider.notifier)
                              .deleteProduct(products[i].id);
                        },
                      );
                    },
                  ),
                );
              },
              loadFailure: (failure) => SmErrorView(
                message: 'Failed to load products.',
                onRetry: () =>
                    ref.read(vendorProductsNotifierProvider.notifier).loadProducts(),
              ),
              actionInProgress: (products) => _productsList(products, ref),
              actionFailure: (products, _) => _productsList(products, ref),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.primaryGreen,
        onPressed: () => context.push(RouteNames.addProduct),
        child: const Icon(Icons.add, color: DesignTokens.textDark),
      ),
    );
  }

  Widget _productsList(List<VendorProduct> products, WidgetRef ref) {
    return RefreshIndicator(
      color: DesignTokens.primaryGreen,
      onRefresh: () =>
          ref.read(vendorProductsNotifierProvider.notifier).loadProducts(),
      child: ListView.builder(
        itemCount: products.length,
        itemBuilder: (_, i) => VendorProductTile(
          product: products[i],
          onTap: () {},
          onDelete: () {
            ref
                .read(vendorProductsNotifierProvider.notifier)
                .deleteProduct(products[i].id);
          },
        ),
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _filters = [
    (null, 'All'),
    ('active', 'Active'),
    ('draft', 'Draft'),
    ('out_of_stock', 'Out of Stock'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: _filters.map((f) {
          final isSelected = selected == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s8),
            child: GestureDetector(
              onTap: () => onSelected(f.$2 == 'All' ? null : f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
                decoration: isSelected
                    ? DesignTokens.chipDecorationSelected()
                    : DesignTokens.chipDecorationDefault(),
                child: Text(
                  f.$2,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: isSelected
                        ? DesignTokens.primaryGreen
                        : DesignTokens.chipsDefaultText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
