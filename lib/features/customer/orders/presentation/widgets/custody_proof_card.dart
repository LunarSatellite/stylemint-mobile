import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/custody_chain.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/custody_proof_export_sheet.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/kathmandu_time.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_timeline.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Permissioned Chain-of-Custody Proof" on order detail.
///
/// The backend has kept a signed, hash-chained record of every handover of
/// this parcel since the first shipment shipped; until now nothing outside the
/// delivery pipeline could read it. This card is the customer's view of it:
/// the handovers, who took the parcel, when — and whether the record itself
/// can be shown to be intact.
///
/// ## Three verification states, never two
///
/// [CustodyVerificationState.verified], [CustodyVerificationState.failed] and
/// [CustodyVerificationState.couldNotVerify] read differently in words *and*
/// in glyph, because a log we could not check is not a log that passed, and a
/// log that failed is not the same claim either. Collapsing the last two would
/// throw away precisely the distinction a signed chain exists to provide.
///
/// ## What this never says
///
/// There is no trust score here, no percentage, no "N of M entries verified",
/// no rating of any courier. The report carries counts; they stay in the
/// report. A number attached to an integrity check reads as a grade, and this
/// capability grades nobody.
///
/// ## What this never invents
///
/// Every row comes from one entry the server returned, in the order it
/// returned them. No intermediate handover is interpolated and no timestamp is
/// derived from another entry's — an entry with no parsable `occurredUtc`
/// simply shows no time. (See the deleted "order timeline" that computed every
/// event from `placedAt`; this must not become a second one.)
class CustodyProofCard extends ConsumerWidget {
  const CustodyProofCard({required this.trackingNumber, super.key});

  final String trackingNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proof = ref.watch(custodyProofProvider(trackingNumber)).asData?.value;
    // No entries, an unavailable endpoint, or still loading: nothing renders.
    // Not an error, not an empty shell — the rest of order detail is unaware
    // this card exists.
    if (proof == null || proof.isEmpty) return const SizedBox.shrink();
    return CustodyProofView(proof: proof, trackingNumber: trackingNumber);
  }
}

/// The card itself, separated from the read so it can be rendered from a
/// fixture in tests and reused wherever a proof is already in hand.
class CustodyProofView extends StatelessWidget {
  const CustodyProofView({required this.proof, this.trackingNumber, super.key});

  final CustodyProof proof;

  /// The parcel this proof belongs to, when the card knows it. Non-null adds
  /// the hand-over control; null renders the card exactly as it always has,
  /// which is what a fixture-driven test gets.
  final String? trackingNumber;

