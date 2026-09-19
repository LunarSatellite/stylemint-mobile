import 'package:stylemint_mobile_frontend/shared/domain/entities/return_evidence.dart';

/// Wire shape of the returns evidence snapshot, identical on the buyer's
/// `CustomerReturnRequestDto` and the vendor's return DTOs — one parser, so
/// the two roles cannot drift apart.
///
/// Hand-written rather than generated: every field is optional in practice
/// (the object itself is absent on older returns) and unknown `source`/`kind`
/// values must degrade to [ReturnEvidenceSourceKind.unknown] /
/// [ReturnEvidenceFindingKind.unknown] instead of throwing.
class ReturnEvidenceDto {
  const ReturnEvidenceDto({
    required this.collectedUtc,
    required this.hasEvidence,
    required this.hasDiscrepancy,
    required this.sources,
    required this.facts,
    required this.findings,
  });

  factory ReturnEvidenceDto.fromJson(Map<String, dynamic> json) =>
      ReturnEvidenceDto(
        collectedUtc: _date(json['collectedUtc']),
        hasEvidence: json['hasEvidence'] as bool? ?? false,
        hasDiscrepancy: json['hasDiscrepancy'] as bool? ?? false,
        sources: _list(json['sources'], ReturnEvidenceSourceDto.fromJson),
        facts: _list(json['facts'], ReturnEvidenceFactDto.fromJson),
        findings: _list(json['findings'], ReturnEvidenceFindingDto.fromJson),
      );

  /// Parses the `evidence` member wherever it hangs. Returns null for an
  /// absent, null or malformed snapshot — absence is the ordinary case and is
  /// never an error.
  static ReturnEvidenceDto? maybeFromJson(Object? value) =>
      value is Map<String, dynamic> ? ReturnEvidenceDto.fromJson(value) : null;

  final DateTime? collectedUtc;
  final bool hasEvidence;
  final bool hasDiscrepancy;
  final List<ReturnEvidenceSourceDto> sources;
  final List<ReturnEvidenceFactDto> facts;
  final List<ReturnEvidenceFindingDto> findings;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'collectedUtc': collectedUtc?.toIso8601String(),
    'hasEvidence': hasEvidence,
    'hasDiscrepancy': hasDiscrepancy,
    'sources': sources.map((s) => s.toJson()).toList(growable: false),
    'facts': facts.map((f) => f.toJson()).toList(growable: false),
    'findings': findings.map((f) => f.toJson()).toList(growable: false),
  };

  ReturnEvidence toDomain() => ReturnEvidence(
    collectedUtc: collectedUtc,
    hasEvidence: hasEvidence,
    hasDiscrepancy: hasDiscrepancy,
    sources: sources.map((s) => s.toDomain()).toList(growable: false),
    facts: facts.map((f) => f.toDomain()).toList(growable: false),
    findings: findings.map((f) => f.toDomain()).toList(growable: false),
  );
}

class ReturnEvidenceSourceDto {
  const ReturnEvidenceSourceDto({
    required this.source,
    required this.available,
    this.detail,
  });

  factory ReturnEvidenceSourceDto.fromJson(Map<String, dynamic> json) =>
      ReturnEvidenceSourceDto(
        source: json['source'] as String? ?? '',
        available: json['available'] as bool? ?? false,
        detail: json['detail'] as String?,
      );

  final String source;
  final bool available;
  final String? detail;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'source': source,
    'available': available,
    'detail': detail,
  };

  ReturnEvidenceSource toDomain() => ReturnEvidenceSource(
    kind: ReturnEvidenceSourceKind.fromWire(source),
    available: available,
    detail: detail,
  );
}

class ReturnEvidenceFactDto {
  const ReturnEvidenceFactDto({
    required this.source,
    required this.key,
    required this.label,
    required this.value,
    this.observedUtc,
  });

  factory ReturnEvidenceFactDto.fromJson(Map<String, dynamic> json) =>
      ReturnEvidenceFactDto(
        source: json['source'] as String? ?? '',
        key: json['key'] as String? ?? '',
        label: json['label'] as String? ?? '',
        value: json['value'] as String? ?? '',
        observedUtc: _date(json['observedUtc']),
      );

  final String source;
  final String key;
  final String label;
  final String value;
  final DateTime? observedUtc;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'source': source,
    'key': key,
    'label': label,
    'value': value,
    'observedUtc': observedUtc?.toIso8601String(),
  };

  ReturnEvidenceFact toDomain() => ReturnEvidenceFact(
    kind: ReturnEvidenceSourceKind.fromWire(source),
    key: key,
    label: label,
    value: value,
    observedUtc: observedUtc,
  );
}

class ReturnEvidenceFindingDto {
  const ReturnEvidenceFindingDto({
    required this.code,
    required this.kind,
    required this.statement,
    required this.sources,
    required this.citedFactKeys,
  });

  factory ReturnEvidenceFindingDto.fromJson(Map<String, dynamic> json) =>
      ReturnEvidenceFindingDto(
        code: json['code'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        statement: json['statement'] as String? ?? '',
        sources: _strings(json['sources']),
        citedFactKeys: _strings(json['citedFactKeys']),
      );

  final String code;
  final String kind;

  /// Backend-authored. Rendered verbatim; never rephrased on the client.
  final String statement;
  final List<String> sources;
  final List<String> citedFactKeys;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'kind': kind,
    'statement': statement,
    'sources': sources,
    'citedFactKeys': citedFactKeys,
  };

  ReturnEvidenceFinding toDomain() => ReturnEvidenceFinding(
    code: code,
    kind: ReturnEvidenceFindingKind.fromWire(kind),
    statement: statement,
    sources: sources
        .map(ReturnEvidenceSourceKind.fromWire)
        .toList(growable: false),
    citedFactKeys: citedFactKeys,
  );
}

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(parse)
      .toList(growable: false);
}

List<String> _strings(Object? raw) =>
    raw is List ? raw.whereType<String>().toList(growable: false) : const [];

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw) : (raw is DateTime ? raw : null);
