import 'package:flutter/material.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Passport schema 2 on product detail: what this passport identifies, the
/// claims recorded against the listing, and what is not recorded at all.
///
/// ## The one rule everything here serves
///
/// A claim is the platform's own statement only when
/// [PassportClaim.presentAsFact] is true, which happens only for a verified
/// claim. Everything else is somebody's assertion and is rendered as one:
/// named issuer, quoted words, and the server's own
/// [PassportClaim.assuranceLabel] printed verbatim underneath — "Recorded by
/// the seller. Nobody has checked it."
///
/// ## Withdrawn is not a weaker claim
///
/// A claim the platform checked and found against is treated by the backend
/// as withdrawn, not as a claim with a caveat. It is drawn in its own block,
/// struck through, with no issuer attribution — because attributing it would
/// resurrect it as "the seller says X", which is exactly the reading the
/// check disposed of.
///
/// ## Listing, not object
///
/// [PassportSubject.identifiesPhysicalUnit] is false on every passport this
/// platform produces: nothing binds a marker to a physical item and an order
/// line. That is stated plainly at the top, because a buyer reading a serial
/// number on a passport will otherwise assume it is the serial number of the
/// thing in their hands.
///
/// ## Absent is not none
///
/// [PassportCoverage.unknownKinds] names what the platform has no record of.
/// A listing with no warranty record does not have "no warranty" — it has an
/// unrecorded one, and the block says so in those words.
class PassportClaimsSection extends StatelessWidget {
  const PassportClaimsSection({required this.passport, super.key});

  final ProductPassport passport;

  @override
  Widget build(BuildContext context) {
    final subject = passport.subject;
    final coverage = passport.coverage;
    final standing = passport.standingClaims;
    final withdrawn = passport.withdrawnClaims;

    // A v1 payload carries none of this, and the section draws nothing rather
    // than an empty heading.
    if (subject == null &&
        coverage == null &&
        standing.isEmpty &&
        withdrawn.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (subject != null) ...[
          const SizedBox(height: DesignTokens.s12),
          _SubjectBlock(subject: subject),
        ],
        if (standing.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s16),
          Text(
            'Recorded against this listing',
            style: DesignTokens.mediumSemibold.copyWith(
              color: DesignTokens.textWhite,
            ),
          ),
          for (final claim in standing) _ClaimBlock(claim: claim),
        ],
        if (withdrawn.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.s16),
          _WithdrawnBlock(claims: withdrawn),
        ],
        if (coverage != null) ...[
          const SizedBox(height: DesignTokens.s16),
          _CoverageBlock(coverage: coverage),
        ],
      ],
    );
  }
}

/// What this passport is a passport *of*.
class _SubjectBlock extends StatelessWidget {
  const _SubjectBlock({required this.subject});

  static const String _listingNotUnit =
      'This describes the listing, not the individual item you receive. '
      'StyleMint cannot tell which physical item was shipped to you.';

  final PassportSubject subject;

