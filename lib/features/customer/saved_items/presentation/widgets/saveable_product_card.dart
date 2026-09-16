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
///
/// Delegates to the view model so a field added to [MallProductVm] cannot go
/// missing here — rebuilding it field by field silently dropped anything new.
MallProductVm mallProductWithSaved(
  MallProductVm product, {
  required bool saved,
}) => product.withSaved(saved: saved);

/// A [MallProductCard] whose heart reads and toggles the shared saved list.
class SaveableMallProductCard extends ConsumerWidget {
  const SaveableMallProductCard({
    required this.product,
    super.key,
    this.size = MallCardSize.regular,
    this.onTap,
    this.variantId,
    this.showRating = true,
    this.signal,
    this.reserveSignal = false,
  });

  final MallProductVm product;
  final MallCardSize size;
  final VoidCallback? onTap;

  /// The SKU to save; the product's default variant when null.
  final String? variantId;
  final bool showRating;

  /// One live fact under the price. See [MallProductCard.signal].
  final MallSignal? signal;

  /// Keeps the signal slot so every card in a rail is the same height.
  final bool reserveSignal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow by design: only this card rebuilds when its own saved state
    // flips, never the rail and never the page.
    final saved = ref.watch(
      savedProductsNotifierProvider.select((s) => s.isSaved(product.id)),
    );
    return MallProductCard(
      product: mallProductWithSaved(product, saved: saved),
      size: size,
      onTap: onTap,
      showRating: showRating,
      signal: signal,
      reserveSignal: reserveSignal,
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

/// A [MallProductTile] whose heart reads and toggles the shared saved list.
///
/// The Mall's tile: a reel where the product has one, the designed type tile
/// where it does not, never a product photo. [SaveableMallProductCard] stays
/// for the product details page, which keeps its photos.
class SaveableMallProductTile extends ConsumerWidget {
  const SaveableMallProductTile({
    required this.product,
    super.key,
    this.size = MallCardSize.regular,
    this.onTap,
    this.onReelTap,
    this.variantId,
    this.showRating = true,
    this.signal,
    this.reserveSignal = false,
  });

  final MallProductVm product;
  final MallCardSize size;

  /// Opens the product.
  final VoidCallback? onTap;

  /// Opens the reel on a tile that has one. Falls back to [onTap].
  final void Function(MallReelRef reel)? onReelTap;

  /// The SKU to save; the product's default variant when null.
  final String? variantId;
  final bool showRating;

  /// One live fact under the price. See [MallProductTile.signal].
  final MallSignal? signal;

  /// Keeps the signal slot so every tile in a rail is the same height.
  final bool reserveSignal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Narrow by design: only this tile rebuilds when its own saved state
    // flips, never the rail and never the page.
    final saved = ref.watch(
      savedProductsNotifierProvider.select((s) => s.isSaved(product.id)),
    );
    return MallProductTile(
      product: mallProductWithSaved(product, saved: saved),
      size: size,
      onTap: onTap,
      onReelTap: onReelTap,
      showRating: showRating,
      signal: signal,
      reserveSignal: reserveSignal,
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
    this.onReelTap,
  });

  final List<MallProductVm> products;
  final ValueChanged<MallProductVm>? onProductTap;

  /// Opens the reel on a tile that has one. Falls back to [onProductTap].
  final void Function(MallProductVm product, MallReelRef reel)? onReelTap;

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
      onReelTap: onReelTap,
      onSaveTap: (product) => unawaited(
        toggleSavedProduct(context, ref, productId: product.id),
      ),
    );
  }
}
