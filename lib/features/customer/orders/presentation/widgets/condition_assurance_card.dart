import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/condition_assurance.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/kathmandu_time.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/mall/mall_status.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// "Condition and tamper assurance" on order detail, directly under the
/// chain-of-custody proof the customer is already reading.
///
/// ## Every sentence here belongs to the server
///
/// The control statements, the findings and the reasons under "not supported"
/// are rendered **verbatim**. They were written precisely — "It is not proof
/// that nobody opened it", "it is not a finding that this parcel was tampered
/// with… a person decides what happens next" — and paraphrasing one is
/// exactly how an accusation gets made by accident. This file adds a short
/// label and a glyph per state and otherwise gets out of the way.
///
/// ## Four states, four glyphs, and one that must not slide
///
/// [ConditionEvidenceState.inconclusive] never collapses toward
/// [ConditionEvidenceState.consistentWithCompromise]. It gets its own word
/// ("Checked, still unsettled"), its own glyph (a question mark) and a
/// neutral tone, because records that disagree are not evidence of tampering.
/// That fourth state exists so nobody gets accused by arithmetic, and a UI
/// that painted it the same red as a disturbed seal would undo the whole
/// capability.
///
/// [ConditionEvidenceState.unrecognised] — a state from a newer server —
/// reads as unrecognised, never as integrity. Degrading toward the
/// favourable reading is the one direction that can mislead.
///
/// ## Attested versus typed
///
/// There is no sensor anywhere on this platform. Temperature, humidity and
/// shock reach StyleMint only when a person reads an indicator and types what
/// they saw. So every fact carries its provenance in words and in a glyph:
/// "Signed into the custody chain" for [ConditionFact.attested], "Typed in by
/// a person" for everything else.
///
/// ## What this never says
///
/// No trust score, no tamper probability, no condition rating, no "N of M
/// controls clear". None of those exist on the server and none may be derived
/// here. The counts the server holds stay in the server's own sentences.
class ConditionAssuranceCard extends ConsumerWidget {
  const ConditionAssuranceCard({required this.trackingNumber, super.key});

  final String trackingNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assurance = ref
        .watch(conditionAssuranceProvider(trackingNumber))
        .asData
        ?.value;
    // Nothing configured, nothing recorded, still loading, or an unavailable
    // endpoint: nothing renders. An absent card is not "notRecorded" — it is
    // the app declining to say anything it did not read.
    if (assurance == null || assurance.isEmpty) return const SizedBox.shrink();
    return ConditionAssuranceView(assurance: assurance);
  }
}

/// The card itself, separated from the read so it can be rendered from a
/// fixture in tests.
class ConditionAssuranceView extends StatelessWidget {
  const ConditionAssuranceView({required this.assurance, super.key});

  final ConditionAssurance assurance;

  @override
  Widget build(BuildContext context) {
    if (assurance.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      // Without this the per-control pills are swallowed into one long card
      // label and a screen-reader user hears four outcomes as a run-on
      // sentence instead of four focusable statements.
      explicitChildNodes: true,
      label: 'Condition and tamper record for this parcel.',
      child: Container(
        // The leading gap is the card's own, so a parcel with no condition
        // record leaves no trace on order detail at all.
        margin: const EdgeInsets.only(top: DesignTokens.s16),
        padding: const EdgeInsets.all(DesignTokens.s16),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBodyLight,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Condition and tamper record', style: DesignTokens.h3),
            const SizedBox(height: DesignTokens.s4),
            const Text(
              'What was recorded about this parcel on its way to you, and by '
              'whom. Your seller sees this same record, word for word.',
              style: DesignTokens.smallDescription,
            ),
            const SizedBox(height: DesignTokens.s12),
            const _NoSensorsNote(),
            for (final control in assurance.controls) ...[
              const SizedBox(height: DesignTokens.s16),
              _ControlBlock(
                control: control,
                facts: assurance.factsFor(control),
              ),
            ],
            if (assurance.findings.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s20),
              _FindingsBlock(findings: assurance.findings),
            ],
            if (assurance.notSupported.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.s20),
              _NotSupportedBlock(entries: assurance.notSupported),
            ],
          ],
        ),
      ),
    );
  }
}

/// The standing caveat, above everything. It is not a finding about this
/// parcel; it is what the platform is able to know at all.
class _NoSensorsNote extends StatelessWidget {
  const _NoSensorsNote();

  static const String _text =
      'Nothing on StyleMint measures a parcel. Seals, temperature, humidity '
      'and shock are recorded only when a person reads an indicator and types '
      'what they saw.';

  @override
  Widget build(BuildContext context) => Semantics(
    label: _text,
    excludeSemantics: true,
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: DesignTokens.iconSmall,
          color: DesignTokens.textMuted,
        ),
        SizedBox(width: DesignTokens.s8),
        Expanded(child: Text(_text, style: DesignTokens.smallDescription)),
      ],
    ),
  );
}

