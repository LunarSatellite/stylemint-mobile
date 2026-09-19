import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/domain/entities/store_product.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/in_store_locations.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/widgets/endless_aisle_section.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/presentation/widgets/store_product_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/in_store/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// `/in-store/store/{storeId}` — where a store's StyleMint code leads.
///
/// Shows the store from the resolved code, then the vendor's products in a
/// two-column grid that loads more as the shopper scrolls. A product opens
/// the in-store product screen with this store's context. Without a vendor,
/// or when the vendor lists nothing, it points shoppers at the products' own
/// shelf codes instead.
class InStoreStoreScreen extends ConsumerWidget {
  const InStoreStoreScreen({
    required this.storeId,
    this.code,
    this.storeName,
    this.storeCity,
    this.vendorName,
    this.vendorId,
    super.key,
  });

  static const String productsTitle = 'Shop this store on StyleMint';
  static const String productsEmpty =
      "This store's products aren't listed here yet. Scan the StyleMint code "
      "on a product's shelf card to watch its reels and buy it.";
  static const String productsFailed = "Couldn't load this store's products.";
  static const String moreFailed = "Couldn't load more products.";

  /// How much scroll may remain, in logical pixels, when the next page of
  /// products starts loading.
  static const double loadMoreExtent = 600;

  final String storeId;
  final String? code;
  final String? storeName;
  final String? storeCity;
  final String? vendorName;

  /// The vendor's account id; its products fill the grid.
  final String? vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trimmedCode = code?.trim();
    final scannedCode = trimmedCode == null || trimmedCode.isEmpty
        ? null
        : trimmedCode;
    final vendorKey = vendorId?.trim() ?? '';
    final products = vendorKey.isEmpty
        ? null
        : storeProductsNotifierProvider(vendorKey);
    final state = products == null ? null : ref.watch(products);

    void load() {
      if (products != null) unawaited(ref.read(products.notifier).load());
    }

    void loadMore() {
      if (products != null) unawaited(ref.read(products.notifier).loadMore());
    }

    bool onScroll(ScrollNotification notification) {
      if (products == null ||
          notification.depth != 0 ||
          notification.metrics.extentAfter > loadMoreExtent) {
        return false;
      }
      final current = ref.read(products);
      if (current is StoreProductsLoaded &&
          current.hasMore &&
          !current.loadingMore &&
          !current.loadMoreFailed) {
        loadMore();
      }
      return false;
    }

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text('Store', style: DesignTokens.sectionInnerTitle),
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: onScroll,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.s20,
                DesignTokens.s20,
                DesignTokens.s20,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: _StoreHeader(
                  name: storeName ?? 'StyleMint store',
                  city: storeCity,
                  vendor: vendorName,
                ),
              ),
            ),
            if (scannedCode != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.s20,
                  DesignTokens.s16,
                  DesignTokens.s20,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: EndlessAisleSection(code: scannedCode),
                ),
              ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.s20,
                DesignTokens.s24,
                DesignTokens.s20,
                DesignTokens.s12,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  productsTitle,
                  style: DesignTokens.sectionInnerTitle,
                ),
              ),
            ),
            ..._productSlivers(state, onRetry: load, onLoadMore: loadMore),
          ],
        ),
      ),
    );
  }

  List<Widget> _productSlivers(
    StoreProductsState? state, {
    required VoidCallback onRetry,
    required VoidCallback onLoadMore,
  }) {
    Widget box(Widget child) => SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s20,
        0,
        DesignTokens.s20,
        DesignTokens.s24,
      ),
      sliver: SliverToBoxAdapter(child: child),
    );

    return switch (state) {
      null => [box(const _ScanShelfCodes())],
      StoreProductsLoading() => [
        box(const SizedBox(height: 160, child: SmPageLoader(size: 48))),
      ],
      StoreProductsFailed() => [
        box(SmErrorView(message: productsFailed, onRetry: onRetry)),
      ],
      StoreProductsLoaded(:final products) when products.isEmpty => [
        box(const _ScanShelfCodes()),
      ],
      StoreProductsLoaded(
        :final products,
        :final loadingMore,
        :final loadMoreFailed,
      ) =>
        [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s20),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: DesignTokens.s12,
                crossAxisSpacing: DesignTokens.s12,
                childAspectRatio: 0.66,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) =>
                  _productCard(context, products[index]),
            ),
          ),
          box(
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.s16),
              child: loadingMore
                  ? const SizedBox(height: 48, child: SmPageLoader(size: 32))
                  : loadMoreFailed
                  ? _LoadMoreFailed(onRetry: onLoadMore)
                  : const SizedBox.shrink(),
            ),
          ),
        ],
    };
  }

  Widget _productCard(BuildContext context, StoreProduct product) =>
      StoreProductCard(
        key: ValueKey('store-product-${product.id}'),
        product: product,
        onTap: () => unawaited(
          context.push(
            inStoreProductLocation(
              productId: product.id,
              storeId: storeId,
              code: code,
              storeName: storeName,
              storeCity: storeCity,
            ),
          ),
        ),
      );
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.name, this.city, this.vendor});

  final String name;
  final String? city;
  final String? vendor;

  @override
  Widget build(BuildContext context) {
    final city = this.city;
    final vendor = this.vendor;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: DesignTokens.cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: DesignTokens.primaryGreenDark,
            child: Icon(
              Icons.storefront_rounded,
              color: DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(width: DesignTokens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: DesignTokens.sectionInnerTitle),
                if (city != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text(city, style: DesignTokens.mediumRegular),
                ],
                if (vendor != null) ...[
                  const SizedBox(height: DesignTokens.s4),
                  Text('By $vendor', style: DesignTokens.smallRegular),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nothing to list: send the shopper to the products' own shelf codes.
class _ScanShelfCodes extends StatelessWidget {
  const _ScanShelfCodes();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s20),
    decoration: DesignTokens.cardDecoration(),
    child: Column(
      children: [
        const Icon(
          Icons.qr_code_scanner_rounded,
          size: 40,
          color: DesignTokens.iconLight,
        ),
        const SizedBox(height: DesignTokens.s12),
        Text(
          InStoreStoreScreen.productsEmpty,
          textAlign: TextAlign.center,
          style: DesignTokens.mediumRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        ElevatedButton.icon(
          onPressed: () => unawaited(context.push(RouteNames.scan)),
          style: DesignTokens.primaryButtonStyle(),
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: const Text('Scan a shelf code'),
        ),
      ],
    ),
  );
}

class _LoadMoreFailed extends StatelessWidget {
  const _LoadMoreFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        InStoreStoreScreen.moreFailed,
        textAlign: TextAlign.center,
        style: DesignTokens.mediumRegular.copyWith(
          color: DesignTokens.textMuted,
        ),
      ),
      TextButton(
        onPressed: onRetry,
        style: DesignTokens.textButtonStyle(),
        child: const Text('Try again'),
      ),
    ],
  );
}
