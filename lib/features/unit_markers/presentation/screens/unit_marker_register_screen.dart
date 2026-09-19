import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/widgets/unit_marker_notice.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_appbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Surface 4 — **the seller's register of minted tags.**
///
/// ## What this list can and cannot say
///
/// `GET vendor/unit-markers` returns a tag's reference, its status, the ids
/// of the listing it was minted for, and the two dates. **It does not return
/// whether the tag is bound to a sale**, and there is no field on
/// [UnitMarker] for one — deliberately, because whether a tag identifies a
/// sold item is a fact about the bindings table, not a flag on the tag.
///
/// So this screen does not show a bound/unbound column. Inventing one from a
/// full page, from the provisioned date, or from anything else on hand would
/// be a guess printed as a fact, and the answer is one tap away on the real
/// route. The header says where the answer lives instead of implying it is
/// already here.
///
/// The product name is likewise **carried in, never derived**. Opened from a
/// listing it is known; opened as the whole register it is not, and then no
/// name is shown rather than a raw id.
///
/// §5.9: nothing on this screen prices anything, reserves stock or moves
/// money. Retiring a tag stops it resolving and does nothing else.
class UnitMarkerRegisterScreen extends ConsumerWidget {
  const UnitMarkerRegisterScreen({this.productId, this.productName, super.key});

  /// Narrows the register to one listing. Null shows every tag the seller has
  /// minted.
  final String? productId;

  /// Only ever what the caller handed over.
  final String? productName;

  static const String title = 'Unit tag register';

  static const String emptyHeading = 'No tags in this register yet';
  static const String emptyBody =
      'Tags appear here once you mint a print run for a listing. Minting '
      'creates physical tags to attach while packing — it changes no stock '
      'and no prices.';
  static const String emptyFilteredBody =
      'No tags have been minted for this listing yet. Minting creates '
      'physical tags to attach while packing — it changes no stock and no '
      'prices.';

  static const String failedHeading = "We couldn't load your tags";
  static const String retryLabel = 'Try again';
  static const String loadMoreLabel = 'Load more tags';
  static const String loadMoreFailedHeading = "We couldn't load the next page";

  /// Said once, at the top, instead of printing a guess on every row.
  static const String bindingNotInListNote =
      'This list does not say whether a tag is attached to a sale — that '
      'lives in each tag’s binding history. Open a tag to read it.';

  static const String revokedBannerHeading = 'Tag retired';
  static const String revokeFailedHeading = "We couldn't retire that tag";

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = (productId: productId, productName: productName);
    final provider = unitMarkerRegisterNotifierProvider(filter);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: const SmAppBar(title: UnitMarkerRegisterScreen.title),
      body: SafeArea(
        child: switch (state) {
          UnitMarkerRegisterLoading() => const Center(
            child: SmBrandLoader(semanticLabel: 'Loading unit tags'),
          ),
          UnitMarkerRegisterFailed(:final failure) => SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnitMarkerNotice(
                  icon: Icons.cloud_off_rounded,
                  tone: UnitMarkerNoticeTone.bad,
                  heading: UnitMarkerRegisterScreen.failedHeading,
                  body: NetworkExceptions.getMessage(failure),
                ),
                const SizedBox(height: DesignTokens.s16),
                SmOutlinedButton(
                  label: UnitMarkerRegisterScreen.retryLabel,
                  onPressed: () => unawaited(notifier.load()),
                ),
              ],
            ),
          ),
          final UnitMarkerRegisterLoaded loaded => _Register(
            loaded: loaded,
            productName: productName,
            isFiltered: productId != null && productId!.isNotEmpty,
            onLoadMore: () => unawaited(notifier.loadMore()),
            onRevoke: notifier.revoke,
            onAcknowledge: notifier.acknowledgeRevoke,
            onRetry: () => unawaited(notifier.load()),
          ),
        },
      ),
    );
  }
}

class _Register extends StatelessWidget {
  const _Register({
    required this.loaded,
    required this.productName,
    required this.isFiltered,
    required this.onLoadMore,
    required this.onRevoke,
    required this.onAcknowledge,
    required this.onRetry,
  });