/// One control: its name, its state as a glyph and a word, the server's own
/// sentence, and the facts it cites.
class _ControlBlock extends StatelessWidget {
  const _ControlBlock({required this.control, required this.facts});

  final ConditionControl control;
  final List<ConditionFact> facts;

  @override
  Widget build(BuildContext context) {
    final copy = conditionStateCopy(control.state);
    final name = conditionControlLabel(control.control);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: '$name. ${copy.semanticSummary}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: DesignTokens.mediumSemibold),
          if (control.required_) ...[
            const SizedBox(height: DesignTokens.s4),
            const Text(
              'Required for this consignment.',
              style: DesignTokens.tiny,
            ),
          ],
          const SizedBox(height: DesignTokens.s8),
          // Aligned start rather than spaced apart, so a long label at 1.3×
          // wraps inside the pill instead of fighting a sibling for the row.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: MallStatusPill(
              label: copy.pillLabel,
              tone: copy.tone,
              icon: copy.glyph,
              semanticLabel: copy.semanticSummary,
            ),
          ),
          if (control.statement.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            // Verbatim. Never trimmed to a summary, never re-worded.
            Text(control.statement, style: DesignTokens.smallDescription),
          ],
          if (facts.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s8),
            for (final fact in facts) _FactRow(fact: fact),
          ],
        ],
      ),
    );
  }
}

/// One cited fact, with where it came from said out loud.
class _FactRow extends StatelessWidget {
  const _FactRow({required this.fact});

  final ConditionFact fact;

