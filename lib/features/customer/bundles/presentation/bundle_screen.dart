import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/auth_gate/auth_gate.dart';
import 'package:stylemint_mobile_frontend/core/navigation/safe_back.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_pricing.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_format.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/cart/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/money.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:uuid/uuid.dart';

/// `/bundles/:bundleId` — one bundle: its items grouped by the shop that
/// ships them, a variant to pick per item, the list price beside the bundle
/// price, and "Add bundle to cart" (shop bundles contract §B6, §B8).
class BundleScreen extends ConsumerStatefulWidget {
  const BundleScreen({
    required this.bundleId,
    this.taggedBundleId,
    this.affiliateCode,
    super.key,
  });

  final String bundleId;

  /// The reel tag it was opened from, so the creator is credited.
  final String? taggedBundleId;
  final String? affiliateCode;

  static const Key addKey = Key('bundle-add-to-cart');
  static const Key unavailableKey = Key('bundle-unavailable');
  static const Key notFoundKey = Key('bundle-not-found');
  static const Key totalKey = Key('bundle-total');
  static const Key listTotalKey = Key('bundle-list-total');
  static Key variantKey(String itemId, String variantId) =>
      Key('bundle-variant-$itemId-$variantId');
  static Key shopKey(String vendorAccountId) =>
      Key('bundle-shop-$vendorAccountId');

  @override
  ConsumerState<BundleScreen> createState() => _BundleScreenState();
}

class _BundleScreenState extends ConsumerState<BundleScreen> {
  static const _uuid = Uuid();

  /// Bundle item id → chosen variant id.
  final Map<String, String> _chosen = <String, String>{};
  bool _adding = false;

  /// The picks for [bundle]: the buyer's where still valid, else each
  /// item's first variant that can cover its quantity.
  Map<String, String> _picksFor(BundleDetail bundle) {
    final picks = <String, String>{};
    for (final item in bundle.items) {
      final mine = _chosen[item.id];
      final valid = item.variants.any(
        (v) => v.id == mine && v.canCover(item.quantity),
      );
      final id = valid ? mine : item.initialVariant?.id;
      if (id != null) picks[item.id] = id;
    }
    return picks;
  }

