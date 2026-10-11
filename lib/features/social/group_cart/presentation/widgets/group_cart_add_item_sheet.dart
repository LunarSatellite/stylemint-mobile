import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_type_tile.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Picks a line out of the shopper's own cart and puts it in the group cart.
///
/// The group cart detail screen has always said "No items yet. Add something!"
/// with nothing behind it — `GroupCartNotifier.addItem` existed and reached
/// `POST /v1/cart-shares/{id}/items`, but no screen called it. This is the
/// entry point.
///
/// Sourcing from the shopper's own cart rather than opening a product browser
/// keeps this to the one decision a group cart actually needs — *which of the
/// things I already picked are we buying together* — and reuses state the app
/// has already loaded.
class GroupCartAddItemSheet extends ConsumerStatefulWidget {
  const GroupCartAddItemSheet({required this.cartId, super.key});

  final String cartId;

  @override
  ConsumerState<GroupCartAddItemSheet> createState() =>
      _GroupCartAddItemSheetState();
}

class _GroupCartAddItemSheetState extends ConsumerState<GroupCartAddItemSheet> {
  String? _addingProductId;
  String? _error;

  @override
  void initState() {
    super.initState();
    // The provider is an app-lifetime singleton that fetches once in its
    // constructor, so re-fetch here rather than show whatever it last held.
    unawaited(
      Future<void>.microtask(
        () => ref.read(cartNotifierProvider.notifier).fetchCart(),
      ),
    );
  }

  Future<void> _add(CartItem item) async {
    setState(() {
      _addingProductId = item.productId;
      _error = null;
    });
    // AddCartShareItemVmValidator rejects anything outside 1–99 with a 400
    // rather than clamping, so the clamp happens here.
    final quantity = item.quantity.clamp(1, 99);
    final result = await ref
        .read(groupCartDetailNotifierProvider(widget.cartId).notifier)
        .addItem(widget.cartId, item.productId, quantity);
    if (!mounted) return;
    result.fold(
      (_) => setState(() {
        _addingProductId = null;
        _error = 'Could not add this item.';
      }),
      (_) => Navigator.of(context).pop<String>(item.productName),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartNotifierProvider);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(DesignTokens.s16),
              child: Text(
                'Add from your cart',
                style: DesignTokens.sectionInnerTitle,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                ),
                child: Text(
                  _error!,
                  key: const Key('group-cart-add-item-error'),
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
            const Divider(color: DesignTokens.borderDefault),
            Expanded(
              child: cartState.maybeWhen(
                loadSuccess: _buildList,
                loadFailure: (_) => const Center(
                  child: Text(
                    'Could not load your cart.',
                    style: DesignTokens.mediumRegular,
                  ),
                ),
                orElse: _loader,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Cart cart) {
    if (cart.items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(DesignTokens.s24),
          child: Text(
            'Your cart is empty. Add something to it first, then bring it '
            'into the group cart.',
            textAlign: TextAlign.center,
            style: DesignTokens.mediumRegular,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.s16),
      itemCount: cart.items.length,
      separatorBuilder: (_, _) =>
          const Divider(color: DesignTokens.borderDefault),
      itemBuilder: (_, index) {
        final item = cart.items[index];
        final adding = _addingProductId == item.productId;
        // Out of stock is still worth showing — seeing it greyed out explains
        // why it cannot come along, where hiding it just looks like a bug.
        final enabled = _addingProductId == null && item.isInStock;
        return ListTile(
          enabled: enabled,
          // A generated ground, not the product photograph:
          // `product_photo_guard_test` keeps real product imagery to product
          // detail and the mall tiles, and seeded grounds stay legible when the
          // media behind a line is missing.
          leading: SizedBox(
            width: 40,
            height: 40,
            child: MallTypeGround(
              seed: item.productId,
              monogram: item.productName.trim().isEmpty
                  ? null
                  : item.productName.trim()[0].toUpperCase(),
            ),
          ),
          title: Text(item.productName),
          subtitle: Text(
            item.isInStock
                ? '${item.variantName} · ${formatMoney(item.unitPrice)}'
                : 'Out of stock',
          ),
          trailing: adding
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_shopping_cart_outlined),
          onTap: enabled ? () => _add(item) : null,
        );
      },
    );
  }

  Widget _loader() => const SmPageLoader();
}
