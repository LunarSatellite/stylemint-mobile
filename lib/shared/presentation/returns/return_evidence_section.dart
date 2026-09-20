import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/shared/domain/entities/return_evidence.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// The returns evidence snapshot, rendered the same way for the buyer and for
/// the seller.
///
/// Deliberately takes **no role parameter**. When a return is disputed the
/// point of this surface is that both sides read one set of facts in one
/// wording; a `role` argument would be the first step back to each side
/// arguing from its own summary, so the symmetry is enforced by the type.
///
/// Four rules this widget exists to keep:
///
/// * A finding is a statement, not a verdict. [ReturnEvidenceFinding.statement]
///   is backend-authored and printed verbatim, with the sources it rests on.
///   Nothing here adds blame or predicts an outcome.
/// * The two kinds are told apart **without colour** — each carries its own
///   glyph and its own word, via the Mall kit's status pill, which guarantees
///   a glyph is always drawn.
/// * There is no score. No count of findings, no ratio, no meter, and no
///   re-ordering: findings appear in the order the backend sent them.
/// * Absence renders as nothing at all — see [ReturnEvidence.isSilent].
class ReturnEvidenceSection extends StatelessWidget {
  const ReturnEvidenceSection({required this.evidence, super.key});

  /// Null on every return opened before the snapshot existed. That is the
  /// ordinary case, not an error state.
  final ReturnEvidence? evidence;

  @override
  Widget build(BuildContext context) {
    final snapshot = evidence;
    // Nothing recorded and nothing to explain: draw nothing. An empty card or
    // a "no evidence found" line would make absence look like a claim about
    // the return, and it is not one.
    if (snapshot == null || snapshot.isSilent) return const SizedBox.shrink();

    final collected = snapshot.collectedUtc;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        boxShadow: DesignTokens.shadowCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(header: true, child: const MallEyebrow(_sectionLabel)),
            const SizedBox(height: DesignTokens.s8),
            const Text(_blurb, style: _bodyStyle),
            if (collected != null) ...[
              const SizedBox(height: DesignTokens.s4),
              Text(
                'Taken ${_formatNptDateTime(collected)}',
                style: _footnoteStyle,
              ),
            ],
            for (final finding in snapshot.findings) ...[
              const SizedBox(height: DesignTokens.s16),
              _FindingBlock(
                finding: finding,
                citedFacts: snapshot.factsCitedBy(finding),
              ),
            ],
            if (snapshot.sources.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s16),
              const Divider(height: 1, color: DesignTokens.bgAppBodyLight),
              const SizedBox(height: DesignTokens.s12),
              Semantics(header: true, child: const MallEyebrow(_sourcesLabel)),
              for (final source in snapshot.sources) ...[
                const SizedBox(height: DesignTokens.s8),
                _SourceRow(source: source),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// One finding: its kind as a glyph-bearing pill, the backend's sentence, the
/// sources it rests on and the facts it cites.
class _FindingBlock extends StatelessWidget {
  const _FindingBlock({required this.finding, required this.citedFacts});

  final ReturnEvidenceFinding finding;
  final List<ReturnEvidenceFact> citedFacts;

  @override
  Widget build(BuildContext context) {
    final restsOn = finding.sources.map((s) => s.label).toList(growable: false);
    return Semantics(
      container: true,
      label: [
        finding.kind.label,
        finding.statement,
        if (restsOn.isNotEmpty) 'Rests on ${restsOn.join(', ')}',
        for (final fact in citedFacts) '${fact.label}: ${fact.value}',
      ].join('. '),
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: MallStatusPill(
                label: finding.kind.label,
                tone: _toneFor(finding.kind),
                icon: _glyphFor(finding.kind),
                dense: true,
              ),
            ),
            const SizedBox(height: DesignTokens.s8),
            // Verbatim. The client never rewords a finding.
            Text(finding.statement, style: _statementStyle),
            if (restsOn.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s6),
              Text('Rests on: ${restsOn.join(' · ')}', style: _footnoteStyle),
            ],
            for (final fact in citedFacts) ...[
              const SizedBox(height: DesignTokens.s6),
              _FactRow(fact: fact),
            ],
          ],
        ),
      ),
    );
  }
}