  @override
  Widget build(BuildContext context) {
    final provenance = conditionProvenanceCopy(attested: fact.attested);
    final observed = fact.observedUtc;
    final label = fact.label.isEmpty ? fact.key : fact.label;
    return Semantics(
      label: [
        '$label: ${fact.value}',
        provenance.semanticSummary,
        if (observed != null) 'Recorded ${formatNptDateTime(observed)}',
      ].join('. '),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: DesignTokens.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label: ${fact.value}', style: DesignTokens.small),
            const SizedBox(height: DesignTokens.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  provenance.glyph,
                  size: DesignTokens.iconSmall,
                  color: DesignTokens.textMuted,
                ),
                const SizedBox(width: DesignTokens.s6),
                Expanded(
                  child: Text(
                    observed == null
                        ? provenance.label
                        : '${provenance.label} · '
                              '${formatNptDateTime(observed)}',
                    style: DesignTokens.tiny,
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

/// The findings, each in the server's own words with its kind named.
class _FindingsBlock extends StatelessWidget {
  const _FindingsBlock({required this.findings});

  final List<ConditionFinding> findings;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('What the record says', style: DesignTokens.mediumSemibold),
      for (final finding in findings) _FindingRow(finding: finding),
    ],
  );
}

class _FindingRow extends StatelessWidget {
  const _FindingRow({required this.finding});

  final ConditionFinding finding;

  @override
  Widget build(BuildContext context) {
    final copy = conditionFindingCopy(finding.kind);
    return Semantics(
      container: true,
      label: '${copy.semanticSummary} ${finding.statement}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(top: DesignTokens.s12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              copy.glyph,
              size: DesignTokens.iconSmall,
              color: DesignTokens.textMuted,
            ),
            const SizedBox(width: DesignTokens.s8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(copy.label, style: DesignTokens.tiny),
                  const SizedBox(height: DesignTokens.s4),
                  // Verbatim, including the sentences that say what the
                  // finding is *not*.
                  Text(finding.statement, style: DesignTokens.smallDescription),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Required controls this platform has no feed for.
///
/// Printed in full so a requirement somebody configured is never mistaken for
/// a capability the platform has.
class _NotSupportedBlock extends StatelessWidget {
  const _NotSupportedBlock({required this.entries});

  final List<ConditionUnsupportedControl> entries;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: 'Required, but StyleMint cannot evidence it.',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Required, but StyleMint cannot evidence it',
          style: DesignTokens.mediumSemibold,
        ),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.s12),
            child: Semantics(
              label:
                  '${conditionControlLabel(entry.control)}. '
                  'Not supported. ${entry.reason}',
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
                          conditionControlLabel(entry.control),
                          style: DesignTokens.small,
                        ),
                        const SizedBox(height: DesignTokens.s4),
                        // Verbatim.
                        Text(
                          entry.reason,
                          style: DesignTokens.smallDescription,
                        ),
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

/// The wording, glyph and tone for one evidence state.
typedef ConditionStateCopy = ({
  String pillLabel,
  IconData glyph,
  MallStatusTone tone,
  String semanticSummary,
});

/// Four states, four glyphs, four sentences — and none of them a number.
///
/// The glyphs are deliberately different *shapes*, not merely different
/// colours: a dash, a tick, a warning triangle and a question mark stay apart
/// in greyscale, under a colour-blind palette and at a glance.
///
/// [ConditionEvidenceState.consistentWithCompromise] draws the caution tone
/// rather than the danger tone on purpose. Danger is the app saying something
/// went wrong; this state is the app saying somebody wrote down that a seal
/// looked disturbed. The server's sentence, printed beside it, carries the
/// rest.
///
/// [ConditionEvidenceState.inconclusive] and
/// [ConditionEvidenceState.notRecorded] share the neutral tone and are told
/// apart by glyph and word, which is the correct carrier: "nobody checked"
/// and "somebody checked and could not tell" are both silence about the
/// parcel, and neither is a step toward compromise.
ConditionStateCopy conditionStateCopy(ConditionEvidenceState state) =>
    switch (state) {
      ConditionEvidenceState.notRecorded => (
        pillLabel: 'Nothing recorded',
        glyph: Icons.horizontal_rule_rounded,
        tone: MallStatusTone.neutral,
        semanticSummary:
            'Nothing recorded. This is an absence of evidence — neither an '
            'accusation nor an exoneration.',
      ),
      ConditionEvidenceState.consistentWithIntegrity => (
        pillLabel: 'Records say undisturbed',
        glyph: Icons.check_circle_outline_rounded,
        tone: MallStatusTone.success,
        semanticSummary:
            'Every record says undisturbed. That is consistency, not proof.',
      ),
      ConditionEvidenceState.consistentWithCompromise => (
        pillLabel: 'Recorded as disturbed',
        glyph: Icons.report_problem_outlined,
        tone: MallStatusTone.caution,
        semanticSummary:
            'Recorded as disturbed. That is what somebody saw and wrote down, '
            'not a finding that this parcel was tampered with.',
      ),
      ConditionEvidenceState.inconclusive => (
        pillLabel: 'Checked, still unsettled',
        glyph: Icons.help_outline_rounded,
        tone: MallStatusTone.neutral,
        semanticSummary:
            'Checked, and the records do not settle it. This is not evidence '
            'of tampering and it counts against nobody.',
      ),
      // A state this build does not know. It reads as unrecognised and never
      // as integrity: the one direction a fallback must not go is the
      // reassuring one.
      ConditionEvidenceState.unrecognised => (
        pillLabel: 'State not recognised',
        glyph: Icons.help_outline_rounded,
        tone: MallStatusTone.neutral,
        semanticSummary:
            'This record uses a state this version of the app does not '
            'recognise. Nothing is assumed either way; the record is shown '
            'exactly as it arrived.',
      ),
    };

/// How a fact reached the platform, in a word and a glyph.
///
/// The distinction is real and small: a signed custody entry was sealed into
/// a hash chain at the moment it happened, while everything else is a person
/// typing. Neither is dismissed here — one is simply said to be signed and
/// the other is said to be typed.
({String label, IconData glyph, String semanticSummary})
conditionProvenanceCopy({required bool attested}) => attested
    ? (
        label: 'Signed into the custody chain',
        glyph: Icons.lock_outline_rounded,
        semanticSummary:
            'Attested: signed into the custody chain when it happened.',
      )
    : (
        label: 'Typed in by a person',
        glyph: Icons.edit_note_outlined,
        semanticSummary:
            'Typed in by a person. Not signed, and not measured by any device.',
      );

/// What one finding is, named before it is read.
({String label, IconData glyph, String semanticSummary}) conditionFindingCopy(
  ConditionFindingKind kind,
) => switch (kind) {
  ConditionFindingKind.recordedObservation => (
    label: 'Recorded observation',
    glyph: Icons.visibility_outlined,
    semanticSummary: 'Recorded observation.',
  ),
  ConditionFindingKind.contradiction => (
    label: 'Records disagree',
    glyph: Icons.compare_arrows_rounded,
    semanticSummary: 'Records disagree. This counts against neither party.',
  ),
  ConditionFindingKind.evidenceGap => (
    label: 'Gap in the evidence',
    glyph: Icons.horizontal_rule_rounded,
    semanticSummary: 'A gap in the evidence, not a finding about anybody.',
  ),
  ConditionFindingKind.unrecognised => (
    label: 'Recorded on this parcel',
    glyph: Icons.notes_rounded,
    semanticSummary: 'Recorded on this parcel.',
  ),
};

/// Human-facing name for one control key.
///
/// An unknown key falls through to the key itself rather than being hidden: a
/// control the customer cannot see is worse than one labelled awkwardly.
String conditionControlLabel(String control) => switch (control) {
  'seal' => 'Tamper seal',
  'temperatureIndicator' => 'Temperature indicator',
  'shockIndicator' => 'Shock indicator',
  'humidityIndicator' => 'Humidity indicator',
  'routeEvent' => 'Route event',
  _ => control.isEmpty ? 'Control' : control,
};
