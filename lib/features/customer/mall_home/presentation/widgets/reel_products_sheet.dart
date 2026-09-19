import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/domain/entities/mall_home.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/mall_navigation.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/presentation/notifiers/reel_products_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/widgets/tagged_products_section.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/money_text.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Opens the quick product sheet for [reel]: its tagged products with add to
/// cart, without leaving Home.
Future<void> showReelProductsSheet(
  BuildContext context, {
  required HomeReel reel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: DesignTokens.surfaceRaised,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(DesignTokens.radiusLarge),
      ),
    ),
    builder: (_) => ReelProductsSheet(reel: reel),
  );
}

/// A reel's tagged products, loaded from the reel detail so each add to cart
/// carries the reel tag for commission attribution (the same add-to-cart as
/// the reels feed's [TaggedProductsSection]).
class ReelProductsSheet extends ConsumerWidget {
  const ReelProductsSheet({required this.reel, super.key});

  final HomeReel reel;

  /// Closes the sheet, then opens [location].
  static void _leaveTo(BuildContext context, String location) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    unawaited(router.push(location));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = reelProductsNotifierProvider(reel.id);
    final state = ref.watch(provider);
    final skeleton = _RowsSkeleton(
      count: reel.taggedProductCount.clamp(1, 3),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(reel: reel),
          Flexible(
            child: state.when(
              initial: () => skeleton,
              loadInProgress: () => skeleton,
              loadFailure: (failure) => SmErrorView(
                message: failure.isNoInternet
                    ? 'No internet connection.'
                    : "Couldn't load this reel's products.",
                onRetry: () => unawaited(ref.read(provider.notifier).load()),
              ),
              loadSuccess: (detail) {
                final products = detail.taggedProducts
                    .where((p) => p.id.isNotEmpty)
                    .toList(growable: false);
                if (products.isEmpty) {
                  return const MallEmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Nothing to shop here',
                    body: 'This reel has no tagged products right now.',
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
                  itemCount: products.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: DesignTokens.s12),
                  itemBuilder: (context, index) => ReelProductRow(
                    product: products[index],
                    onOpen: () => _leaveTo(
                      context,
                      MallRoutes.product(products[index].id),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
              child: TextButton.icon(
                onPressed: () => _leaveTo(context, MallRoutes.reel(reel.id)),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.textWhite,
                  minimumSize: const Size(DesignTokens.minTouchTarget, 48),
                  textStyle: const TextStyle(
                    fontFamily: DesignTokens.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                label: const Text('Watch the reel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.reel});

  final HomeReel reel;

  static const TextStyle _creatorStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: DesignTokens.textLight,
  );

  @override
  Widget build(BuildContext context) {
    final strings = MallStrings.of(context);
    final creator = reel.creatorName.isEmpty
        ? 'StyleMint creator'
        : reel.creatorName;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 8, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const MallEyebrow('Shop the reel'),
                const SizedBox(height: DesignTokens.s6),
                Semantics(
                  header: true,
                  child: Text(
                    reel.hook ?? 'From this reel',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.displaySection,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: DesignTokens.s8,
                  runSpacing: DesignTokens.s6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MallAvatar(
                          name: creator,
                          imageUrl: reel.creatorAvatarUrl,
                          size: 22,
                        ),
                        const SizedBox(width: DesignTokens.s6),
                        Flexible(
                          child: Text(
                            creator,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _creatorStyle,
                          ),
                        ),
                      ],
                    ),
                    // Disclosure: always shown for AI reels, never truncated.
                    if (reel.isAiGenerated)
                      MallBadge(
                        label: strings.aiGenerated,
                        icon: Icons.auto_awesome_rounded,
                        maxLines: null,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            constraints: const BoxConstraints.tightFor(
              width: DesignTokens.minTouchTarget,
              height: DesignTokens.minTouchTarget,
            ),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.close_rounded,
              color: DesignTokens.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tagged product: name and price (opens the product) and add to cart,
/// which becomes a quantity stepper once the product is in the cart.
///
/// The leading block used to be the product's photograph. This sheet sits
/// over a reel, which is as far from product detail as a surface gets, so it
/// is the tile's own `MallTypeGround` now — same seed, same face as the
/// tile that tagged it.
class ReelProductRow extends ConsumerWidget {
  const ReelProductRow({
    required this.product,
    required this.onOpen,
    super.key,
  });

  final TaggedProductEntity product;
  final VoidCallback onOpen;

  static const TextStyle _nameStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  static const TextStyle _priceStyle = TextStyle(
    fontFamily: DesignTokens.fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: DesignTokens.textWhite,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItem = watchCartItemForProduct(ref, product.id);
    final radius = BorderRadius.circular(DesignTokens.radiusMedium);
    return Row(
      children: [
        Expanded(
          child: MergeSemantics(
            child: Semantics(
              button: true,
              child: InkWell(
                onTap: onOpen,
                borderRadius: radius,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: radius,
                      child: SizedBox(
                        width: 64,
                        height: 80,
                        child: MallTypeGround(
                          seed: product.id,
                          monogram: product.name.trim().isEmpty
                              ? null
                              : product.name.trim()[0].toUpperCase(),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _nameStyle,
                          ),
                          const SizedBox(height: DesignTokens.s4),
                          MoneyText(
                            product.price,
                            decimalDigits: MallMetrics.priceDigits(
                              product.price,
                            ),
                            maxLines: 1,
                            style: _priceStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: DesignTokens.s8),
        if (cartItem == null)
          MallPrimaryCta(
            label: 'Add',
            onPressed: () =>
                unawaited(addTaggedProductToCart(context, ref, product)),
          )
        else
          _QuantityStepper(
            quantity: cartItem.quantity,
            onChanged: (delta) => changeCartItemQuantity(ref, cartItem, delta),
          ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  static const BoxConstraints _target = BoxConstraints.tightFor(
    width: DesignTokens.minTouchTarget,
    height: DesignTokens.minTouchTarget,
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBodyLight,
        borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: quantity <= 1 ? 'Remove from cart' : 'Remove one',
            onPressed: () => onChanged(-1),
            constraints: _target,
            padding: EdgeInsets.zero,
            icon: Icon(
              quantity <= 1
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              size: 18,
              color: DesignTokens.textWhite,
            ),
          ),
          Semantics(
            liveRegion: true,
            label: '$quantity in cart',
            excludeSemantics: true,
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: DesignTokens.textWhite,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Add one more',
            onPressed: () => onChanged(1),
            constraints: _target,
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
              color: DesignTokens.textWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++)
            const Padding(
              padding: EdgeInsetsDirectional.only(bottom: DesignTokens.s12),
              child: Row(
                children: [
                  SmSkeleton.box(width: 64, height: 80),
                  SizedBox(width: DesignTokens.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SmSkeleton.line(width: 160, height: 14),
                        SizedBox(height: DesignTokens.s8),
                        SmSkeleton.line(width: 80, height: 14),
                      ],
                    ),
                  ),
                  SizedBox(width: DesignTokens.s8),
                  SmSkeleton.box(width: 76, height: 44, radius: 22),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
