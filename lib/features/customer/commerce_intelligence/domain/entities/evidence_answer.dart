import 'package:flutter/foundation.dart';

/// One bitemporally selected fact the backend used to answer a question.
///
/// Every field here is sent by `/v1/customer/commerce-intelligence/answer`.
/// Nothing is derived, scored or inferred on the device — if the backend did
/// not assert it, it is not on this class.
@immutable
class TemporalFact {
  const TemporalFact({
    required this.factId,
    required this.subjectKey,
    required this.kind,
    required this.statement,
    required this.version,
    required this.validFromUtc,
    required this.validToUtc,
    required this.observedUtc,
    required this.source,
    required this.sourceReference,
    required this.confidence,
  });

  /// Opaque server id. Used to join a forecast to the facts it rests on,
  /// never drawn.
  final String factId;

  /// `product:{guid}` today. [productId] reads the id back out when it is.
  final String subjectKey;

  /// Machine token, e.g. `vendor-verification`, `provenance:origin`.
  final String kind;

  /// The human sentence. This is the claim.
  final String statement;

  /// Server revision of the underlying record. Not drawn.
  final int version;

  /// Start of the fact's validity window.
  final DateTime? validFromUtc;

  /// End of the validity window; null means "still open".
  final DateTime? validToUtc;

  /// When the fact was recorded.
  final DateTime? observedUtc;

  /// Producing system, e.g. `catalog.product-passport`.
  final String source;

  /// Backend path the fact came from, e.g. `/v1/public/products/{id}`.
  final String sourceReference;

  /// Backend-asserted confidence in 0..1, or null when it did not send one.
  final double? confidence;

  /// The product this fact is about, when [subjectKey] names one.
  String? get productId =>
      subjectKey.startsWith('product:') && subjectKey.length > 8
      ? subjectKey.substring(8)
      : null;

  /// A fact with nothing to say is not evidence.
  bool get isRenderable => statement.trim().isNotEmpty;
}

/// A forecast the backend attached to the answer, traced back to fact ids.
@immutable
class EvidenceConsequence {
  const EvidenceConsequence({
    required this.subjectKey,
    required this.outcome,
    required this.direction,
    required this.horizonDays,
    required this.probability,
    required this.basis,
    required this.evidenceFactIds,
  });

  final String subjectKey;

  /// The sentence describing what may follow. This is the claim.
  final String outcome;

  /// `risk-increase`, `risk-decrease`, `stable`, or anything future.
  final String direction;

  /// 0 means the forecast carries no horizon.
  final int horizonDays;

  /// Backend-asserted probability in 0..1, or null when absent.
  final double? probability;

  /// What the forecast was computed from.
  final String basis;

  /// Ids of the facts above that this forecast rests on.
  final List<String> evidenceFactIds;

  bool get isRenderable => outcome.trim().isNotEmpty;
}

/// A whole answer: the claim, the evidence under it, and when it was true.
@immutable
class EvidenceAnswer {
  const EvidenceAnswer({
    required this.schemaVersion,
    required this.query,
    required this.asOfUtc,
    required this.answer,
    required this.evidence,
    required this.consequences,
    required this.limitations,
    required this.evidenceDigestSha256,
  });

  /// Contract version. A version this build does not know still renders —
  /// unknown fields are ignored and missing ones fall back.
  final int schemaVersion;

  final String query;

  /// The moment the evidence was selected as-of. Null when the backend did
  /// not send one, in which case no as-of claim is made on screen.
  final DateTime? asOfUtc;

  /// The prose claim. Never shown when [evidence] is empty — see
  /// [hasEvidence].
  final String answer;

  final List<TemporalFact> evidence;
  final List<EvidenceConsequence> consequences;

  /// Backend-authored caveats. Rendered verbatim.
  final List<String> limitations;

  /// Integrity digest over the selected fact ids and forecasts.
  final String evidenceDigestSha256;

  /// The rule this feature exists to enforce: no evidence, no answer.
  bool get hasEvidence => evidence.any((fact) => fact.isRenderable);

  /// Facts named by [ids], in the order the backend listed the evidence.
  List<TemporalFact> factsById(Iterable<String> ids) {
    final wanted = ids.toSet();
    return evidence
        .where((fact) => wanted.contains(fact.factId) && fact.isRenderable)
        .toList(growable: false);
  }
}