  final UnitMarkerRegisterLoaded loaded;
  final String? productName;
  final bool isFiltered;
  final VoidCallback onLoadMore;
  final Future<void> Function(String reference) onRevoke;
  final VoidCallback onAcknowledge;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loaded.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (productName case final name?) ...[
              Text(name, style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s12),
            ],
            UnitMarkerNotice(
              icon: Icons.local_offer_outlined,
              heading: UnitMarkerRegisterScreen.emptyHeading,
              body: isFiltered
                  ? UnitMarkerRegisterScreen.emptyFilteredBody
                  : UnitMarkerRegisterScreen.emptyBody,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      children: [
        if (productName case final name?) ...[
          Text(name, style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s12),
        ],
        // The outcome of a retire, kept on screen until it is read.
        if (loaded.revokedReference case final retired?) ...[
          UnitMarkerNotice(
            icon: Icons.gpp_maybe_outlined,
            tone: UnitMarkerNoticeTone.warn,
            heading: UnitMarkerRegisterScreen.revokedBannerHeading,
            body:
                'Tag $retired is retired. A scan of it now reports it '
                'retired instead of active.',
            action: SmOutlinedButton(
              label: 'Dismiss',
              onPressed: onAcknowledge,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
        if (loaded.revokeFailure case final failure?) ...[
          UnitMarkerNotice(
            icon: Icons.cloud_off_rounded,
            tone: UnitMarkerNoticeTone.bad,
            heading: UnitMarkerRegisterScreen.revokeFailedHeading,
            body: NetworkExceptions.getMessage(failure),
            action: SmOutlinedButton(
              label: 'Dismiss',
              onPressed: onAcknowledge,
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
        ],
        Text(
          UnitMarkerRegisterScreen.bindingNotInListNote,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s16),
        for (final marker in loaded.markers)
          _MarkerRow(
            marker: marker,
            isRevoking: loaded.revokingReference == marker.reference,
            onRevoke: onRevoke,
          ),
        if (loaded.loadMoreFailure case final failure?) ...[
          const SizedBox(height: DesignTokens.s8),
          UnitMarkerNotice(
            icon: Icons.cloud_off_rounded,
            tone: UnitMarkerNoticeTone.bad,
            heading: UnitMarkerRegisterScreen.loadMoreFailedHeading,
            body: NetworkExceptions.getMessage(failure),
          ),
        ],
        if (loaded.hasMore) ...[
          const SizedBox(height: DesignTokens.s16),
          if (loaded.isLoadingMore)
            const Center(
              child: SmBrandLoader(semanticLabel: 'Loading more tags'),
            )
          else
            SmOutlinedButton(
              label: UnitMarkerRegisterScreen.loadMoreLabel,
              onPressed: onLoadMore,
            ),
        ],
        const SizedBox(height: DesignTokens.s24),
      ],
    );
  }
}

/// One tag. Reference, status, and the dates the server actually sent.
///
/// A null date renders as nothing. There is no "—", no epoch and no "not
/// recorded yet" standing in for a value the response did not carry.
class _MarkerRow extends StatelessWidget {
  const _MarkerRow({
    required this.marker,
    required this.isRevoking,
    required this.onRevoke,
  });

  final UnitMarker marker;
  final bool isRevoking;
  final Future<void> Function(String reference) onRevoke;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s12),
    child: Material(
      color: DesignTokens.bgAppBody,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        onTap: isRevoking
            ? null
            : () => unawaited(
                _showTagActions(
                  context,
                  marker: marker,
                  onRevoke: onRevoke,
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Narrow + large text: the reference and its chip stack rather
              // than fight for one line.
              Wrap(
                spacing: DesignTokens.s8,
                runSpacing: DesignTokens.s8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(marker.reference, style: DesignTokens.mediumSemibold),
                  _StatusChip(status: marker.status),
                  if (isRevoking)
                    const SmBrandLoader(semanticLabel: 'Retiring tag'),
                ],
              ),
              if (marker.provisionedAt case final minted?) ...[
                const SizedBox(height: DesignTokens.s8),
                Text(
                  'Minted ${formatDateTime(minted)}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
              if (marker.revokedAt case final retired?) ...[
                const SizedBox(height: DesignTokens.s4),
                Text(
                  'Retired ${formatDateTime(retired)}',
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final UnitMarkerStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      UnitMarkerStatus.active => DesignTokens.colorSuccess,
      UnitMarkerStatus.revoked => DesignTokens.warning300,
      UnitMarkerStatus.unrecognised => DesignTokens.textMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s8,
        vertical: DesignTokens.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
      ),
      child: Text(
        status.label,
        style: DesignTokens.smallRegular.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// What a seller can do with one tag.
///
/// A sheet rather than an alert, so the wording has room to be a sentence at
/// 320dp with large text instead of a truncated line.
Future<void> _showTagActions(
  BuildContext context, {
  required UnitMarker marker,
  required Future<void> Function(String reference) onRevoke,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: DesignTokens.bgAppBody,
  isScrollControlled: true,
  builder: (sheetCtx) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(marker.reference, style: DesignTokens.h3),
          const SizedBox(height: DesignTokens.s16),
          _SheetAction(
            icon: Icons.link_rounded,
            label: 'Binding history',
            onTap: () async {
              Navigator.pop(sheetCtx);
              await context.push(
                RouteNames.vendorUnitMarkerBindings.replaceFirst(
                  ':reference',
                  marker.reference,
                ),
              );
            },
          ),
          _SheetAction(
            icon: Icons.history_rounded,
            label: 'Scan history',
            onTap: () async {
              Navigator.pop(sheetCtx);
              await context.push(
                RouteNames.vendorUnitMarkerScans.replaceFirst(
                  ':reference',
                  marker.reference,
                ),
              );
            },
          ),
          // Offered only on a tag that is still active. A revoked tag has
          // nothing left to retire, and an unrecognised status is not a state
          // this build may act on.
          if (marker.status == UnitMarkerStatus.active)
            _SheetAction(
              icon: Icons.block_rounded,
              label: UnitMarkerRevokeSheet.actionLabel,
              isDestructive: true,
              onTap: () async {
                Navigator.pop(sheetCtx);
                await showUnitMarkerRevokeSheet(
                  context,
                  reference: marker.reference,
                  onConfirm: onRevoke,
                );
              },
            ),
        ],
      ),
    ),
  ),
);

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? DesignTokens.colorError
        : DesignTokens.textLight;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.s12),
        child: Row(
          children: [
            Icon(icon, size: DesignTokens.s20, color: color),
            const SizedBox(width: DesignTokens.s12),
            Expanded(
              child: Text(
                label,
                style: DesignTokens.mediumRegular.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Surface 5 — **confirming a retirement before it happens.**
///
/// Revoking is idempotent server-side and there is no route that reverses it,
/// so the effect is permanent. This sheet says what stops working in plain
/// words *before* the call, and the register shows the outcome after it.
///
/// It claims only what the platform actually does: the tag's status changes
/// and a scan reports it retired. It does not promise anything about stock,
/// orders or money, because retiring a tag touches none of them.
class UnitMarkerRevokeSheet extends StatelessWidget {
  const UnitMarkerRevokeSheet({
    required this.reference,
    required this.onConfirm,
    super.key,
  });

  final String reference;
  final Future<void> Function(String reference) onConfirm;

  static const String actionLabel = 'Retire this tag';
  static const String confirmLabel = 'Retire tag';
  static const String cancelLabel = 'Keep this tag';

  static const String heading = 'Retire this tag?';

  /// Plain, and only what is true.
  static const String consequences =
      'Anyone who scans this tag will be told it has been retired instead of '
      'active. This cannot be undone — there is no way to bring a retired tag '
      'back.';
  static const String scopeNote =
      'Retiring a tag changes no stock, no price and no order. It stops the '
      'tag resolving, and nothing else.';

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.s16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.gpp_maybe_outlined,
                size: DesignTokens.s24,
                color: DesignTokens.colorError,
              ),
              const SizedBox(width: DesignTokens.s12),
              Expanded(
                child: Text(
                  UnitMarkerRevokeSheet.heading,
                  style: DesignTokens.h3.copyWith(
                    color: DesignTokens.colorError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(reference, style: DesignTokens.mediumSemibold),
          const SizedBox(height: DesignTokens.s12),
          Text(
            UnitMarkerRevokeSheet.consequences,
            style: DesignTokens.mediumRegular.copyWith(
              color: DesignTokens.textLight,
            ),
          ),
          const SizedBox(height: DesignTokens.s12),
          Text(
            UnitMarkerRevokeSheet.scopeNote,
            style: DesignTokens.smallRegular.copyWith(
              color: DesignTokens.textMuted,
            ),
          ),
          const SizedBox(height: DesignTokens.s20),
          // Stacked, not side by side: at 320dp with large text a row of two
          // buttons is where labels get clipped.
          SmPrimaryButton(
            label: UnitMarkerRevokeSheet.confirmLabel,
            color: DesignTokens.colorError,
            // Closes first, so the register underneath is what shows the tag
            // going out — the in-flight row, then the outcome.
            onPressed: () async {
              Navigator.pop(context);
              unawaited(onConfirm(reference));
            },
          ),
          const SizedBox(height: DesignTokens.s12),
          SmOutlinedButton(
            label: UnitMarkerRevokeSheet.cancelLabel,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  );
}

/// Opens the confirmation. The call only happens if the seller confirms.
Future<void> showUnitMarkerRevokeSheet(
  BuildContext context, {
  required String reference,
  required Future<void> Function(String reference) onConfirm,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: DesignTokens.bgAppBody,
  isScrollControlled: true,
  builder: (_) =>
      UnitMarkerRevokeSheet(reference: reference, onConfirm: onConfirm),
);
