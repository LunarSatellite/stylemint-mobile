import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/notifiers/product_option_chooser.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/product_option_choosers.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/entities/reel.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/digital_goods/digital_goods_policy.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// What tapping a reel's product should do, decided from the product's
/// detail record (the tag carries no variant or stock).
sealed class ReelQuickBuyPlan {
  const ReelQuickBuyPlan();
}

/// One buyable variant, or none to choose between: add it straight away.
class ReelQuickBuyAdd extends ReelQuickBuyPlan {
  const ReelQuickBuyAdd(this.variantId);

  /// Null for a product the server prices without a variant id.
  final String? variantId;
}

/// Sizes or colours to pick first — the variant sheet.
class ReelQuickBuyChoose extends ReelQuickBuyPlan {
  const ReelQuickBuyChoose();
}

/// Nothing can be added; [message] says why.
class ReelQuickBuyUnavailable extends ReelQuickBuyPlan {
  const ReelQuickBuyUnavailable(this.message);

  final String message;
}

abstract final class ReelQuickBuyStrings {
  static const outOfStock = 'This item is out of stock.';
  static const notSoldHere = "This item can't be bought in the app.";
  static const loadFailed = "Couldn't open this product. Please try again.";
  static const addFailed = "Couldn't add that to your cart. Please try again.";
  static const sheetAction = 'Add to cart';
}

/// The legacy chip row's SKU group, when it offers a real choice.
ProductVariant? _skuChoice(ProductDetail product) {
  for (final group in product.variants) {
    if (group.type == 'sku' &&
        group.values.length > 1 &&
        group.optionVariantIds.isNotEmpty) {
      return group;
    }
  }
  return null;
}

/// Decides between adding at once, asking for a size/colour, and refusing.
///
/// A product with option rows asks whenever more than one variant exists —
/// the tag names no variant, so a buyer would otherwise get whichever the
/// server calls default. A single variant is added as it is.
ReelQuickBuyPlan planReelQuickBuy(
  ProductDetail product, {
  bool purchaseBlocked = false,
}) {
  if (purchaseBlocked) {
    return const ReelQuickBuyUnavailable(ReelQuickBuyStrings.notSoldHere);
  }
  if (product.options.isNotEmpty && product.optionVariants.isNotEmpty) {
    final buyable = product.optionVariants.where((v) => v.isBuyable).toList();
    if (buyable.isEmpty) {
      return const ReelQuickBuyUnavailable(ReelQuickBuyStrings.outOfStock);
    }
    if (product.optionVariants.length == 1) {
      return ReelQuickBuyAdd(buyable.single.variantId);
    }
    return const ReelQuickBuyChoose();
  }
  if (!product.isInStock) {
    return const ReelQuickBuyUnavailable(ReelQuickBuyStrings.outOfStock);
  }
  if (_skuChoice(product) != null) return const ReelQuickBuyChoose();
  return ReelQuickBuyAdd(product.defaultVariantId);
}

/// The reel rail's product tile: add the reel's [product] to the cart —
/// attributed to the reel tag, after a size/colour pick when it has them —
/// then open the cart. Guests sign in first; a product that cannot be added
/// says why and stays on the reel.
///
/// Returns whether the cart was opened.
Future<bool> reelQuickBuy(
  BuildContext context,
  WidgetRef ref,
  TaggedProductEntity product,
) async {
  if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) {
    return false;
  }
  if (!context.mounted) return false;

  final detail = await ref
      .read(discoveryRepositoryProvider)
      .getProductDetail(product.id);
  if (!context.mounted) return false;
  final loaded = detail.fold((_) => null, (p) => p);
  if (loaded == null) {
    SmSnackbar.error(context, ReelQuickBuyStrings.loadFailed);
    return false;
  }

  final plan = planReelQuickBuy(
    loaded,
    purchaseBlocked: DigitalGoodsPolicy.of(
      context,
    ).blocksPurchaseOf(loaded.productKind),
  );
  final String? variantId;
  switch (plan) {
    case ReelQuickBuyUnavailable(:final message):
      SmSnackbar.error(context, message);
      return false;
    case ReelQuickBuyAdd(variantId: final id):
      variantId = id;
    case ReelQuickBuyChoose():
      final picked = await showReelVariantSheet(context, loaded);
      if (picked == null || !context.mounted) return false;
      variantId = picked;
  }

  final notifier = ref.read(cartNotifierProvider.notifier);
  final added = await notifier.addItem(
    productId: product.id,
    quantity: 1,
    variantId: variantId,
    reelTagContextId: product.taggedProductId,
    idempotencyKey: _uuid.v4(),
  );
  if (!context.mounted) return false;
  if (!added) {
    final message = ref
        .read(cartNotifierProvider)
        .maybeWhen(
          loadFailure: _addFailureMessage,
          orElse: () => ReelQuickBuyStrings.addFailed,
        );
    SmSnackbar.error(context, message);
    return false;
  }
  await context.push(RouteNames.cart);
  return true;
}

