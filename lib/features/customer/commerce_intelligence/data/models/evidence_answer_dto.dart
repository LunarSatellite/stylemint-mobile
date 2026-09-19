import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/entities/evidence_answer.dart';

/// Wire mapping for `POST /v1/customer/commerce-intelligence/answer`.
///
/// Hand-written and deliberately total: every reader below has a defined
/// answer for a missing, null or wrongly-typed value, because the one thing
/// this screen must never do is throw while drawing evidence. Unknown keys
/// are ignored, so a newer `schemaVersion` still renders what this build
/// understands.

String _str(Object? raw) => raw is String ? raw : '';

int _int(Object? raw) => switch (raw) {
  final int value => value,
  final num value => value.toInt(),
  final String value => int.tryParse(value) ?? 0,
  _ => 0,
};

/// Null rather than 0: "the backend sent no number" and "the backend sent
/// zero" are different claims and must not collapse into one.
double? _doubleOrNull(Object? raw) => switch (raw) {
  final double value when value.isFinite => value,
  final int value => value.toDouble(),
  final num value when value.isFinite => value.toDouble(),
  final String value => double.tryParse(value),
  _ => null,
};

DateTime? _utcOrNull(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

List<String> _strings(Object? raw) => raw is List
    ? raw.map(_str).where((value) => value.isNotEmpty).toList(growable: false)
    : const <String>[];

List<Map<String, dynamic>> _objects(Object? raw) => raw is List
    ? raw.whereType<Map<String, dynamic>>().toList(growable: false)
    : const <Map<String, dynamic>>[];

TemporalFact temporalFactFromJson(Map<String, dynamic> json) => TemporalFact(
  factId: _str(json['factId']),
  subjectKey: _str(json['subjectKey']),
  kind: _str(json['kind']),
  statement: _str(json['statement']).trim(),
  version: _int(json['version']),
  validFromUtc: _utcOrNull(json['validFromUtc']),
  validToUtc: _utcOrNull(json['validToUtc']),
  observedUtc: _utcOrNull(json['observedUtc']),
  source: _str(json['source']),
  sourceReference: _str(json['sourceReference']),
  // `valueJson` is the machine payload behind `statement`; it is parsed by
  // nothing here and drawn by nothing here.
  confidence: _doubleOrNull(json['confidence']),
);

EvidenceConsequence consequenceFromJson(Map<String, dynamic> json) =>
    EvidenceConsequence(
      subjectKey: _str(json['subjectKey']),
      outcome: _str(json['outcome']).trim(),
      direction: _str(json['direction']),
      horizonDays: _int(json['horizonDays']),
      probability: _doubleOrNull(json['probability']),
      basis: _str(json['basis']).trim(),
      evidenceFactIds: _strings(json['evidenceFactIds']),
    );

EvidenceAnswer evidenceAnswerFromJson(Map<String, dynamic> json) =>
    EvidenceAnswer(
      schemaVersion: _int(json['schemaVersion']),
      query: _str(json['query']),
      asOfUtc: _utcOrNull(json['asOfUtc']),
      answer: _str(json['answer']).trim(),
      evidence: _objects(json['evidence'])
          .map(temporalFactFromJson)
          .where((fact) => fact.isRenderable)
          .toList(growable: false),
      consequences: _objects(json['consequences'])
          .map(consequenceFromJson)
          .where((forecast) => forecast.isRenderable)
          .toList(growable: false),
      limitations: _strings(json['limitations']),
      evidenceDigestSha256: _str(json['evidenceDigestSha256']),
    );
