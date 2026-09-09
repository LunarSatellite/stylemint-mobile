import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/discover_data.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/discover_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/trending_product_card.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Generic product list screen — used for "Trending Products" and
/// "[Category] Products" views.
class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key, required this.title, this.categoryId});

  final String title;
  final String? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: DesignTokens.sectionInnerTitle),
        centerTitle: false,
      ),
      body: categoryId == null
          ? _TrendingProductsList()
          : _CategoryProductsList(categoryId: categoryId!),
    );
  }
}

class _TrendingProductsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoverNotifierProvider);
    return state.when(
      initial: () => const _LoadingProducts(),
      loadInProgress: () => const _LoadingProducts(),
      loadFailure: (_) => _FailureProducts(
        onRetry: () =>
            ref.read(discoverNotifierProvider.notifier).fetchDiscover(),
      ),
      loadSuccess: (data) => _ProductsList(products: data.trending),
    );
  }
}

class _CategoryProductsList extends ConsumerWidget {
  const _CategoryProductsList({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(categoryProductsProvider(categoryId));
    return products.when(
      loading: () => const _LoadingProducts(),
      error: (_, _) => _FailureProducts(
        onRetry: () => ref.invalidate(categoryProductsProvider(categoryId)),
      ),
      data: (items) => _ProductsList(products: items),
    );
  }
}

class _ProductsList extends StatelessWidget {
  const _ProductsList({required this.products});

  final List<TrendingProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(
        child: Text(
          'No products are available right now.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => TrendingProductCard(
        product: products[i],
        onTap: () => context.push(
          RouteNames.productDetail.replaceFirst(':productId', products[i].id),
        ),
      ),
    );
  }
}

class _LoadingProducts extends StatelessWidget {
  const _LoadingProducts();

  @override
  Widget build(BuildContext context) => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _FailureProducts extends StatelessWidget {
  const _FailureProducts({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: onRetry,
      child: const Text('Could not load products. Try again.'),
    ),
  );
}
