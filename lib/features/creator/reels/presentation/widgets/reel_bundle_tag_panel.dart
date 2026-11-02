import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/data/datasources/reel_bundle_tags_api.dart';
import 'package:stylemint_mobile_frontend/features/creator/reels/shared/reel_bundle_tag_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/domain/bundle_failure.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/presentation/bundle_format.dart';
import 'package:stylemint_mobile_frontend/features/customer/bundles/shared/bundle_providers.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_image.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Tag a bundle": the bundles already on this reel (up to
/// [maxReelBundleTags]) and the creator's Live bundles to add. Bundles are
/// made in Creator Studio. Whether a bundle may go on this reel is the
/// server's ruling (own bundle, or partnerships with every shop); a refusal
/// is shown as it comes.
class ReelBundleTagPanel extends ConsumerStatefulWidget {
  const ReelBundleTagPanel({required this.reelId, super.key});

  final String reelId;

  static Key tagKey(String bundleId) => Key('reel-bundle-tag-add-$bundleId');
  static Key untagKey(String taggedBundleId) =>
      Key('reel-bundle-tag-remove-$taggedBundleId');
  static const Key limitKey = Key('reel-bundle-tag-limit');

  @override
  ConsumerState<ReelBundleTagPanel> createState() => _ReelBundleTagPanelState();
}

class _ReelBundleTagPanelState extends ConsumerState<ReelBundleTagPanel> {
  String? _busy;

  Future<void> _run(String id, Future<BundleFailure?> Function() call) async {
    if (_busy != null) return;
    setState(() => _busy = id);
    final failure = await call();
    if (!mounted) return;
    setState(() => _busy = null);
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bundleFailureMessage(failure)),
          backgroundColor: DesignTokens.colorError,
        ),
      );
      return;
    }
    ref.invalidate(reelBundlesProvider(widget.reelId));
    // The shopper-facing copy of the reel, like a product tag.
    unawaited(
      ref.read(reelsFeedNotifierProvider.notifier).refreshReel(widget.reelId),
    );
  }

  Future<BundleFailure?> _tag(BundleCard bundle) async {
    final result = await ref
        .read(reelBundleTagsApiProvider)
        .tag(widget.reelId, bundleId: bundle.id);
    return result.fold((f) => f, (_) => null);
  }

  Future<BundleFailure?> _untag(String taggedBundleId) async {
    final result = await ref
        .read(reelBundleTagsApiProvider)
        .untag(widget.reelId, taggedBundleId);
    return result.fold((f) => f, (_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(creatorTaggableBundlesProvider);
    final tagged = ref.watch(reelBundlesProvider(widget.reelId));
    final current = tagged.asData?.value ?? const <ReelTaggedBundle>[];
    final full = current.length >= maxReelBundleTags;
    final taggedIds = {for (final t in current) t.bundle.id};

    return mine.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(DesignTokens.s24),
        child: SmPageLoader(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Text(
          bundleFailureOf(error) == null
              ? 'We could not load your bundles.'
              : bundleFailureMessage(bundleFailureOf(error)!),
          style: DesignTokens.bodyText,
        ),
      ),
      data: (bundles) => ListView(
        shrinkWrap: true,
        children: [
          if (current.isNotEmpty) ...[
            Text(
              'On this reel (${current.length} of $maxReelBundleTags)',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            for (final t in current)
              _BundleRow(
                bundle: t.bundle,
                trailing: _busy == t.taggedBundleId
                    ? const _Spinner()
                    : IconButton(
                        key: ReelBundleTagPanel.untagKey(t.taggedBundleId),
                        tooltip: 'Remove from reel',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _busy != null
                            ? null
                            : () => unawaited(
                                _run(
                                  t.taggedBundleId,
                                  () => _untag(t.taggedBundleId),
                                ),
                              ),
                      ),
              ),
            const Divider(color: DesignTokens.borderDefault),
          ],
          if (full)
            Padding(
              key: ReelBundleTagPanel.limitKey,
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.s8),
              child: Text(
                'A reel can show up to $maxReelBundleTags bundles. Remove one '
                'to add another.',
                style: DesignTokens.bodyText,
              ),
            ),
          if (bundles.isEmpty)
            const Padding(
              padding: EdgeInsets.all(DesignTokens.s16),
              child: Text(
                'You have no live bundles yet. Make one in Creator Studio, '
                'and it shows here once every shop has accepted.',
                style: DesignTokens.bodyText,
              ),
            ),
          for (final b in bundles)
            if (!taggedIds.contains(b.id))
              _BundleRow(
                bundle: b,
                onTap: full || _busy != null
                    ? null
                    : () => unawaited(_run(b.id, () => _tag(b))),
                tileKey: ReelBundleTagPanel.tagKey(b.id),
                trailing: _busy == b.id
                    ? const _Spinner()
                    : Icon(
                        Icons.add,
                        color: full ? DesignTokens.textMuted : null,
                      ),
              ),
        ],
      ),
    );
  }
}

class _BundleRow extends StatelessWidget {
  const _BundleRow({
    required this.bundle,
    required this.trailing,
    this.onTap,
    this.tileKey,
  });

  final BundleCard bundle;
  final Widget trailing;
  final VoidCallback? onTap;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) => ListTile(
    key: tileKey,
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: MallNetworkImage(url: bundle.imageUrl),
      ),
    ),
    title: Text(
      bundle.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: DesignTokens.bodyText,
    ),
    subtitle: Text(
      [
        bundleMoney(bundle.bundleTotal),
        ?bundleDiscountLabel(bundle.discountPercent),
        if (bundle.shopCount > 0)
          '${bundle.shopCount} ${bundle.shopCount == 1 ? 'shop' : 'shops'}',
      ].join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: DesignTokens.bodyText,
    ),
    trailing: trailing,
  );
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
