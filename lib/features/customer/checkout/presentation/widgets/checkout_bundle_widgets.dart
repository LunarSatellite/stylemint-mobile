import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_format.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/domain/entities/cart.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/presentation/notifiers/cart_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/checkout/domain/entities/checkout.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The 422 checkout start and place answer when a bundle in the cart is no
/// longer Live, its terms changed, or it lost an item (contract §B8).
bool isBundleUnavailable(NetworkExceptions failure) =>
    failure.validationCode == 'bundle_unavailable';

/// How the order splits: one parcel per shop. Shown when the order has a
/// bundle or more than one shop; nothing for a one-shop order.
class CheckoutParcelsCard extends StatelessWidget {
  const CheckoutParcelsCard({required this.items, super.key});

  static const Key cardKey = Key('checkout-parcels');

  final List<CheckoutItem> items;

  @override
  Widget build(BuildContext context) {
    final parcels = checkoutParcels(items);
    final bundleTitles = <String>{
      for (final i in items)
        if (i.isBundleLine) i.bundleTitle ?? 'Bundle',
    };
    if (parcels.length < 2 && bundleTitles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      key: cardKey,
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.s12),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(color: DesignTokens.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: DesignTokens.textLight,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Text(
                    parcels.length >= 2
                        ? 'Arrives in ${parcels.length} parcels'
                        : 'How your bundle arrives',
                    style: DesignTokens.mediumSemibold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              parcels.length >= 2
                  ? 'Each shop packs and sends its own items, so they may '
                        'arrive on different days.'
                  : 'Items from different shops in a bundle are packed and '
                        'sent by each shop, so they may arrive separately.',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            for (final (index, parcel) in parcels.indexed) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                'Parcel ${index + 1}'
                '${parcel.shopName == null ? '' : ' · ${parcel.shopName}'}',
                style: DesignTokens.smallRegular.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final item in parcel.items)
                Text(
                  '${item.quantity} × ${item.productName}'
                  '${item.isBundleLine ? ' (${item.bundleTitle ?? 'bundle'})' : ''}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Said beside Pay with EMI when the cart has bundle lines: they are never
/// on an instalment plan (contract §B7, phase 1).
class CheckoutBundleEmiNote extends StatelessWidget {
  const CheckoutBundleEmiNote({super.key});

  static const Key noteKey = Key('checkout-bundle-no-emi');

  @override
  Widget build(BuildContext context) => Padding(
    key: noteKey,
    padding: const EdgeInsets.only(bottom: DesignTokens.s8),
    child: Text(
      'Bundle items cannot be paid in instalments (EMI).',
      style: DesignTokens.smallRegular.copyWith(color: DesignTokens.textMuted),
    ),
  );
}

/// What checkout shows when a bundle in the cart cannot be bought now: each
/// bundle with "Remove bundle" and "Buy items separately" (unbundle), then
/// [onResolved] restarts checkout.
class CheckoutBundleUnavailable extends ConsumerStatefulWidget {
  const CheckoutBundleUnavailable({
    required this.onResolved,
    required this.onBackToCart,
    super.key,
  });

  static const Key viewKey = Key('checkout-bundle-unavailable');
  static Key removeKey(String groupId) => Key('checkout-bundle-remove-$groupId');
  static Key unbundleKey(String groupId) =>
      Key('checkout-bundle-unbundle-$groupId');

  final VoidCallback onResolved;
  final VoidCallback onBackToCart;

  @override
  ConsumerState<CheckoutBundleUnavailable> createState() =>
      _CheckoutBundleUnavailableState();
}

class _CheckoutBundleUnavailableState
    extends ConsumerState<CheckoutBundleUnavailable> {
  String? _busy;

  @override
  void initState() {
    super.initState();
    // The cart as it is now: which bundle is the unavailable one.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(cartNotifierProvider.notifier).fetchCart();
    });
  }

  Future<void> _act(
    String groupId,
    Future<NetworkExceptions?> Function(CartNotifier n) action,
  ) async {
    setState(() => _busy = groupId);
    final failure = await action(ref.read(cartNotifierProvider.notifier));
    if (!mounted) return;
    setState(() => _busy = null);
    if (failure == null) {
      widget.onResolved();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(NetworkExceptions.getMessage(failure)),
        backgroundColor: DesignTokens.colorError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(settledCartProvider);
    final groups = cart?.bundleGroups ?? const <CartBundleGroup>[];
    // The ones the cart already marks unavailable; all of them when it does
    // not say (the server's check is the stricter one).
    final flagged = [
      for (final g in groups)
        if (!g.isPurchasable) g,
    ];
    final shown = flagged.isEmpty ? groups : flagged;
    return ListView(
      key: CheckoutBundleUnavailable.viewKey,
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          size: 40,
          color: DesignTokens.colorWarning,
        ),
        const SizedBox(height: DesignTokens.s12),
        const Text(
          'A bundle in your cart is not available',
          style: DesignTokens.sectionInnerTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.s8),
        Text(
          'It was paused, changed, or one of its items sold out. Remove the '
          'bundle, or keep the items and buy them separately at their full '
          'price.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: DesignTokens.s16),
        for (final g in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.s12),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.s12),
              decoration: BoxDecoration(
                color: DesignTokens.bgAppBody,
                borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
                border: Border.all(color: DesignTokens.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(g.title, style: DesignTokens.mediumSemibold),
                  if (!g.isPurchasable)
                    Text(
                      bundleUnavailableSentence(g.unavailableReason),
                      style: DesignTokens.smallRegular.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  const SizedBox(height: DesignTokens.s8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: CheckoutBundleUnavailable.removeKey(g.groupId),
                          onPressed: _busy != null
                              ? null
                              : () => _act(
                                  g.groupId,
                                  (n) => n.removeBundle(g.groupId),
                                ),
                          child: const Text('Remove bundle'),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.s8),
                      Expanded(
                        child: FilledButton(
                          key: CheckoutBundleUnavailable.unbundleKey(
                            g.groupId,
                          ),
                          onPressed: _busy != null
                              ? null
                              : () => _act(
                                  g.groupId,
                                  (n) => n.unbundle(g.groupId),
                                ),
                          child: const Text('Buy separately'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        TextButton(
          onPressed: widget.onBackToCart,
          child: const Text('Back to cart'),
        ),
      ],
    );
  }
}

/// The same choice as a sheet, when Place order is refused.
Future<void> showCheckoutBundleUnavailableSheet(
  BuildContext context, {
  required VoidCallback onResolved,
  required VoidCallback onBackToCart,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  backgroundColor: DesignTokens.bgAppFoundation,
  builder: (sheetContext) => SizedBox(
    height: MediaQuery.sizeOf(sheetContext).height * 0.6,
    child: CheckoutBundleUnavailable(
      onResolved: () {
        Navigator.of(sheetContext).pop();
        onResolved();
      },
      onBackToCart: () {
        Navigator.of(sheetContext).pop();
        onBackToCart();
      },
    ),
  ),
);
