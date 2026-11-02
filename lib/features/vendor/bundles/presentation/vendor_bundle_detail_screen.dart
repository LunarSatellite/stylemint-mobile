import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_format.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/domain/vendor_bundle.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/presentation/vendor_bundles_screen.dart';
import 'package:stylemint_mobile_frontend/features/vendor/bundles/shared/vendor_bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/vendor/services/shared/service_widgets.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_snackbar.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// One bundle, as this shop sees it: what the bundle sells, what this shop
/// gives up (the discount on its own items), every shop's answer, and
/// accept / decline / withdraw.
class VendorBundleDetailScreen extends ConsumerStatefulWidget {
  const VendorBundleDetailScreen({required this.bundleId, super.key});

  final String bundleId;

  static const Key acceptKey = Key('vendor-bundle-accept');
  static const Key declineKey = Key('vendor-bundle-decline');
  static const Key withdrawKey = Key('vendor-bundle-withdraw');
  static const Key fundsKey = Key('vendor-bundle-funds');

  @override
  ConsumerState<VendorBundleDetailScreen> createState() =>
      _VendorBundleDetailScreenState();
}

class _VendorBundleDetailScreenState
    extends ConsumerState<VendorBundleDetailScreen> {
  String? _busy;

  Future<void> _run(
    String action,
    Future<Either<BundleFailure, VendorBundle>> Function() call, {
    required String done,
  }) async {
    if (_busy != null) return;
    setState(() => _busy = action);
    final result = await call();
    if (!mounted) return;
    setState(() => _busy = null);
    result.fold(
      (failure) {
        // New terms since this screen loaded: show them before any answer.
        if (failure.isTermsChanged) {
          ref.invalidate(vendorBundleProvider(widget.bundleId));
        }
        SmSnackbar.error(
          context,
          failure.isTermsChanged
              ? 'The bundle changed while you were looking. Check the new '
                    'terms and answer again.'
              : bundleFailureMessage(failure),
          seconds: 5,
        );
      },
      (_) {
        ref
          ..invalidate(vendorBundleProvider(widget.bundleId))
          ..invalidate(vendorBundlesProvider);
        SmSnackbar.success(context, done);
      },
    );
  }

  Future<void> _accept(VendorBundle bundle) async {
    final funds = bundle.myFunds;
    final ok = await confirmServiceAction(
      context,
      title: 'Accept this bundle?',
      message: funds.amount > 0
          ? 'You fund ${bundleMoney(funds)} of the discount on your items for '
                'each bundle sold. Creator and platform commission are '
                'charged on the discounted price.'
          : 'Your items join the bundle at the prices shown.',
      confirmLabel: 'Accept',
    );
    if (!ok || !mounted) return;
    final api = ref.read(vendorBundlesApiProvider);
    await _run(
      'accept',
      () => api.accept(bundle.id, termsVersion: bundle.termsVersion),
      done: 'You accepted the bundle.',
    );
  }

  Future<void> _decline(VendorBundle bundle) async {
    final reason = await askServiceReason(
      context,
      title: 'Decline this bundle?',
      message: 'The owner sees your reason.',
      confirmLabel: 'Decline',
      hint: 'Reason (optional)',
      required: false,
      maxLength: 500,
    );
    if (reason == null || !mounted) return;
    final api = ref.read(vendorBundlesApiProvider);
    await _run(
      'decline',
      () => api.decline(bundle.id, reason: reason),
      done: 'You declined the bundle.',
    );
  }

  Future<void> _withdraw(VendorBundle bundle) async {
    final reason = await askServiceReason(
      context,
      title: 'Withdraw from this bundle?',
      message:
          'The bundle stops selling until the owner removes your items or '
          'you accept again.',
      confirmLabel: 'Withdraw',
      hint: 'Reason (optional)',
      required: false,
      maxLength: 500,
    );
    if (reason == null || !mounted) return;
    final api = ref.read(vendorBundlesApiProvider);
    await _run(
      'withdraw',
      () => api.withdraw(bundle.id, reason: reason),
      done: 'You withdrew from the bundle.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bundle = ref.watch(vendorBundleProvider(widget.bundleId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Bundle'),
      ),
      body: SafeArea(
        child: bundle.when(
          loading: () => const SmPageLoader(),
          error: (error, _) => ListView(
            children: [
              VendorBundleLoadFailure(
                error: error,
                onRetry: () =>
                    ref.invalidate(vendorBundleProvider(widget.bundleId)),
              ),
            ],
          ),
          data: (b) => RefreshIndicator(
            onRefresh: () =>
                ref.refresh(vendorBundleProvider(widget.bundleId).future),
            child: _Body(
              bundle: b,
              busy: _busy,
              onAccept: () => unawaited(_accept(b)),
              onDecline: () => unawaited(_decline(b)),
              onWithdraw: () => unawaited(_withdraw(b)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.bundle,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
    required this.onWithdraw,
  });

  final VendorBundle bundle;
  final String? busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final discount = bundleDiscountLabel(bundle.discountPercent);
    final mine = bundle.myItems;
    final mineIds = {for (final i in mine) i.id};
    final others = [
      for (final i in bundle.items)
        if (!mineIds.contains(i.id)) i,
    ];
    final paused = bundle.state == VendorBundleState.paused
        ? bundle.pausedReason
        : null;
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(bundle.title, style: DesignTokens.sectionInnerTitle),
            ),
            VendorBundleStatusPill(bundle: bundle),
          ],
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(
          [
            'by ${bundle.ownerName ?? bundle.ownerKind.label}',
            discount ?? 'no discount',
            'terms v${bundle.termsVersion}',
          ].join(' · '),
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        if (paused != null) ...[
          const SizedBox(height: DesignTokens.s8),
          Text(
            paused.sentence,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorWarning,
            ),
          ),
        ],
        const SizedBox(height: DesignTokens.s16),
        ServiceCard(
          key: VendorBundleDetailScreen.fundsKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your share', style: DesignTokens.mediumSemibold),
              const SizedBox(height: DesignTokens.s8),
              ServiceRow(
                label: 'You fund per bundle sold',
                value: bundleMoney(bundle.myFunds),
                emphasised: true,
              ),
              ServiceRow(
                label: 'Your items at bundle price',
                value: bundleMoney(bundle.myBundleRevenue),
              ),
              ServiceRow(
                label: 'Whole bundle',
                value:
                    '${bundleMoney(bundle.bundleTotal)} '
                    '(list ${bundleMoney(bundle.listTotal)})',
              ),
              const SizedBox(height: DesignTokens.s8),
              Text(
                'You fund ${bundleMoney(bundle.myFunds)} of the discount on '
                'your items; creator commission and platform commission are '
                'charged on the discounted price.',
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (bundle.needsItems) ...[
          const SizedBox(height: DesignTokens.s12),
          Text(
            'Add your products to this bundle in Seller Center, then accept '
            'it here.',
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.colorInfo,
            ),
          ),
        ],
        if (mine.isNotEmpty) ...[
          const ServiceSectionTitle('Your items'),
          for (final i in mine) _ItemRow(item: i, mine: true),
        ],
        if (others.isNotEmpty) ...[
          const ServiceSectionTitle('Other items'),
          for (final i in others) _ItemRow(item: i, mine: false),
        ],
        if (bundle.shops.isNotEmpty) ...[
          const ServiceSectionTitle('Shops'),
          for (final s in bundle.shops)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.s4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(s.name, style: DesignTokens.smallRegular),
                  ),
                  Text(
                    s.state.label,
                    style: DesignTokens.smallRegular.copyWith(
                      color: s.state == VendorBundleShopState.accepted
                          ? DesignTokens.colorSuccess
                          : DesignTokens.textMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: DesignTokens.s24),
        if (bundle.canAnswer && !bundle.isEnded) ...[
          ServiceActionButton(
            key: VendorBundleDetailScreen.acceptKey,
            label: 'Accept',
            icon: Icons.check_rounded,
            busy: busy == 'accept',
            onPressed: busy == null ? onAccept : null,
          ),
          const SizedBox(height: DesignTokens.s8),
          ServiceActionButton(
            key: VendorBundleDetailScreen.declineKey,
            label: 'Decline',
            outlined: true,
            destructive: true,
            busy: busy == 'decline',
            onPressed: busy == null ? onDecline : null,
          ),
        ],
        if (bundle.canWithdraw && !bundle.isEnded)
          ServiceActionButton(
            key: VendorBundleDetailScreen.withdrawKey,
            label: 'Withdraw from bundle',
            outlined: true,
            destructive: true,
            busy: busy == 'withdraw',
            onPressed: busy == null ? onWithdraw : null,
          ),
      ],
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.mine});

  final VendorBundleItem item;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final commission = item.commissionRatePercent;
    final detail = [
      '${item.quantity} × ${bundleMoney(item.bundleUnitPrice)}',
      if (item.listUnitPrice.amount > item.bundleUnitPrice.amount)
        'list ${bundleMoney(item.listUnitPrice)}',
      if (commission != null) 'creator ${_percent(commission)}',
      if (mine && item.shopFunds != null)
        'you fund ${bundleMoney(item.shopFunds!)}',
      if (!item.available) 'unavailable',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
            child: SizedBox(
              width: 44,
              height: 44,
              child: MallNetworkImage(url: item.thumbnailUrl),
            ),
          ),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: DesignTokens.smallRegular.copyWith(
                    fontWeight: mine ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  detail,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _percent(double value) =>
      value == value.roundToDouble()
          ? '${value.toInt()}%'
          : '${value.toStringAsFixed(1)}%';
}
