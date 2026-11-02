import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_format.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/domain/vendor_bundle.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/shared/vendor_bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/shared/vendor_bundle_routes.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Bundles: sets of products from several shops sold together at a
/// discount. Lists the invites waiting for this shop, the live bundles it
/// is in and the rest. Bundles are made in Seller Center; here the shop
/// answers.
class VendorBundlesScreen extends ConsumerWidget {
  const VendorBundlesScreen({super.key});

  static Key tileKey(String id) => Key('vendor-bundle-tile-$id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundles = ref.watch(vendorBundlesProvider);
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Bundles'),
      ),
      body: SafeArea(
        child: bundles.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              VendorBundleLoadFailure(
                error: error,
                onRetry: () => ref.invalidate(vendorBundlesProvider),
              ),
            ],
          ),
          data: (all) => RefreshIndicator(
            onRefresh: () => ref.refresh(vendorBundlesProvider.future),
            child: _BundleList(bundles: all),
          ),
        ),
      ),
    );
  }
}

/// "Being set up" for a bare 404, else a retryable error.
class VendorBundleLoadFailure extends StatelessWidget {
  const VendorBundleLoadFailure({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (bundlesNotDeployed(error)) {
      return const ServiceSettingUpView(title: 'Bundles are being set up');
    }
    final failure = bundleFailureOf(error);
    return SmErrorView(
      message: failure == null
          ? 'We could not load your bundles.'
          : bundleFailureMessage(failure),
      onRetry: onRetry,
    );
  }
}

class _BundleList extends ConsumerWidget {
  const _BundleList({required this.bundles});

  final List<VendorBundle> bundles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = [
      for (final b in bundles)
        if (b.isWaitingForMe) b,
    ];
    final live = [
      for (final b in bundles)
        if (!b.isWaitingForMe && b.state == VendorBundleState.live) b,
    ];
    final rest = [
      for (final b in bundles)
        if (!b.isWaitingForMe && b.state != VendorBundleState.live) b,
    ];

    Future<void> open(VendorBundle bundle) async {
      await context.push(VendorBundleRoutes.detailPath(bundle.id));
      ref.invalidate(vendorBundlesProvider);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.s16,
        DesignTokens.s8,
        DesignTokens.s16,
        DesignTokens.s32,
      ),
      children: [
        Text(
          'Sell your products together with other shops at a bundle price. '
          'Each shop ships its own items. Bundles are made in Seller Center; '
          'answer invites here.',
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        if (bundles.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s32),
            child: Column(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 40,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(height: DesignTokens.s12),
                const Text('No bundles yet', style: DesignTokens.mediumSemibold),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'When a creator, StyleMint or another shop puts your '
                  'products in a bundle, it shows here for you to accept.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        if (waiting.isNotEmpty) ...[
          const ServiceSectionTitle('Waiting for you'),
          for (final b in waiting) _BundleTile(bundle: b, onTap: () => open(b)),
        ],
        if (live.isNotEmpty) ...[
          const ServiceSectionTitle('Live'),
          for (final b in live) _BundleTile(bundle: b, onTap: () => open(b)),
        ],
        if (rest.isNotEmpty) ...[
          const ServiceSectionTitle('Other bundles'),
          for (final b in rest) _BundleTile(bundle: b, onTap: () => open(b)),
        ],
      ],
    );
  }
}

class _BundleTile extends StatelessWidget {
  const _BundleTile({required this.bundle, required this.onTap});

  final VendorBundle bundle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final discount = bundleDiscountLabel(bundle.discountPercent);
    final subtitle = [
      'by ${bundle.ownerName ?? bundle.ownerKind.label}',
      ?discount,
      if (bundle.myItems.isNotEmpty && bundle.myFunds.amount > 0)
        'you fund ${bundleMoney(bundle.myFunds)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Material(
        color: DesignTokens.bgAppBody,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          side: const BorderSide(color: DesignTokens.borderDefault),
        ),
        child: InkWell(
          key: VendorBundlesScreen.tileKey(bundle.id),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s12),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: DesignTokens.textLight,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bundle.title,
                        style: DesignTokens.mediumSemibold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: DesignTokens.smallRegular.copyWith(
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.s8),
                VendorBundleStatusPill(bundle: bundle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// This shop's answer, or the bundle's state once answered.
class VendorBundleStatusPill extends StatelessWidget {
  const VendorBundleStatusPill({required this.bundle, super.key});

  final VendorBundle bundle;

  @override
  Widget build(BuildContext context) {
    if (bundle.isEnded) {
      return const ServicePill('Ended', tone: ServicePillTone.neutral);
    }
    if (bundle.needsItems) {
      return const ServicePill('Invited', tone: ServicePillTone.info);
    }
    if (bundle.canAnswer) {
      return const ServicePill('Answer needed', tone: ServicePillTone.warning);
    }
    return switch (bundle.myShopState) {
      VendorBundleShopState.declined => const ServicePill(
        'Declined',
        tone: ServicePillTone.error,
      ),
      VendorBundleShopState.withdrawn => const ServicePill(
        'Withdrew',
        tone: ServicePillTone.error,
      ),
      VendorBundleShopState.removed => const ServicePill(
        'Removed',
        tone: ServicePillTone.neutral,
      ),
      _ => switch (bundle.state) {
        VendorBundleState.live => const ServicePill(
          'Live',
          tone: ServicePillTone.success,
        ),
        VendorBundleState.paused => const ServicePill(
          'Paused',
          tone: ServicePillTone.warning,
        ),
        _ => ServicePill(bundle.state.label, tone: ServicePillTone.info),
      },
    };
  }
}
