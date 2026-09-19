/// The returns **evidence snapshot**: what the platform already knew about
/// this item and this delivery at the moment the return was opened.
///
/// It lives in `shared/` on purpose. The buyer and the seller are shown the
/// *same* snapshot, worded the same way — when a return is disputed the whole
/// value of this surface is that both sides are arguing from one set of facts
/// rather than from memory. A role-specific summary would destroy that.
///
/// Deliberately **not** a score. The backend exposes no number, no band and no
/// ratio, and nothing here may derive one: no count of findings, no
/// "confidence", no progress bar, no ordering that implies severity. Findings
/// are rendered in the order the backend sent them.
///
/// The whole object is absent or null on returns that predate the feature.
/// That is the ordinary case and says nothing at all about the return.
library;

/// Which capability recorded a fact. [unknown] carries a value a newer backend
/// introduced, so an unrecognised source degrades to a plain row instead of
/// throwing.
enum ReturnEvidenceSourceKind {
  scanToReceive('scanToReceive', 'Scan to receive'),
  chainOfCustody('chainOfCustody', 'Chain of custody'),
  productPassport('productPassport', 'Product passport'),
  unknown('', 'Other record');

  const ReturnEvidenceSourceKind(this.wire, this.label);

  /// Exactly as it appears on the wire.
  final String wire;

  /// Human name, used identically on both roles' screens.
  final String label;

  static ReturnEvidenceSourceKind fromWire(String? wire) =>
      ReturnEvidenceSourceKind.values.firstWhere(
        (s) => s.wire.isNotEmpty && s.wire == wire,
        orElse: () => unknown,
      );
}

/// Whether a finding weighs against the return as stated or supports it.
///
/// Never a verdict: both kinds are shown, in the backend's words, and a person
/// still decides. [unknown] absorbs a future kind rather than crashing.
enum ReturnEvidenceFindingKind {
  discrepancy('discrepancy', 'Discrepancy'),
  corroboration('corroboration', 'Corroboration'),
  unknown('', 'Finding');

  const ReturnEvidenceFindingKind(this.wire, this.label);

  final String wire;

  /// The kind as a word — screen readers get this, not a colour.
  final String label;

  static ReturnEvidenceFindingKind fromWire(String? wire) =>
      ReturnEvidenceFindingKind.values.firstWhere(
        (k) => k.wire.isNotEmpty && k.wire == wire,
        orElse: () => unknown,
      );
}

/// Whether a source had anything to say, so absence reads as absence.
///
/// A source that could not be read is not a source that found nothing —
/// [detail] says which, and the UI must state it.
class ReturnEvidenceSource {
  const ReturnEvidenceSource({
    required this.kind,
    required this.available,
    this.detail,
  });

  final ReturnEvidenceSourceKind kind;
  final bool available;
  final String? detail;
}

/// One fact, attributed to the capability that recorded it.
class ReturnEvidenceFact {
  const ReturnEvidenceFact({
    required this.kind,
    required this.key,
    required this.label,
    required this.value,
    this.observedUtc,
  });

  final ReturnEvidenceSourceKind kind;

  /// Stable identifier a finding cites in
  /// [ReturnEvidenceFinding.citedFactKeys].
  final String key;
  final String label;
  final String value;
  final DateTime? observedUtc;
}

/// Something the evidence plainly says, with the facts it rests on.
///
/// [statement] is written by the backend and is rendered verbatim. The client
/// does not rephrase it, does not summarise it and adds no language of blame
/// or outcome around it.
class ReturnEvidenceFinding {
  const ReturnEvidenceFinding({
    required this.code,
    required this.kind,
    required this.statement,
    this.sources = const <ReturnEvidenceSourceKind>[],
    this.citedFactKeys = const <String>[],
  });

  final String code;
  final ReturnEvidenceFindingKind kind;
  final String statement;
  final List<ReturnEvidenceSourceKind> sources;
  final List<String> citedFactKeys;
}

/// The snapshot, taken once at submission and never recomputed.
class ReturnEvidence {
  const ReturnEvidence({
    required this.collectedUtc,
    required this.hasEvidence,
    required this.hasDiscrepancy,
    this.sources = const <ReturnEvidenceSource>[],
    this.facts = const <ReturnEvidenceFact>[],
    this.findings = const <ReturnEvidenceFinding>[],
  });

  final DateTime? collectedUtc;

  /// False when nothing was recorded — an older order, not a red flag.
  final bool hasEvidence;

  final bool hasDiscrepancy;
  final List<ReturnEvidenceSource> sources;
  final List<ReturnEvidenceFact> facts;
  final List<ReturnEvidenceFinding> findings;

  /// True when there is genuinely nothing to show.
  ///
  /// Nothing was recorded *and* no source can even explain why, so the surface
  /// renders nothing at all: an empty card or a "no evidence found" line would
  /// make absence look like a claim about the return, which it is not.
  bool get isSilent =>
      (!hasEvidence || (facts.isEmpty && findings.isEmpty)) &&
      sources.every((s) => s.detail == null || s.detail!.trim().isEmpty) &&
      facts.isEmpty &&
      findings.isEmpty;

  /// Facts cited by [finding], in the snapshot's own order.
  List<ReturnEvidenceFact> factsCitedBy(ReturnEvidenceFinding finding) => facts
      .where((f) => finding.citedFactKeys.contains(f.key))
      .toList(growable: false);
}
