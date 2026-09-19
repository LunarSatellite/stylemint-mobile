import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/entities/unit_marker_binding.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/widgets/unit_marker_notice.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_appbar.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_button.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Surface 6 — **every binding this tag has ever carried, corrections
/// included.**
///
/// ## Why a superseded row is still on the screen
///
/// The backend supersedes a binding rather than overwriting it, and keeps the
/// seller's own reason on the retired row. That design is worth nothing if
/// the app renders only the row that currently stands — a correction would
/// then look exactly like a binding that was right the first time, and the
/// question a trail exists to answer ("what did this tag say before, and who
/// said it was wrong?") would have no surface.
///
/// So a superseded binding here reads *as superseded*: it keeps its own
/// heading, it carries the reason verbatim, and it names the row that
/// replaced it. It is never struck through into illegibility and never
/// dropped.
///
/// ## The boundary
///
/// These are the seller's own orders, so their ids appear. Nothing here
/// reaches a buyer account, a buyer name, an address, a price or a tracking
/// number — no field on [UnitMarkerBinding] carries one and this screen makes
/// no second call to go and find one.
class UnitMarkerBindingsScreen extends ConsumerWidget {
  const UnitMarkerBindingsScreen({required this.reference, super.key});

  /// The non-secret `UMxxxxxxxxxx` handle. Never a credential.
  final String reference;

  static const String title = 'Binding history';

  static const String emptyHeading = 'This tag has never been bound';
  static const String emptyBody =
      'No packer has attached this tag to an order line yet. A tag is only '
      'bound while packing or at handover, so a minted tag sitting on a sheet '
      'has no bindings — that is normal.';

  static const String failedHeading = "We couldn't load this tag's bindings";
  static const String retryLabel = 'Try again';

  static const String supersededLabel = 'Superseded';
  static const String supersededOnLabel = 'Superseded on';
  static const String currentLabel = 'Current binding';
  static const String currentCorrectionLabel =
      'Current binding — a correction';
  static const String reasonLabel = 'Reason given';

  /// Shown when a superseded row's replacement is not in this response.
  /// Absent stays absent: the screen does not pick the nearest row and call
  /// it the replacement.
  static const String replacementMissing =
      'The binding that replaced this one is not in this history.';

  /// Shown when a correction's predecessor is not in this response.
  static const String predecessorMissing =
      'This was recorded as a correction, but the binding it replaced is not '
      'in this history.';

  /// Shown when a superseded row carries no reason.
  static const String reasonMissing =
      'No reason was recorded with this correction.';

  static const String noLiveHeading = 'Nothing is bound to this tag now';
  static const String noLiveBody =
      'Every binding this tag has carried was later superseded, and none of '
      'the corrections left a binding standing. The trail below shows what '
      'happened.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = unitMarkerBindingsNotifierProvider(reference);
    final state = ref.watch(provider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: const SmAppBar(title: UnitMarkerBindingsScreen.title),
      body: SafeArea(
        child: switch (state) {
          UnitMarkerBindingsLoading() => const Center(
            child: SmBrandLoader(semanticLabel: 'Loading binding history'),
          ),
          UnitMarkerBindingsFailed(:final failure) => SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UnitMarkerNotice(
                  icon: Icons.cloud_off_rounded,
                  tone: UnitMarkerNoticeTone.bad,
                  heading: UnitMarkerBindingsScreen.failedHeading,
                  body: NetworkExceptions.getMessage(failure),
                ),
                const SizedBox(height: DesignTokens.s16),
                SmOutlinedButton(
                  label: UnitMarkerBindingsScreen.retryLabel,
                  onPressed: () =>
                      unawaited(ref.read(provider.notifier).load()),
                ),
              ],
            ),
          ),
          final UnitMarkerBindingsLoaded loaded when loaded.isEmpty =>
            const SingleChildScrollView(
              padding: EdgeInsets.all(DesignTokens.s16),
              child: UnitMarkerNotice(
                icon: Icons.link_off_rounded,
                heading: UnitMarkerBindingsScreen.emptyHeading,
                body: UnitMarkerBindingsScreen.emptyBody,
              ),
            ),
          final UnitMarkerBindingsLoaded loaded => ListView(
            padding: const EdgeInsets.all(DesignTokens.s16),
            children: [
              Text(reference, style: DesignTokens.h3),
              const SizedBox(height: DesignTokens.s16),
              // Says up front whether anything stands, so a trail of nothing
              // but superseded rows cannot be misread as a live binding.
              if (loaded.liveBinding == null) ...[
                const UnitMarkerNotice(
                  icon: Icons.link_off_rounded,
                  tone: UnitMarkerNoticeTone.warn,
                  heading: UnitMarkerBindingsScreen.noLiveHeading,
                  body: UnitMarkerBindingsScreen.noLiveBody,
                ),
                const SizedBox(height: DesignTokens.s16),
              ],
              for (final entry in loaded.trail)
                _BindingCard(entry: entry),
              const SizedBox(height: DesignTokens.s24),
            ],
          ),
        },
      ),
    );
  }
}