  @override
  Widget build(BuildContext context) {
    if (proof.isEmpty) return const SizedBox.shrink();
    final verdict = custodyVerdictCopy(proof.verification.state);
    return Semantics(
      container: true,
      // Without this the verdict pill's own label is swallowed into the
      // card's, and a screen-reader user hears the outcome only as a tail on
      // a long sentence instead of as its own focusable announcement.
      explicitChildNodes: true,
      label: 'Chain of custody for this parcel. ${verdict.semanticSummary}',
      child: Container(
        // The leading gap is the card's own, so that a parcel without a
        // custody log leaves no trace on order detail at all.
        margin: const EdgeInsets.only(top: DesignTokens.s16),
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chain of custody', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s4),
            const Text(
              'Every handover of this parcel was signed at the moment it '
              'happened, and each entry seals the one before it.',
              style: DesignTokens.smallDescription,
            ),
            const SizedBox(height: DesignTokens.s12),
            _VerdictBlock(verdict: verdict),
            const SizedBox(height: DesignTokens.s16),
            MallTimeline(
              compact: true,
              semanticLabel: 'Handovers recorded for this parcel',
              steps: [
                for (final entry in proof.entries) _stepFor(entry),
              ],
            ),
            // The export has been buyer-facing since it shipped and had no
            // caller of any kind: the endpoint is authenticated and scoped to
            // the buyer, so no buyer could reach it without a client. This is
            // that client, and it is deliberately a control rather than a
            // screen — the document is hashes and signatures, which nobody
            // checks by eye, and the question a buyer has about their own
            // parcel is already answered by the verdict above. What the
            // export adds is a document somebody *else* can check.
            if (trackingNumber case final tracking?) ...[
              const SizedBox(height: DesignTokens.s16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => CustodyProofExportSheet.open(
                    context,
                    trackingNumber: tracking,
                  ),
                  style: DesignTokens.outlinedButtonStyle(),
                  child: const Text('Hand this proof to someone'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static MallTimelineStep _stepFor(CustodyEntry entry) {
    final occurred = entry.occurredUtc;
    return MallTimelineStep(
      markKey: ValueKey('custody-entry-${entry.sequence}'),
      title: custodyEventTitle(entry.eventKind),
      // Exceptions are corrections appended to the chain, not stages that
      // "failed" — but they are the one kind the customer should not read
      // past, so they carry the failed mark's cross glyph.
      state: entry.eventKind == CustodyEventKind.exception
          ? MallStepState.failed
          : MallStepState.done,
      detail: _detailFor(entry),
      // Shown only when the entry actually carries one. Never borrowed from a
      // neighbouring entry, never estimated.
      timestamp: occurred == null ? null : formatNptDateTime(occurred),
    );
  }

  static String? _detailFor(CustodyEntry entry) {
    final delegate = entry.receivedByDelegateName;
    final notes = entry.notes;
    final lines = <String>[
      // The delegate's name is covered by the signature, so the chain proves
      // who actually took the parcel — that is worth saying in full.
      if (delegate != null) 'Taken by $delegate on your behalf',
      ?notes,
    ];
    return lines.isEmpty ? null : lines.join('\n');
  }
}

/// Human-facing name for one entry's kind. Unknown kinds read as a plain
/// handover rather than being hidden — an entry the customer cannot see is
/// worse than one labelled generically.
String custodyEventTitle(CustodyEventKind kind) => switch (kind) {
  CustodyEventKind.sealApplied => 'Sealed by the seller',
  CustodyEventKind.pickedUp => 'Picked up',
  CustodyEventKind.handedOff => 'Passed to the next courier',
  CustodyEventKind.deliveryConfirmed => 'Delivered',
  CustodyEventKind.exception => 'Exception recorded',
  CustodyEventKind.returnInitiated => 'Return started',
  CustodyEventKind.unknown => 'Handover recorded',
};

/// The wording, glyph and tone for one verification outcome.
typedef CustodyVerdictCopy = ({
  String pillLabel,
  IconData glyph,
  MallStatusTone tone,
  String body,
  String semanticSummary,
});

/// Three outcomes, three glyphs, three sentences.
///
/// The glyphs are deliberately different shapes, not merely different
/// colours: a tick, a broken shield and a question mark stay apart in
/// greyscale, under a colour-blind palette and at a glance.
///
/// The [CustodyVerificationState.failed] wording says what is true — the log
/// cannot be shown to be intact — and stops there. It does not name a
/// courier, does not say the parcel was tampered with, and does not imply
/// anyone did anything. A broken hash chain is a fact about a record.
CustodyVerdictCopy custodyVerdictCopy(CustodyVerificationState state) =>
    switch (state) {
      CustodyVerificationState.verified => (
        pillLabel: 'Signatures check out',
        glyph: Icons.check_circle_outline_rounded,
        tone: MallStatusTone.success,
        body:
            'We re-checked every signature and every link in this handover '
            'log. All of them hold.',
        semanticSummary:
            'Verified: every signature in the handover log checks out.',
      ),
      CustodyVerificationState.failed => (
        pillLabel: 'Signatures do not check out',
        glyph: Icons.gpp_bad_outlined,
        tone: MallStatusTone.danger,
        body:
            'The handover log for this parcel cannot be shown to be intact. '
            'That is a statement about the record itself, not about anyone '
            'who handled your parcel. Support can look into it with you.',
        semanticSummary:
            'Failed verification: the handover log cannot be shown to be '
            'intact.',
      ),
      CustodyVerificationState.couldNotVerify => (
        pillLabel: 'Not checked yet',
        glyph: Icons.help_outline_rounded,
        tone: MallStatusTone.neutral,
        body:
            'We could not run the check just now, so we cannot tell you '
            'either way. This is not the same as a check that failed — the '
            'handovers below are what the parcel recorded.',
        semanticSummary:
            'Could not be verified: the check did not run, which is neither a '
            'pass nor a failure.',
      ),
    };

class _VerdictBlock extends StatelessWidget {
  const _VerdictBlock({required this.verdict});

  final CustodyVerdictCopy verdict;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Aligned start rather than spaced apart, so a long label at 1.3x wraps
      // inside the pill instead of fighting a sibling for the row.
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: MallStatusPill(
          label: verdict.pillLabel,
          tone: verdict.tone,
          icon: verdict.glyph,
          semanticLabel: verdict.semanticSummary,
        ),
      ),
      const SizedBox(height: DesignTokens.s8),
      Text(verdict.body, style: DesignTokens.smallDescription),
    ],
  );
}
