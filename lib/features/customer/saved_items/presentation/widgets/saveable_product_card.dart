import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/saved_products_providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';

const String savedProductErrorMessage =
    "Couldn't update your saved items. Please try again.";

/// The save heart's action everywhere: sign-in gate for guests, then the
/// optimistic toggle; a snackbar says so when it rolled back.
Future<void> toggleSavedProduct(
  BuildContext context,
  WidgetRef ref, {
  required String productId,
  String? variantId,
}) async {
  if (!await ensureAuth(context, ref, reason: AuthReason.save)) return;
  if (!context.mounted) return;
  // The session may have started (or signed in) after the saved list was
  // set up as signed out; rebuild it so the viewer's list is read.
  if (!ref.read(savedProductsSignedInProvider)) {
    ref.invalidate(savedProductsSignedInProvider);
  }
  final ok = await ref
      .read(savedProductsNotifierProvider.notifier)
      .toggle(productId, variantId: variantId);
  if (!context.mounted) return;
  if (!ok) {
    SmSnackbar.error(context, savedProductErrorMessage);
    return;
  }
  // The Saved Items screen keeps its own list; refresh it if it is alive.
  if (ref.exists(savedItemsNotifierProvider)) {
    unawaited(ref.read(savedItemsNotifierProvider.notifier).load());
  }
}

/// [product] with its heart set to [saved].
MallProductVm mallProductWithSaved(
  MallProductVm product, {
  required bool saved,
}) => product.isSaved == saved
    ? product
    : MallProductVm(
        id: product.id,
        name: product.name,
        price: product.price,
        brandName: product.brandName,
        imageUrl: product.imageUrl,
        compareAtPrice: product.compareAtPrice,
        rating: product.rating,
        isNew: product.isNew,
        isLowStock: product.isLowStock,
        isSaved: saved,
      );

/// A [MallProductCard] whose heart reads and toggles the shared saved list.
class SaveableMallProductCard extends ConsumerWidget {
  const SaveableMallProductCard({
    required this.product,
    super.key,
    this.size = MallCardSize.regular,
    this.onTap,
    this.variantId,
    this.showRating = true,
  });

  final MallProductVm product;
  final MallCardSize size;
  final VoidCallback? onTap;

  /// The SKU to save; the product's default variant when null.
  final String? variantId;
  final bool showRating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      savedProductsNotifierProvider.select((s) => s.isSaved(product.id)),
    );
    return MallProductCard(
      product: mallProductWithSaved(product, saved: saved),
      size: size,
      onTap: onTap,
      showRating: showRating,
      onSaveTap: () => unawaited(
        toggleSavedProduct(
          context,
          ref,
          productId: product.id,
          variantId: variantId,
        ),
      ),
    );
  }
}

/// A [MallSliverProductGrid] whose hearts read and toggle the saved list.
class SaveableSliverProductGrid extends ConsumerWidget {
  const SaveableSliverProductGrid({
    required this.products,
    super.key,
    this.onProductTap,
  });

  final List<MallProductVm> products;
  final ValueChanged<MallProductVm>? onProductTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      savedProductsNotifierProvider.select((s) => s.entries),
    );
    return MallSliverProductGrid(
      products: [
        for (final product in products)
          mallProductWithSaved(product, saved: saved.containsKey(product.id)),
      ],
      onProductTap: onProductTap,
      onSaveTap: (product) => unawaited(
        toggleSavedProduct(context, ref, productId: product.id),
      ),
    );
  }
}
