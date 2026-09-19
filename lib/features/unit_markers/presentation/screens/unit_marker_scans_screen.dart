import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/widgets/unit_marker_notice.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_appbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Surface 7 — **where this tag has been read, and when.**
///
/// ## There is no location in this feature
///
/// The only place StyleMint can state is a registered `VendorStore` whose own
/// StyleMint code the person scanning presented alongside the item. That is
/// the whole place registry. There is no GPS in this flow, no IP-derived
/// city, and no "nearest store" inference.
///
/// So a reading whose place was not proved shows **no place** — and says so
/// in words. It does not show a blank line under a "Scanned at" label, it
/// does not fall back to the seller's default store, and it does not fill the
/// gap with the store from a neighbouring row. A reading nobody proved a
/// place for is a reading with no place, and that is the honest thing to
/// print.
class UnitMarkerScansScreen extends ConsumerWidget {
  const UnitMarkerScansScreen({required this.reference, super.key});

  /// The non-secret `UMxxxxxxxxxx` handle.
  final String reference;

  static const String title = 'Scan history';

  static const String emptyHeading = 'This tag has not been scanned yet';
  static const String emptyBody =
      'Nobody has read this tag. Readings appear here as soon as someone '
      'scans it — yourself, a courier, or whoever is holding the item.';

  static const String failedHeading = "We couldn't load this tag's readings";
  static const String retryLabel = 'Try again';

  /// Said plainly, in place of a blank. A reading whose place nobody proved
  /// is a reading with no place — not a reading at an unknown place that
  /// could be filled in later.
  static const String noPlace = 'No place recorded';
  static const String unnamedStore = 'A registered store, not named';
  static const String placeUnrecognised = 'Place not recognised';
  static const String noTime = 'Time not recorded';

  /// The rule, said once, so no row has to carry a disclaimer.
  static const String placeRuleHeading = 'How a place gets recorded';
  static const String placeRuleBody =
      'A store is shown only when the person scanning presented that store’s '
      'own StyleMint code alongside the item. StyleMint records no other '
      'location — no GPS and no city guessed from a network — so a reading '
      'without that proof shows no place at all.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = unitMarkerScansNotifierProvider(reference);
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: const SmAppBar(title: UnitMarkerScansScreen.title),
      body: SafeArea(
        child: switch (state) {
          UnitMarkerScansLoading() => const Center(
            child: SmBrandLoader(semanticLabel: 'Loading scan history'),
          ),
          UnitMarkerScansFailed(:final failure) => SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnitMarkerNotice(
                  icon: Icons.cloud_off_rounded,
                  tone: UnitMarkerNoticeTone.bad,
                  heading: UnitMarkerScansScreen.failedHeading,
                  body: NetworkExceptions.getMessage(failure),
                ),
                const SizedBox(height: DesignTokens.s16),
                SmOutlinedButton(
                  label: UnitMarkerScansScreen.retryLabel,
                  onPressed: () =>
                      unawaited(ref.read(provider.notifier).load()),
                ),
              ],
            ),
          ),
          final UnitMarkerScansLoaded loaded when loaded.isEmpty =>
            const SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.s16),
              child: UnitMarkerNotice(
                icon: Icons.history_rounded,
                heading: UnitMarkerScansScreen.emptyHeading,
                body: UnitMarkerScansScreen.emptyBody,
              ),
            ),
          final UnitMarkerScansLoaded loaded => ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              Text(reference, style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s16),
              const UnitMarkerNotice(
                icon: Icons.storefront_outlined,
                heading: UnitMarkerScansScreen.placeRuleHeading,
                body: UnitMarkerScansScreen.placeRuleBody,
              ),
              const SizedBox(height: DesignTokens.s16),
              for (final scan in loaded.scans) _ScanRow(scan: scan),
              const SizedBox(height: DesignTokens.s24),
            ],
          ),
        },
      ),
    );
  }
}

class _ScanRow extends StatelessWidget {
  const _ScanRow({required this.scan});

  final UnitMarkerScan scan;

  @override
  Widget build(BuildContext context) {
    final proven = scan.hasProvenPlace;
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(
            color: DesignTokens.textMuted.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // An absent timestamp says it is absent rather than showing an
            // epoch or today's date.
            Text(
              scan.scannedAt == null
                  ? UnitMarkerScansScreen.noTime
                  : formatDateTime(scan.scannedAt!),
              style: DesignTokens.mediumSemibold.copyWith(
                color: scan.scannedAt == null
                    ? DesignTokens.textMuted
                    : DesignTokens.textLight,
              ),
            ),
            // An unrecognised `via` renders as nothing at all, not as a raw
            // wire token.
            if (scan.viaLabel case final via?) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(
                via,
                style: DesignTokens.smallRegular.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.s8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  proven
                      ? Icons.storefront_outlined
                      : Icons.location_off_outlined,
                  size: DesignTokens.s20,
                  color: proven
                      ? DesignTokens.colorSuccess
                      : DesignTokens.textMuted,
                ),
                const SizedBox(width: DesignTokens.s8),
                Expanded(
                  child: Text(
                    switch (scan.placeKind) {
                      // Proven: the scanner presented this store's own code.
                      UnitScanPlaceKind.vendorStore when proven =>
                        scan.vendorStoreName!,
                      // A store was recorded but came back unnamed. The id is
                      // not a place a person can read, so it is not printed
                      // as one.
                      UnitScanPlaceKind.vendorStore =>
                        UnitMarkerScansScreen.unnamedStore,
                      UnitScanPlaceKind.notStated =>
                        UnitMarkerScansScreen.noPlace,
                      UnitScanPlaceKind.unrecognised =>
                        UnitMarkerScansScreen.placeUnrecognised,
                    },
                    style: DesignTokens.mediumRegular.copyWith(
                      color: proven
                          ? DesignTokens.textLight
                          : DesignTokens.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