/// A cited fact: what was recorded, what it said, and when it was observed.
class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final ReturnEvidenceFact fact;

  @override
  Widget build(BuildContext context) {
    final observed = fact.observedUtc;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.only(top: 5, end: DesignTokens.s8),
          child: Icon(
            Icons.subdirectory_arrow_right_rounded,
            size: 13,
            color: DesignTokens.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            [
              '${fact.label}: ${fact.value}',
              if (observed != null) '(${_formatNptDate(observed)})',
            ].join(' '),
            style: _factStyle,
          ),
        ),
      ],
    );
  }
}

/// Whether a source had anything to say.
///
/// A source that could not be read is not a source that found nothing, so an
/// unavailable source always states why.
class _SourceRow extends StatelessWidget {
  const _SourceRow({required this.source});

  final ReturnEvidenceSource source;

  @override
  Widget build(BuildContext context) {
    final state = source.available ? 'Recorded' : 'Not available';
    final detail = source.detail?.trim();
    final reason = source.available
        ? detail
        : (detail == null || detail.isEmpty ? _noReason : detail);
    return Semantics(
      container: true,
      label: [source.kind.label, state, ?reason].join('. '),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                top: 3,
                end: DesignTokens.s8,
              ),
              child: Icon(
                source.available
                    ? Icons.fact_check_outlined
                    : Icons.visibility_off_outlined,
                size: 15,
                color: DesignTokens.textMuted,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${source.kind.label} · $state', style: _factStyle),
                  if (reason != null && reason.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(reason, style: _footnoteStyle),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tone carries emphasis only. The glyph and the word carry the meaning, so
/// the two kinds stay apart in greyscale.
MallStatusTone _toneFor(ReturnEvidenceFindingKind kind) => switch (kind) {
  ReturnEvidenceFindingKind.discrepancy => MallStatusTone.caution,
  ReturnEvidenceFindingKind.corroboration => MallStatusTone.success,
  // A kind this build has never heard of: shown plainly, never guessed at.
  ReturnEvidenceFindingKind.unknown => MallStatusTone.neutral,
};

IconData _glyphFor(ReturnEvidenceFindingKind kind) => switch (kind) {
  // Two offset shapes — "these do not line up".
  ReturnEvidenceFindingKind.discrepancy => Icons.difference_outlined,
  // A double tick — "more than one record says the same".
  ReturnEvidenceFindingKind.corroboration => Icons.done_all_rounded,
  ReturnEvidenceFindingKind.unknown => Icons.help_outline_rounded,
};

const String _sectionLabel = 'What the records show';
const String _sourcesLabel = 'Where this came from';
const String _blurb =
    'Recorded when this return was opened. Shown the same way to the '
    'customer and the seller.';
const String _noReason = 'No reason was recorded.';

const TextStyle _bodyStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 12.5,
  height: 1.45,
  color: DesignTokens.textMuted,
);

const TextStyle _statementStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 13.5,
  height: 1.45,
  color: DesignTokens.textWhite,
);

const TextStyle _factStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 12.5,
  height: 1.4,
  color: DesignTokens.textLight,
);

const TextStyle _footnoteStyle = TextStyle(
  fontFamily: DesignTokens.fontFamily,
  fontSize: 11.5,
  height: 1.4,
  color: DesignTokens.textMuted,
);

// Nepal Time is a fixed UTC+05:45 with no daylight saving, so a constant
// offset is exact without loading the timezone database.
const Duration _nptOffset = Duration(hours: 5, minutes: 45);

DateTime _toKathmandu(DateTime instant) => instant.toUtc().add(_nptOffset);

String _formatNptDateTime(DateTime instant) =>
    DateFormat('d MMM yyyy, h:mm a').format(_toKathmandu(instant));

String _formatNptDate(DateTime instant) =>
    DateFormat('d MMM yyyy').format(_toKathmandu(instant));
