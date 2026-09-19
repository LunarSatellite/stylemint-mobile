/// Wire shapes for "Condition and tamper assurance" —
/// `GET /v1/deliveries/{trackingNumber}/condition-assurance`.
///
/// The buyer endpoint and the vendor twin return the **identical** document,
/// which is the whole point: there is no version of this record that one side
/// sees and the other does not.
///
/// ## Four states, and why the fourth exists
///
/// The backend refuses to reduce condition evidence to a number, and so does
/// this file. `PackageConditionAssuranceDto` carries no score, no confidence,
/// no probability and no rating, and nothing here derives one. What it carries
/// is a [ConditionEvidenceState] per control:
///
/// * [ConditionEvidenceState.notRecorded] — absence of evidence. Neither an
///   accusation nor an exoneration. A missing seal record is not a broken
///   seal.
/// * [ConditionEvidenceState.consistentWithIntegrity] — every record says
///   undisturbed. Consistency, not proof.
/// * [ConditionEvidenceState.consistentWithCompromise] — at least one record
///   says disturbed. A record of what somebody saw, never a finding that
///   anybody tampered.
/// * [ConditionEvidenceState.inconclusive] — records exist and cannot settle
///   it, either because a reading was indeterminate or because two records
///   disagree.
///
/// The fourth state is the one that keeps the other three honest, and it must
/// never be folded into [ConditionEvidenceState.consistentWithCompromise]: a
/// contradiction between two records is not evidence of tampering. Nobody gets
/// accused by arithmetic here.
///
/// ## Unknown values
///
/// A state this app does not recognise becomes
/// [ConditionEvidenceState.unrecognised], never `consistentWithIntegrity`.
/// Degrading toward the *favourable* reading
/// would let a server-side state that means something worse arrive looking
/// like a clean bill of health. The server's own [ConditionControl.statement]
/// is still rendered verbatim, so the reader loses nothing.
library;

/// What the recorded evidence for one control amounts to. Backend
/// `ConditionEvidenceState`, on the wire as the camelCase `state` string.
enum ConditionEvidenceState {
  notRecorded('notRecorded'),
  consistentWithIntegrity('consistentWithIntegrity'),
  consistentWithCompromise('consistentWithCompromise'),
  inconclusive('inconclusive'),

  /// A state this build does not know. Deliberately its own value, and
  /// deliberately not a synonym for anything reassuring.
  unrecognised('');

  const ConditionEvidenceState(this.wire);

  final String wire;

  static ConditionEvidenceState fromWire(String? value) {
    if (value == null || value.isEmpty) return unrecognised;
    for (final state in values) {
      if (state != unrecognised && state.wire == value) return state;
    }
    return unrecognised;
  }
}

/// What one finding is. Backend `KindRecordedObservation` /
/// `KindContradiction` / `KindEvidenceGap`.
enum ConditionFindingKind {
  recordedObservation('recordedObservation'),
  contradiction('contradiction'),
  evidenceGap('evidenceGap'),
  unrecognised('');

  const ConditionFindingKind(this.wire);

  final String wire;

  static ConditionFindingKind fromWire(String? value) {
    if (value == null || value.isEmpty) return unrecognised;
    for (final kind in values) {
      if (kind != unrecognised && kind.wire == value) return kind;
    }
    return unrecognised;
  }
}

/// One control, and what the record amounts to for it.
class ConditionControl {
  const ConditionControl({
    required this.control,
    required this.required_,
    required this.state,
    required this.statement,
    this.citedFactKeys = const <String>[],
  });

  factory ConditionControl.fromJson(Map<String, dynamic> json) =>
      ConditionControl(
        control: (json['control'] as String? ?? '').trim(),
        required_: json['required'] as bool? ?? false,
        state: ConditionEvidenceState.fromWire(json['state'] as String?),
        // Rendered verbatim wherever it is shown. These sentences were
        // written to be read by both parties and rephrasing one is how an
        // accusation gets made by accident.
        statement: (json['statement'] as String? ?? '').trim(),
        citedFactKeys: _stringList(json['citedFactKeys']),
      );

  final String control;

  /// Named with a trailing underscore because `required` is a Dart keyword.
  final bool required_;
  final ConditionEvidenceState state;
  final String statement;
  final List<String> citedFactKeys;
}

/// One recorded fact, attributed to whatever recorded it.
///
/// [attested] is the field that carries the difference this platform can
/// actually stand behind. There is no sensor anywhere in StyleMint:
/// temperature, humidity and shock reach the platform only when a person
/// reads an indicator and types what they saw. An attested fact came out of
/// the signed custody chain; everything else is somebody's typing, and the UI
/// says which is which rather than letting the reader assume.
class ConditionFact {
  const ConditionFact({
    required this.source,
    required this.key,
    required this.label,
    required this.value,
    required this.attested,
    this.observedUtc,
  });

