import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/widgets/passport_claims_section.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_scan.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_appbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Surface 3 — **what a stranger holding the item is shown.**
///
/// ## The boundary, stated
///
/// This screen renders the scan result and, when the tag is bound, the unit
/// passport. Between them they say:
///
/// * whether the tag is one StyleMint issued, and whether it is still active;
/// * which listing it belongs to, by name;
/// * whether it is bound to a completed sale, and the date it was bound;
/// * the store where the scan happened, and only when the scanner presented
///   that store's own code.
///
/// It shows **no order id, no sub-order, no order line, no buyer account, no
/// buyer name, no address, no price and no tracking number**. That is not a
/// filter applied here — none of those fields exist on
/// [UnitMarkerScanResult], none exist on the passport shape, and the ports
/// behind both endpoints cannot fetch them. There is deliberately no second
/// call anywhere on this screen to fill the gap, because filling it is the
/// mistake the whole design exists to prevent.
class UnitTagPassportScreen extends ConsumerWidget {
  const UnitTagPassportScreen({
    required this.unitMarkerId,
    this.scan,
    super.key,
  });

  /// The opaque id the scan returned. Safe in the route: it is not a
  /// credential, the passport re-checks the binding, and a guessed one is
  /// simply unbound.
  final String unitMarkerId;

  /// The scan answer, when this screen was reached straight from a reading.
  /// Null when the route was opened cold, in which case the passport is the
  /// only thing shown — and nothing is invented to stand in for the rest.
  final UnitMarkerScanResult? scan;

  static const String title = 'This item';
  static const String genuineHeading = 'StyleMint issued this tag';
  static const String revokedHeading = 'This tag has been retired';
  static const String revokedBody =
      'The seller switched this tag off. A retired tag on an item in your '
      'hands is worth asking the seller about.';
  static const String unknownStatusBody =
      'This app does not recognise the status StyleMint reported for this '
      'tag, so it is not telling you the tag is good.';

  /// The sentence for the 404 the passport endpoint answers with.
  ///
  /// It is not an error and it is not an empty passport. A genuine tag that
  /// nobody has bound to a sale is a normal, sayable state — a tag on a shelf,
  /// a tag on a sample, a tag printed and not yet used.
  static const String notBoundHeading = 'This tag is not bound to a sale';
  static const String notBoundBody =
      'StyleMint has no record of this tag being attached to an item that was '
      'sold, so there is no unit passport for it. That is not a fault — a tag '
      'is only bound when a seller attaches it while packing or handing over '
      'an order.';

  static const String boundLabel = 'Bound to a completed sale';
  static const String retryLabel = 'Try again';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = unitPassportNotifierProvider(unitMarkerId);
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: const SmAppBar(title: UnitTagPassportScreen.title),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (scan case final reading?) ...[
                _ScanSummary(scan: reading),
                const SizedBox(height: DesignTokens.s20),
              ],
              switch (state) {
                UnitPassportLoading() => const Padding(
                  padding: EdgeInsets.symmetric(vertical: DesignTokens.s48),
                  child: Center(
                    child: SmBrandLoader(semanticLabel: 'Reading passport'),
                  ),
                ),
                UnitPassportNotBound() => const _Note(
                  icon: Icons.link_off_rounded,
                  heading: UnitTagPassportScreen.notBoundHeading,
                  body: UnitTagPassportScreen.notBoundBody,
                ),
                UnitPassportLoaded(:final passport) => PassportClaimsSection(
                  passport: passport,
                ),
                UnitPassportFailed(:final failure) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Note(
                      icon: Icons.cloud_off_rounded,
                      tone: _NoteTone.bad,
                      heading: "We couldn't read this tag's passport",
                      body: NetworkExceptions.getMessage(failure),
                    ),
                    const SizedBox(height: DesignTokens.s16),
                    SmOutlinedButton(
                      label: UnitTagPassportScreen.retryLabel,
                      onPressed: () =>
                          unawaited(ref.read(provider.notifier).load()),
                    ),
                  ],
                ),
              },
              const SizedBox(height: DesignTokens.s24),
            ],
          ),
        ),
      ),
    );
  }
}