/// One row of the trail, with the rows around it.
class _BindingCard extends StatelessWidget {
  const _BindingCard({required this.entry});

  final BindingTrailEntry entry;

  @override
  Widget build(BuildContext context) {
    final binding = entry.binding;
    final superseded = !binding.isLive;
    final accent = superseded
        ? DesignTokens.warning300
        : DesignTokens.colorSuccess;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  superseded
                      ? Icons.history_toggle_off_rounded
                      : Icons.link_rounded,
                  size: DesignTokens.s20,
                  color: accent,
                ),
                const SizedBox(width: DesignTokens.s12),
                Expanded(
                  child: Text(
                    superseded
                        ? UnitMarkerBindingsScreen.supersededLabel
                        : (binding.isCorrection
                              ? UnitMarkerBindingsScreen.currentCorrectionLabel
                              : UnitMarkerBindingsScreen.currentLabel),
                    style: DesignTokens.mediumSemibold.copyWith(color: accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.s12),

            UnitMarkerFact(
              label: 'Bound at',
              value: binding.boundAtStage.label,
            ),
            // A null timestamp is simply not rendered. No placeholder date.
            if (binding.boundAt case final at?)
              UnitMarkerFact(label: 'Recorded', value: formatDateTime(at)),
            if (binding.orderId.isNotEmpty)
              UnitMarkerFact(label: 'Order', value: binding.orderId),
            if (binding.subOrderLineId.isNotEmpty)
              UnitMarkerFact(
                label: 'Order line',
                value: binding.subOrderLineId,
              ),

            // ── What retired this row ──────────────────────────────────
            if (superseded) ...[
              const Divider(height: DesignTokens.s24),
              if (binding.supersededAt case final at?)
                UnitMarkerFact(
                  label: UnitMarkerBindingsScreen.supersededOnLabel,
                  value: formatDateTime(at),
                  valueColor: DesignTokens.warning300,
                ),
              // The seller's own words, verbatim. Never paraphrased and
              // never replaced with a canned string.
              if (binding.supersededReason case final reason?
                  when reason.trim().isNotEmpty)
                UnitMarkerFact(
                  label: UnitMarkerBindingsScreen.reasonLabel,
                  value: reason,
                )
              else
                Text(
                  UnitMarkerBindingsScreen.reasonMissing,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
              const SizedBox(height: DesignTokens.s4),
              if (entry.replacedBy case final replacement?)
                Text(
                  replacement.boundAt == null
                      ? 'Replaced by a later binding on this tag.'
                      : 'Replaced by the binding recorded '
                            '${formatDateTime(replacement.boundAt!)}.',
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                )
              else
                Text(
                  UnitMarkerBindingsScreen.replacementMissing,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
            ],

            // ── What this row itself replaced ──────────────────────────
            if (binding.isCorrection) ...[
              const Divider(height: DesignTokens.s24),
              if (entry.replaces case final earlier?)
                Text(
                  earlier.boundAt == null
                      ? 'This corrected an earlier binding on this tag.'
                      : 'This corrected the binding recorded '
                            '${formatDateTime(earlier.boundAt!)}.',
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textLight,
                  ),
                )
              else
                Text(
                  UnitMarkerBindingsScreen.predecessorMissing,
                  style: DesignTokens.smallRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