/// The server's reason when it gave one ("Only 2 left in stock"), else the
/// generic message — "Resource not found." says nothing to a shopper.
String _addFailureMessage(NetworkExceptions failure) => failure.maybeWhen(
  server: (message) =>
      message.trim().isEmpty ? ReelQuickBuyStrings.addFailed : message.trim(),
  validation: (_, _, _, _) => NetworkExceptions.getMessage(failure),
  orElse: () => ReelQuickBuyStrings.addFailed,
);

/// The size/colour picker for [product], as a bottom sheet. Resolves to the
/// picked variant id, or null when dismissed.
///
/// The same choosers the product page uses ([ProductOptionChoosers]), so a
/// value that is sold out or not offered is greyed the same way; a product
/// on the legacy single SKU row gets that row as chips.
Future<String?> showReelVariantSheet(
  BuildContext context,
  ProductDetail product,
) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: DesignTokens.bgAppBody,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(DesignTokens.cardRadius),
    ),
  ),
  builder: (_) => ReelVariantSheet(product: product),
);

class ReelVariantSheet extends StatefulWidget {
  const ReelVariantSheet({required this.product, super.key});

  final ProductDetail product;

  static const Key addKey = Key('reel-variant-sheet-add');

  @override
  State<ReelVariantSheet> createState() => _ReelVariantSheetState();
}

class _ReelVariantSheetState extends State<ReelVariantSheet> {
  late final ProductOptionChooser _chooser = ProductOptionChooser.forProduct(
    widget.product,
  )..addListener(_changed);
  late final ProductVariant? _sku = _skuChoice(widget.product);
  late String? _skuValue = _sku?.values.first;

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chooser
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  bool get _usesOptions => !_chooser.value.isEmpty;

  /// The variant the current picks name, when it can be bought.
  String? get _variantId {
    if (_usesOptions) {
      final variant = _chooser.value.resolvedVariant;
      return variant != null && variant.isBuyable ? variant.variantId : null;
    }
    final sku = _sku;
    final value = _skuValue;
    if (sku == null || value == null) return widget.product.defaultVariantId;
    return sku.optionVariantIds[value];
  }

  @override
  Widget build(BuildContext context) {
    final product = _usesOptions
        ? _chooser.value.applyTo(widget.product)
        : widget.product;
    final variantId = _variantId;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: DesignTokens.borderDefault,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DesignTokens.titleMedium,
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            formatMoney(product.price, decimalDigits: 0),
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.primaryGreen,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          Flexible(
            child: SingleChildScrollView(
              child: _usesOptions
                  ? ProductOptionChoosers(chooser: _chooser)
                  : _SkuChips(
                      group: _sku,
                      selected: _skuValue,
                      onSelected: (value) => setState(() => _skuValue = value),
                    ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: ReelVariantSheet.addKey,
              style: FilledButton.styleFrom(
                backgroundColor: DesignTokens.primaryGreen,
                foregroundColor: DesignTokens.buttonPrimaryText,
              ),
              onPressed: variantId == null
                  ? null
                  : () => Navigator.of(context).pop(variantId),
              child: const Text(ReelQuickBuyStrings.sheetAction),
            ),
          ),
        ],
      ),
    );
  }
}

/// The legacy SKU row — one chip per SKU, the first preselected, as on the
/// product page.
class _SkuChips extends StatelessWidget {
  const _SkuChips({
    required this.group,
    required this.selected,
    required this.onSelected,
  });

  final ProductVariant? group;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final sku = group;
    if (sku == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select ${sku.name}',
          style: DesignTokens.smallRegular.copyWith(
            fontWeight: FontWeight.w600,
            color: DesignTokens.textLight,
          ),
        ),
        const SizedBox(height: DesignTokens.s8),
        Wrap(
          spacing: DesignTokens.s8,
          runSpacing: DesignTokens.s8,
          children: [
            for (final value in sku.values)
              ChoiceChip(
                label: Text(value),
                selected: value == selected,
                onSelected: (_) => onSelected(value),
              ),
          ],
        ),
      ],
    );
  }
}