/// The scan answer, rendered field by field.
///
/// Every `if` below is an *absent renders as absent* rule: no placeholder
/// date, no "unknown location", no empty label with nothing after it.
class _ScanSummary extends StatelessWidget {
  const _ScanSummary({required this.scan});

  final UnitMarkerScanResult scan;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Note(
        icon: switch (scan.status) {
          UnitMarkerStatus.active => Icons.verified_outlined,
          UnitMarkerStatus.revoked => Icons.gpp_maybe_outlined,
          UnitMarkerStatus.unrecognised => Icons.help_outline_rounded,
        },
        tone: switch (scan.status) {
          UnitMarkerStatus.active => _NoteTone.good,
          UnitMarkerStatus.revoked => _NoteTone.warn,
          UnitMarkerStatus.unrecognised => _NoteTone.warn,
        },
        heading: switch (scan.status) {
          UnitMarkerStatus.active => UnitTagPassportScreen.genuineHeading,
          UnitMarkerStatus.revoked => UnitTagPassportScreen.revokedHeading,
          UnitMarkerStatus.unrecognised => scan.status.label,
        },
        body: switch (scan.status) {
          UnitMarkerStatus.active => 'Tag ${scan.reference}.',
          UnitMarkerStatus.revoked => UnitTagPassportScreen.revokedBody,
          UnitMarkerStatus.unrecognised =>
            UnitTagPassportScreen.unknownStatusBody,
        },
      ),
      const SizedBox(height: DesignTokens.s16),
      // Absent product name renders as nothing, not as an empty heading.
      if (scan.productName case final name?) ...[
        Text(name, style: DesignTokens.h3),
        const SizedBox(height: DesignTokens.s12),
      ],
      if (scan.isBoundToSale)
        _Fact(
          label: UnitTagPassportScreen.boundLabel,
          // Null `inServiceSince` means the date was not recorded, so the
          // fact stands on its own rather than borrowing a made-up date.
          value: scan.inServiceSince == null
              ? 'Yes'
              : 'Yes, since ${formatDateTime(scan.inServiceSince!)}',
        )
      else
        const _Fact(
          label: UnitTagPassportScreen.boundLabel,
          value: 'No',
        ),
      // A place only when the scanner proved one. There is no GPS here and no
      // inferred city: a place StyleMint did not observe renders as absent.
      if (scan.hasProvenPlace)
        _Fact(
          label: 'Scanned at',
          value: [
            scan.vendorStoreName,
            scan.vendorStoreCity,
          ].whereType<String>().where((part) => part.isNotEmpty).join(', '),
        ),
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: DesignTokens.s12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: DesignTokens.smallRegular.copyWith(
            color: DesignTokens.textMuted,
          ),
        ),
        const SizedBox(height: DesignTokens.s4),
        Text(value, style: DesignTokens.body),
      ],
    ),
  );
}

enum _NoteTone { neutral, good, warn, bad }

class _Note extends StatelessWidget {
  const _Note({
    required this.icon,
    required this.heading,
    required this.body,
    this.tone = _NoteTone.neutral,
  });

  final IconData icon;
  final String heading;
  final String body;
  final _NoteTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _NoteTone.neutral => DesignTokens.textLight,
      _NoteTone.good => DesignTokens.colorSuccess,
      _NoteTone.warn => DesignTokens.warning300,
      _NoteTone.bad => DesignTokens.colorError,
    };
    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: DesignTokens.s20, color: color),
          const SizedBox(width: DesignTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: DesignTokens.mediumSemibold.copyWith(color: color),
                ),
                const SizedBox(height: DesignTokens.s4),
                Text(
                  body,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
