import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/notifiers/brand_storefront_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/widgets/brand_storefront_hero.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/presentation/widgets/brand_storefront_tabs.dart';
import 'package:stylemint_mobile_frontend/features/customer/brand_storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/product_listing_query.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/storefront_links.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_hero_parts.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_scaffold.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/presentation/widgets/storefront_states.dart';
import 'package:stylemint_mobile_frontend/features/customer/storefront/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';

/// `/brands/:vendorAccountId`: a brand's official flagship storefront.
class BrandStorefrontScreen extends ConsumerStatefulWidget {
  const BrandStorefrontScreen({required this.vendorAccountId, super.key});

  final String vendorAccountId;

  @override
  ConsumerState<BrandStorefrontScreen> createState() =>
      _BrandStorefrontScreenState();
}

class _BrandStorefrontScreenState extends ConsumerState<BrandStorefrontScreen> {
  BrandStorefrontTab _tab = BrandStorefrontTab.home;

  /// Shop All's sort and filters.
  late ProductListingQuery _shopQuery = brandNewestQuery(_id);

  String get _id => widget.vendorAccountId;

  void _openTab(BrandStorefrontTab tab) => setState(() => _tab = tab);

  Future<void> _share(String name) async {
    final link = StorefrontLinks.brandWeb(_id);
    try {
      await ref
          .read(storefrontExternalActionsProvider)
          .share(
            text: "Shop $name's official store on StyleMint\n$link",
            subject: '$name on StyleMint',
          );
    } on Object {
      if (mounted) {
        SmSnackbar.error(context, "Couldn't open sharing. Please try again.");
      }
    }
  }

  void _loadMore() {
    switch (_tab) {
      case BrandStorefrontTab.home:
      case BrandStorefrontTab.about:
        return;
      case BrandStorefrontTab.shopAll:
        unawaited(
          ref.read(storefrontProductsProvider(_shopQuery).notifier).loadMore(),
        );
      case BrandStorefrontTab.newIn:
        unawaited(
          ref
              .read(storefrontProductsProvider(brandNewestQuery(_id)).notifier)
              .loadMore(),
        );
      case BrandStorefrontTab.reels:
        unawaited(ref.read(vendorReelsProvider(_id).notifier).loadMore());
      case BrandStorefrontTab.collections:
        unawaited(
          ref
              .read(
                storefrontCollectionsProvider(
                  brandCollectionsKey(_id),
                ).notifier,
              )
              .loadMore(),
        );
    }
  }

  Object? _contentVersion() => switch (_tab) {
    BrandStorefrontTab.home || BrandStorefrontTab.about => null,
    BrandStorefrontTab.shopAll => ref.watch(
      storefrontProductsProvider(_shopQuery),
    ),
    BrandStorefrontTab.newIn => ref.watch(
      storefrontProductsProvider(brandNewestQuery(_id)),
    ),
    BrandStorefrontTab.reels => ref.watch(vendorReelsProvider(_id)),
    BrandStorefrontTab.collections => ref.watch(
      storefrontCollectionsProvider(brandCollectionsKey(_id)),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final header = ref.watch(brandStorefrontNotifierProvider(_id));
    // The Home tab's lists stay loaded for the whole visit.
    ref
      ..listen(storefrontProductsProvider(brandNewestQuery(_id)), (_, _) {})
      ..listen(
        storefrontProductsProvider(brandBestSellersQuery(_id)),
        (_, _) {},
      )
      ..listen(
        storefrontCollectionsProvider(brandCollectionsKey(_id)),
        (_, _) {},
      )
      ..listen(vendorReelsProvider(_id), (_, _) {});

    switch (header) {
      case BrandStorefrontNotFound():
        return StorefrontMessagePage(
          icon: Icons.storefront_outlined,
          title: "This brand isn't available",
          body: 'The store may be closed, or it is no longer on StyleMint.',
          actionLabel: 'Explore the Mall',
          onAction: () => context.go(RouteNames.home),
        );
      case BrandStorefrontFailure(:final failure):
        return StorefrontMessagePage(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't load this brand",
          body: storefrontErrorBody(failure),
          actionLabel: 'Try again',
          onAction: () => unawaited(
            ref.read(brandStorefrontNotifierProvider(_id).notifier).load(),
          ),
        );
      case BrandStorefrontLoading():
      case BrandStorefrontLoaded():
        break;
    }

    final brand = header is BrandStorefrontLoaded ? header.brand : null;
    final name = brand?.name ?? '';
    final coverExtent = StorefrontCover.extentFor(
      context,
      ratio: 0.66,
      min: 210,
      max: 340,
      topBarExtent: StorefrontScaffold.topBarExtentOf(context),
    );

    return StorefrontScaffold(
      title: name,
      coverExtent: coverExtent,
      tabs: [for (final tab in BrandStorefrontTab.values) tab.label],
      selectedTab: _tab.index,
      onTabChanged: (index) => _openTab(BrandStorefrontTab.values[index]),
      onShare: brand == null ? null : () => unawaited(_share(name)),
      shareLabel: 'Share $name',
      onNearEnd: _loadMore,
      contentVersion: _contentVersion(),
      hero: BrandStorefrontHero(
        vendorAccountId: _id,
        coverExtent: coverExtent,
        brand: brand,
        onShare: () => unawaited(_share(name)),
      ),
      slivers: [
        switch (_tab) {
          BrandStorefrontTab.home => BrandHomeTab(
            vendorAccountId: _id,
            brandName: name.isEmpty ? 'this brand' : name,
            brand: brand,
            onOpenTab: _openTab,
            onShopBestSellers: () => setState(() {
              _shopQuery = _shopQuery.withSort(ProductSort.bestselling);
              _tab = BrandStorefrontTab.shopAll;
            }),
          ),
          BrandStorefrontTab.shopAll => BrandProductsTab(
            query: _shopQuery,
            brandName: name.isEmpty ? 'This brand' : name,
            showControls: true,
            onQueryChanged: (query) => setState(() => _shopQuery = query),
          ),
          BrandStorefrontTab.newIn => BrandProductsTab(
            query: brandNewestQuery(_id),
            brandName: name.isEmpty ? 'this brand' : name,
            showControls: false,
            onQueryChanged: (_) {},
          ),
          BrandStorefrontTab.reels => BrandReelsTab(
            vendorAccountId: _id,
            brandName: name.isEmpty ? 'this brand' : name,
          ),
          BrandStorefrontTab.collections => BrandCollectionsTab(
            vendorAccountId: _id,
            brandName: name.isEmpty ? 'This brand' : name,
          ),
          BrandStorefrontTab.about => BrandAboutTab(brand: brand),
        },
      ],
    );
  }
}
