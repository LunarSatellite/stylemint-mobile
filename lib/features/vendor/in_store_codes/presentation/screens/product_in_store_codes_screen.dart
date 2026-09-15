import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/vendor/in_store_codes/presentation/widgets/vendor_code_sheet.dart';
import 'package:stylemint_mobile_frontend/features/vendor/products/domain/entities/vendor_product.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/domain/entities/vendor_store.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/presentation/widgets/vendor_store_tile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/stores/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Products → ⋮ → "In-store codes": pick the store where the product sits on
/// the shelf, then show (or make) its StyleMint code there.
class ProductInStoreCodesScreen extends ConsumerWidget {
  const ProductInStoreCodesScreen({
    required this.productId,
    this.product,
    super.key,
  });

  static const String title = 'In-store codes';
  static const String pickStore =
      'Choose the store where this product is on the shelf. Shoppers scan '
      'or tap its code to watch reels and buy it on StyleMint.';
  static const String noStores =
      "You haven't added a store yet. Add the shop or branch where this "
      'product is sold.';

  final String productId;

  /// The product from the Products list; null when opened without it.
  final VendorProduct? product;

  void _openCode(BuildContext context, VendorStore store) {
    final item = product;
    unawaited(
      showVendorCodeSheet(
        context,
        target: (productId: productId, storeId: store.id),
        subject: VendorCodeSubject(
          title: item?.name ?? 'Product',
          storeName: store.name,
          storeCity: store.city,
          price: item == null ? null : formatMoney(item.price),
        ),
      ),
    );
  }

  Future<void> _addStore(BuildContext context) async {
    final created = await context.push<VendorStore>(RouteNames.vendorStoreNew);
    if (created != null && context.mounted) _openCode(context, created);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorStoresNotifierProvider);
    final item = product;

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
        title: const Text(title, style: DesignTokens.sectionInnerTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        children: [
          if (item != null) ...[
            _ProductHeader(product: item),
            const SizedBox(height: DesignTokens.s16),
          ],
          Text(
            pickStore,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          switch (state) {
            VendorStoresLoading() => const SizedBox(
              height: 160,
              child: SmPageLoader(),
            ),
            VendorStoresFailed() => SmErrorView(
              message: "Couldn't load your stores.",
              onRetry: () => unawaited(
                ref.read(vendorStoresNotifierProvider.notifier).load(),
              ),
            ),
            VendorStoresLoaded(:final stores) when stores.isEmpty =>
              const Text(noStores, style: DesignTokens.mediumRegular),
            VendorStoresLoaded(:final stores) => Column(
              children: [
                for (final store in stores) ...[
                  VendorStoreTile(
                    store: store,
                    trailingIcon: Icons.qr_code_2_rounded,
                    onTap: () => _openCode(context, store),
                  ),
                  const SizedBox(height: DesignTokens.s12),
                ],
              ],
            ),
          },
          const SizedBox(height: DesignTokens.s12),
          OutlinedButton.icon(
            onPressed: () => unawaited(_addStore(context)),
            style: DesignTokens.outlinedButtonStyle(),
            icon: const Icon(Icons.add_business_outlined),
            label: const Text('Add a store'),
          ),
        ],
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  const _ProductHeader({required this.product});

  final VendorProduct product;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.s12),
    decoration: DesignTokens.cardDecoration(),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(DesignTokens.s8),
          child: SizedBox.square(
            dimension: 56,
            child: product.imageUrl.isEmpty
                ? const ColoredBox(
                    color: DesignTokens.bgAppBodyLight,
                    child: Icon(Icons.image, color: DesignTokens.textMuted),
                  )
                : CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: DesignTokens.bgAppBodyLight,
                      child: Icon(Icons.image, color: DesignTokens.textMuted),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: DesignTokens.s12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DesignTokens.mediumSemibold,
              ),
              const SizedBox(height: DesignTokens.s4),
              Text(
                formatMoney(product.price),
                style: DesignTokens.smallRegular,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
