import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/presentation/widgets/saveable_product_card.dart';
import 'package:stylemint_mobile_frontend/features/customer/saved_items/shared/saved_products_providers.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The product page's save heart, sharing saved state with every Mall card.
class ProductSaveButton extends ConsumerWidget {
  const ProductSaveButton({required this.productId, super.key, this.variantId});

  final String productId;

  /// The SKU to save; the product's default variant when null.
  final String? variantId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      savedProductsNotifierProvider.select((s) => s.isSaved(productId)),
    );
    return IconButton(
      tooltip: saved ? 'Remove from saved' : 'Save for later',
      icon: Icon(
        saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: saved ? DesignTokens.colorError : DesignTokens.textWhite,
      ),
      onPressed: () => unawaited(
        toggleSavedProduct(
          context,
          ref,
          productId: productId,
          variantId: variantId,
        ),
      ),
    );
  }
}