  factory ConditionFact.fromJson(Map<String, dynamic> json) => ConditionFact(
    source: (json['source'] as String? ?? '').trim(),
    key: (json['key'] as String? ?? '').trim(),
    label: (json['label'] as String? ?? '').trim(),
    value: (json['value'] as String? ?? '').trim(),
    // Absent means not attested. A fact whose provenance did not arrive is
    // never promoted to a signed one.
    attested: json['attested'] as bool? ?? false,
    observedUtc: DateTime.tryParse(json['observedUtc'] as String? ?? ''),
  );

  final String source;
  final String key;
  final String label;
  final String value;
  final bool attested;
  final DateTime? observedUtc;
}

/// Something the record plainly says, with the facts it rests on.
class ConditionFinding {
  const ConditionFinding({
    required this.code,
    required this.kind,
    required this.statement,
    this.sources = const <String>[],
    this.citedFactKeys = const <String>[],
  });

  factory ConditionFinding.fromJson(Map<String, dynamic> json) =>
      ConditionFinding(
        code: (json['code'] as String? ?? '').trim(),
        kind: ConditionFindingKind.fromWire(json['kind'] as String?),
        statement: (json['statement'] as String? ?? '').trim(),
        sources: _stringList(json['sources']),
        citedFactKeys: _stringList(json['citedFactKeys']),
      );

  final String code;
  final ConditionFindingKind kind;
  final String statement;
  final List<String> sources;
  final List<String> citedFactKeys;
}

/// A required control this platform cannot evidence, said out loud.
///
/// This exists so a *requirement* is never read as a *capability*. Somebody
/// configured a temperature indicator for this consignment; nothing on this
/// platform reports one.
class ConditionUnsupportedControl {
  const ConditionUnsupportedControl({
    required this.control,
    required this.reason,
  });

  factory ConditionUnsupportedControl.fromJson(Map<String, dynamic> json) =>
      ConditionUnsupportedControl(
        control: (json['control'] as String? ?? '').trim(),
        reason: (json['reason'] as String? ?? '').trim(),
      );

  final String control;
  final String reason;
}

/// The whole document, as both buyer and seller receive it.
class ConditionAssurance {
  const ConditionAssurance({
    required this.trackingNumber,
    required this.hasRequirements,
    required this.hasObservations,
    this.collectedUtc,
    this.controls = const <ConditionControl>[],
    this.facts = const <ConditionFact>[],
    this.findings = const <ConditionFinding>[],
    this.notSupported = const <ConditionUnsupportedControl>[],
  });

  factory ConditionAssurance.fromJson(Map<String, dynamic> json) =>
      ConditionAssurance(
        trackingNumber: (json['trackingNumber'] as String? ?? '').trim(),
        hasRequirements: json['hasRequirements'] as bool? ?? false,
        hasObservations: json['hasObservations'] as bool? ?? false,
        collectedUtc: DateTime.tryParse(json['collectedUtc'] as String? ?? ''),
        controls: _mapList(json['controls'], ConditionControl.fromJson),
        facts: _mapList(json['facts'], ConditionFact.fromJson),
        findings: _mapList(json['findings'], ConditionFinding.fromJson),
        notSupported: _mapList(
          json['notSupported'],
          ConditionUnsupportedControl.fromJson,
        ),
      );

  final String trackingNumber;

  /// False when nobody configured any control for this consignment.
  final bool hasRequirements;

  /// False when nothing at all was recorded — an ordinary parcel, not a red
  /// flag.
  final bool hasObservations;

  final DateTime? collectedUtc;
  final List<ConditionControl> controls;
  final List<ConditionFact> facts;
  final List<ConditionFinding> findings;
  final List<ConditionUnsupportedControl> notSupported;

  /// Nothing configured, nothing recorded and nothing to say. The card then
  /// renders nothing at all rather than an empty shell that reads as a
  /// finding about the parcel.
  bool get isEmpty =>
      controls.isEmpty && findings.isEmpty && notSupported.isEmpty;

  /// The facts one control cites, in the order the server returned them.
  List<ConditionFact> factsFor(ConditionControl control) {
    if (control.citedFactKeys.isEmpty) return const <ConditionFact>[];
    final wanted = control.citedFactKeys.toSet();
    return facts
        .where((fact) => wanted.contains(fact.key))
        .toList(
          growable: false,
        );
  }
}

List<String> _stringList(Object? raw) =>
    (raw as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

List<T> _mapList<T>(Object? raw, T Function(Map<String, dynamic>) build) =>
    (raw as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(build)
        .toList(growable: false);