  @override
  Widget build(BuildContext context) {
    final serial = subject.serialOrBatchNumber;
    final lines = <String>[
      // Said plainly, and said first, because everything below it is about a
      // listing and a reader will otherwise assume it is about their parcel.
      if (!subject.identifiesPhysicalUnit) _listingNotUnit,
      if (subject.scopeExplanation.isNotEmpty) subject.scopeExplanation,
    ];
    return Semantics(
      container: true,
      label: [
        'What this passport covers.',
        ...lines,
        if (serial != null) 'Batch or serial number $serial.',
      ].join(' '),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: DesignTokens.iconSmall,
            color: DesignTokens.textMuted,
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                    child: Text(
                      line,
                      style: DesignTokens.tiny.copyWith(
                        color: DesignTokens.textMuted,
                      ),
                    ),
                  ),
                if (serial != null)
                  Text(
                    'Batch or serial number: $serial',
                    style: DesignTokens.tiny.copyWith(
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
}

/// One standing claim: its kind, who said it, what they said, and how far it
/// may be relied on.
class _ClaimBlock extends StatelessWidget {
  const _ClaimBlock({required this.claim});

  final PassportClaim claim;

  @override
  Widget build(BuildContext context) {
    final copy = passportAssuranceCopy(claim.assurance);
    final attribution = passportAttributionLine(claim);
    return Semantics(
      container: true,
      label: [
        claim.kindLabel,
        copy.semanticSummary,
        ?attribution,
        claim.statement,
        claim.assuranceLabel,
      ].where((line) => line.isNotEmpty).join(' '),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: DesignTokens.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (claim.kindLabel.isNotEmpty)
              Text(
                claim.kindLabel,
                style: DesignTokens.small.copyWith(
                  color: DesignTokens.textWhite,
                ),
              ),
            const SizedBox(height: DesignTokens.s6),
            // Aligned start so a long label at 1.3× wraps inside the pill
            // rather than fighting a sibling for the row.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MallStatusPill(
                label: copy.pillLabel,
                tone: copy.tone,
                icon: copy.glyph,
                semanticLabel: copy.semanticSummary,
                dense: true,
              ),
            ),
            const SizedBox(height: DesignTokens.s6),
            // An unverified claim is never rendered as the platform's own
            // sentence. It is named to its issuer and quoted.
            if (attribution != null)
              Text(
                attribution,
                style: DesignTokens.tiny.copyWith(
                  color: DesignTokens.textMuted,
                ),
              ),
            Text(
              attribution == null ? claim.statement : '“${claim.statement}”',
              style: DesignTokens.smallRegular.copyWith(
                color: DesignTokens.textMuted,
              ),
            ),
            if (claim.assuranceLabel.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s4),
              // Verbatim, every time. This is the sentence that decides
              // whether a reader takes the claim as checked or as claimed.
              Text(
                claim.assuranceLabel,
                style: DesignTokens.tiny.copyWith(
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

/// Claims a check found against. Shown, because hiding them would leave the
/// listing looking cleaner than its record — and shown as withdrawn, without
/// an issuer, because they are no longer claims anybody is making.
class _WithdrawnBlock extends StatelessWidget {
  const _WithdrawnBlock({required this.claims});

  final List<PassportClaim> claims;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: 'Withdrawn records.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdrawn',
          style: DesignTokens.mediumSemibold.copyWith(
            color: DesignTokens.textWhite,
          ),
        ),
        for (final claim in claims)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s12),
            child: Semantics(
              label: [
                claim.kindLabel,
                'Withdrawn.',
                'The withdrawn record read: ${claim.statement}',
                claim.assuranceLabel,
              ].where((line) => line.isNotEmpty).join(' '),
              excludeSemantics: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.block_outlined,
                    size: DesignTokens.iconSmall,
                    color: DesignTokens.textMuted,
                  ),
                  const SizedBox(width: DesignTokens.s8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          claim.kindLabel.isEmpty
                              ? 'Withdrawn'
                              : '${claim.kindLabel} — withdrawn',
                          style: DesignTokens.small.copyWith(
                            color: DesignTokens.textWhite,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        Text(
                          'The withdrawn record read:',
                          style: DesignTokens.tiny.copyWith(
                            color: DesignTokens.textMuted,
                          ),
                        ),
                        // Struck through, not attributed. The strike is the
                        // greyscale carrier; the heading and the label above
                        // carry the same fact in words.
                        Text(
                          claim.statement,
                          style: DesignTokens.smallRegular.copyWith(
                            color: DesignTokens.textMuted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        if (claim.assuranceLabel.isNotEmpty) ...[
                          const SizedBox(height: DesignTokens.s4),
                          // Verbatim: "…Treat it as withdrawn, not as a
                          // claim."
                          Text(
                            claim.assuranceLabel,
                            style: DesignTokens.tiny.copyWith(
                              color: DesignTokens.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

/// What the passport does not cover.
class _CoverageBlock extends StatelessWidget {
  const _CoverageBlock({required this.coverage});

  static const String _absentIsNotNone =
      'Not recorded is not the same as none. StyleMint has no record of '
      'these for this listing; it is not saying the listing has none.';

  final PassportCoverage coverage;

  @override
  Widget build(BuildContext context) {
    final unknown = coverage.unknownKinds;
    return Semantics(
      container: true,
      label: [
        if (coverage.summary.isNotEmpty) coverage.summary,
        if (unknown.isNotEmpty) 'Not recorded: ${unknown.join(', ')}.',
        if (unknown.isNotEmpty) _absentIsNotNone,
      ].join(' '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (coverage.summary.isNotEmpty)
            // Verbatim, and built server-side from the same counts, so the
            // sentence and the numbers cannot drift apart.
            Text(
              coverage.summary,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          if (unknown.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            Text(
              'Not recorded for this listing',
              style: DesignTokens.small.copyWith(
                color: DesignTokens.textWhite,
              ),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              unknown.join(' · '),
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s4),
            Text(
              _absentIsNotNone,
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// The attribution line for a claim, or null when the platform verified it
/// and may state it itself.
///
/// Null is returned only for [PassportClaim.presentAsFact], which the mapper
/// already narrows to a verified claim. Everything else — including an
/// assurance this build does not recognise — gets a name in front of it.
String? passportAttributionLine(PassportClaim claim) {
  if (claim.presentAsFact) return null;
  final issuer = claim.issuerName.trim();
  return issuer.isEmpty ? 'Recorded on this listing:' : '$issuer states:';
}

/// The wording, glyph and tone for one assurance.
typedef PassportAssuranceCopy = ({
  String pillLabel,
  IconData glyph,
  MallStatusTone tone,
  String semanticSummary,
});

/// Four assurances plus the unknown, each with its own glyph shape so the
/// distinction survives greyscale: a tick, a pencil, a crossed circle and a
/// question mark.
///
/// [PassportAssurance.unrecognised] reads as unchecked and never as verified.
/// An unknown value from a newer server must not arrive wearing the
/// platform's own endorsement.
PassportAssuranceCopy passportAssuranceCopy(PassportAssurance assurance) =>
    switch (assurance) {
      PassportAssurance.verified => (
        pillLabel: 'Checked by StyleMint',
        glyph: Icons.verified_outlined,
        tone: MallStatusTone.success,
        semanticSummary:
            'Checked by StyleMint against a source outside the claimant.',
      ),
      PassportAssurance.recorded => (
        pillLabel: 'Not checked',
        glyph: Icons.edit_note_outlined,
        tone: MallStatusTone.neutral,
        semanticSummary: 'Recorded, and nobody has checked it.',
      ),
      PassportAssurance.couldNotVerify => (
        pillLabel: 'Could not be checked',
        glyph: Icons.help_outline_rounded,
        tone: MallStatusTone.neutral,
        semanticSummary:
            'StyleMint tried to check this and reached no conclusion. It '
            'remains unverified, which is not the same as having failed.',
      ),
      PassportAssurance.verificationFailed => (
        pillLabel: 'Withdrawn',
        glyph: Icons.block_outlined,
        tone: MallStatusTone.caution,
        semanticSummary:
            'Checked and it did not hold. Treated as withdrawn, not as a '
            'claim.',
      ),
      PassportAssurance.unrecognised => (
        pillLabel: 'Not checked',
        glyph: Icons.help_outline_rounded,
        tone: MallStatusTone.neutral,
        semanticSummary:
            'This record uses an assurance this version of the app does not '
            'recognise. It is shown as unchecked.',
      ),
    };