  Future<void> _add(BundleDetail bundle, Map<String, String> picks) async {
    if (_adding) return;
    if (!await ensureAuth(context, ref, reason: AuthReason.addToCart)) return;
    if (!mounted) return;
    setState(() => _adding = true);
    final result = await ref
        .read(bundlesApiProvider)
        .addToCart(
          bundleId: bundle.id,
          termsVersion: bundle.termsVersion,
          variants: picks,
          taggedBundleId: widget.taggedBundleId,
          affiliateCode: widget.affiliateCode,
          idempotencyKey: _uuid.v4(),
        );
    if (!mounted) return;
    setState(() => _adding = false);
    final messenger = ScaffoldMessenger.of(context);
    result.fold(
      (failure) {
        // The bundle changed under the buyer: show the new terms.
        if (failure.isTermsChanged || failure.isNotFound) {
          ref.invalidate(bundleDetailProvider(widget.bundleId));
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              bundleFailureMessage(
                failure,
                fallback: "Couldn't add the bundle. Please try again.",
              ),
            ),
            backgroundColor: DesignTokens.colorError,
          ),
        );
      },
      (cart) {
        ref.read(cartNotifierProvider.notifier).showCart(cart);
        messenger.showSnackBar(
          SnackBar(
            content: Text('Added "${bundle.title}" to your bag'),
            action: SnackBarAction(
              label: 'View bag',
              onPressed: () => context.push(RouteNames.cart),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(bundleDetailProvider(widget.bundleId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: DesignTokens.textWhite,
          ),
          onPressed: () => context.popOrHome(),
        ),
        title: const Text('Bundle', style: DesignTokens.sectionInnerTitle),
        centerTitle: false,
      ),
      body: detail.when(
        loading: () => const SmPageLoader(),
        error: (error, _) {
          final failure = bundleFailureOf(error);
          // Not deployed yet, archived, or never Live: one plain page.
          if (failure == null || failure.isNotFound) {
            return const _NotAvailable();
          }
          return SmErrorView(
            message: bundleFailureMessage(failure),
            onRetry: () =>
                ref.invalidate(bundleDetailProvider(widget.bundleId)),
          );
        },
        data: (bundle) {
          final picks = _picksFor(bundle);
          final quote = quoteBundle(bundle, picks);
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(bundleDetailProvider(widget.bundleId).future),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s24),
                    children: [
                      _Header(bundle: bundle),
                      for (final shop in bundle.shops)
                        _ShopSection(
                          key: BundleScreen.shopKey(shop.vendorAccountId),
                          shop: shop,
                          splitShipping: bundle.shopCount > 1,
                          discountPercent: bundle.discountPercent,
                          picks: picks,
                          enabled: bundle.isPurchasable,
                          onPick: (itemId, variantId) =>
                              setState(() => _chosen[itemId] = variantId),
                        ),
                    ],
                  ),
                ),
              ),
              _AddBar(
                bundle: bundle,
                quote: quote,
                busy: _adding,
                onAdd: bundle.isPurchasable && quote.complete
                    ? () => unawaited(_add(bundle, picks))
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotAvailable extends StatelessWidget {
  const _NotAvailable();

  @override
  Widget build(BuildContext context) => Center(
    key: BundleScreen.notFoundKey,
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.s24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 40,
            color: DesignTokens.textMuted,
          ),
          const SizedBox(height: DesignTokens.s12),
          const Text(
            "This bundle isn't available",
            style: DesignTokens.mediumSemibold,
          ),
          const SizedBox(height: DesignTokens.s4),
          Text(
            'It may have ended. The items may still be sold on their own.',
            textAlign: TextAlign.center,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.bundle});

  final BundleDetail bundle;

  @override
  Widget build(BuildContext context) {
    final discount = bundleDiscountLabel(bundle.discountPercent);
    final cover =
        bundle.coverImageUrl ??
        (bundle.items.isEmpty ? null : bundle.items.first.thumbnailUrl);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (cover != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: MallNetworkImage(url: cover),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.s16,
            DesignTokens.s16,
            DesignTokens.s16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(bundle.title, style: DesignTokens.titleMedium),
                  ),
                  if (discount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.s8,
                        vertical: DesignTokens.s4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.primaryGreen,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.chipRadius,
                        ),
                      ),
                      child: Text(
                        discount,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.baseBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (bundle.curator case final curator?) ...[
                const SizedBox(height: DesignTokens.s4),
                Text(
                  curator.byline,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.s4),
              Text(
                bundleCountsLabel(
                  items: bundle.items.length,
                  shops: bundle.shopCount,
                ),
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
              if (bundle.description case final text?) ...[
                const SizedBox(height: DesignTokens.s12),
                Text(text, style: DesignTokens.bodyText),
              ],
              if (!bundle.isPurchasable) ...[
                const SizedBox(height: DesignTokens.s12),
                Container(
                  key: BundleScreen.unavailableKey,
                  width: double.infinity,
                  padding: const EdgeInsets.all(DesignTokens.s12),
                  decoration: BoxDecoration(
                    color: DesignTokens.warningFillDark,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMedium,
                    ),
                  ),
                  child: Text(
                    (bundle.unavailableReason ??
                            BundleUnavailableReason.other)
                        .sentence,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.warningTextLight,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopSection extends StatelessWidget {
  const _ShopSection({
    required this.shop,
    required this.splitShipping,
    required this.discountPercent,
    required this.picks,
    required this.enabled,
    required this.onPick,
    super.key,
  });

  final BundleShopGroup shop;
  final bool splitShipping;
  final double discountPercent;
  final Map<String, String> picks;
  final bool enabled;
  final void Function(String itemId, String variantId) onPick;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      DesignTokens.s16,
      DesignTokens.s20,
      DesignTokens.s16,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 18,
              color: DesignTokens.textLight,
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Text(shop.shopName, style: DesignTokens.mediumSemibold),
            ),
            if (splitShipping)
              Text(
                'Ships separately',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.s8),
        for (final item in shop.items)
          _ItemCard(
            item: item,
            discountPercent: discountPercent,
            pick: picks[item.id],
            enabled: enabled,
            onPick: (variantId) => onPick(item.id, variantId),
          ),
      ],
    ),
  );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.discountPercent,
    required this.pick,
    required this.enabled,
    required this.onPick,
  });

  final BundleItem item;
  final double discountPercent;
  final String? pick;
  final bool enabled;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    BundleVariant? chosen;
    for (final v in item.variants) {
      if (v.id == pick) chosen = v;
    }
    final list = chosen?.price ?? item.listUnitPrice;
    final unit = chosen == null
        ? item.bundleUnitPrice
        : Money(
            amount: bundleUnitPrice(list.amount, discountPercent),
            currency: list.currency,
          );
    final soldOut = chosen == null;
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.s8),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                child: SizedBox(
                  width: DesignTokens.thumbSmall,
                  height: DesignTokens.thumbSmall,
                  child: MallNetworkImage(url: item.thumbnailUrl),
                ),
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.quantity > 1
                          ? '${item.quantity} × ${item.title}'
                          : item.title,
                      style: DesignTokens.mediumRegular,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.note case final note?)
                      Text(
                        note,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    const SizedBox(height: DesignTokens.s4),
                    Wrap(
                      spacing: DesignTokens.s8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          bundleMoney(unit),
                          style: DesignTokens.mediumSemibold,
                        ),
                        if (list.amount > unit.amount)
                          Text(
                            bundleMoney(list),
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        if (item.quantity > 1)
                          Text(
                            'each',
                            style: DesignTokens.smallRegular.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                      ],
                    ),
                    if (soldOut || !item.available)
                      Text(
                        'Out of stock',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.colorError,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (item.needsChoice) ...[
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s8,
              runSpacing: DesignTokens.s8,
              children: [
                for (final v in item.variants)
                  ChoiceChip(
                    key: BundleScreen.variantKey(item.id, v.id),
                    label: Text(v.label),
                    selected: v.id == pick,
                    onSelected: enabled && v.canCover(item.quantity)
                        ? (_) => onPick(v.id)
                        : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AddBar extends StatelessWidget {
  const _AddBar({
    required this.bundle,
    required this.quote,
    required this.busy,
    required this.onAdd,
  });

  final BundleDetail bundle;
  final BundleQuote quote;
  final bool busy;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final saving = quote.saving;
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s12,
        DesignTokens.s16,
        DesignTokens.s12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: DesignTokens.bgAppBody,
        border: Border(top: BorderSide(color: DesignTokens.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bundleMoney(quote.bundleTotal),
                  key: BundleScreen.totalKey,
                  style: DesignTokens.moneyMedium,
                ),
                if (saving.amount > 0)
                  Wrap(
                    spacing: DesignTokens.s8,
                    children: [
                      Text(
                        bundleMoney(quote.listTotal),
                        key: BundleScreen.listTotalKey,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'Save ${bundleMoney(saving)}',
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          FilledButton(
            key: BundleScreen.addKey,
            onPressed: busy ? null : onAdd,
            child: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    bundle.isPurchasable
                        ? 'Add bundle to cart'
                        : 'Not available',
                  ),
          ),
        ],
      ),
    );
  }
}
