import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';

/// Wire → domain for backend `ProductPassport`.
///
/// Two endpoints return this exact shape: the listing passport at
/// `GET v1/public/products/{id}/passport` and the per-unit passport at
/// `GET v1/public/unit-passports/{unitMarkerId}`. One mapper serves both so
/// the two can never drift apart — a unit passport that mapped `subject`
/// differently from a listing passport is precisely the bug class this
/// codebase keeps finding.
ProductPassport productPassportFromJson(Map<String, dynamic> json) =>
    ProductPassport(
      vendorBusinessName: json['vendorBusinessName'] as String? ?? '',
      vendorIdentityVerified: json['vendorIdentityVerified'] as bool? ?? false,
      vendorOnPlatformSince: json['vendorOnPlatformSinceUtc'] != null
          ? DateTime.tryParse(json['vendorOnPlatformSinceUtc'] as String)
          : null,
      authenticityStatement: json['authenticityStatement'] as String? ?? '',
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      revision: json['revision'] as String? ?? '',
      generatedAt: DateTime.tryParse(json['generatedUtc'] as String? ?? ''),
      provenance: (json['provenance'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (fact) => ProductProvenanceFact(
              key: fact['key'] as String? ?? '',
              label: fact['label'] as String? ?? '',
              value: fact['value'] as String? ?? '',
              verified: fact['verified'] as bool? ?? false,
              observedAt: DateTime.tryParse(
                fact['observedUtc'] as String? ?? '',
              ),
            ),
          )
          .where((fact) => fact.label.isNotEmpty && fact.value.isNotEmpty)
          .toList(growable: false),
      subject: passportSubjectFromJson(json['subject']),
      claims: (json['claims'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(passportClaimFromJson)
          // A claim with no words in it is not a claim. It is dropped rather
          // than rendered as an empty attributed line.
          .where((claim) => claim.statement.isNotEmpty)
          .toList(growable: false),
      coverage: passportCoverageFromJson(json['coverage']),
    );

/// Passport schema 2 — `subject`. Absent on a v1 payload, and absent means
/// the app says nothing about scope rather than assuming one.
///
/// `scope` is read as the **name** the server sends — `"Listing"`, `"Batch"`
/// or `"Unit"`. It is kept as the raw string on purpose: the app branches on
/// `identifiesPhysicalUnit`, which is the field that actually answers the
/// question a reader has, and a scope this build has not heard of must not
/// be guessed at.
PassportSubject? passportSubjectFromJson(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final explanation = passportNonEmpty(raw['scopeExplanation']);
  return PassportSubject(
    scope: passportNonEmpty(raw['scope']) ?? '',
    scopeExplanation: explanation ?? '',
    // Absent defaults to false, which is the safe direction: a passport is
    // never assumed to identify a physical item.
    identifiesPhysicalUnit: raw['identifiesPhysicalUnit'] as bool? ?? false,
    serialOrBatchNumber: passportNonEmpty(raw['serialOrBatchNumber']),
  );
}

/// Passport schema 2 — one `claims[]` entry.
///
/// `presentAsFact` is read straight off the wire and defaults to **false**
/// when it is missing. That default is the whole safety property: a claim the
/// app cannot confirm the platform verified is shown as somebody's statement,
/// never as the platform's own.
PassportClaim passportClaimFromJson(Map<String, dynamic> raw) {
  final assurance = PassportAssurance.fromJson(raw['assurance']);
  return PassportClaim(
    claimId: passportNonEmpty(raw['claimId']) ?? '',
    kindLabel: passportNonEmpty(raw['kindLabel']) ?? '',
    statement: passportNonEmpty(raw['statement']) ?? '',
    assurance: assurance,
    assuranceLabel: passportNonEmpty(raw['assuranceLabel']) ?? '',
    presentAsFact:
        (raw['presentAsFact'] as bool? ?? false) &&
        assurance == PassportAssurance.verified,
    issuerName: passportNonEmpty(raw['issuerName']) ?? '',
    isInEffect: raw['isInEffect'] as bool? ?? false,
    issuerReference: passportNonEmpty(raw['issuerReference']),
    verificationMethod: passportNonEmpty(raw['verificationMethod']),
    verificationNote: passportNonEmpty(raw['verificationNote']),
    verifiedAt: DateTime.tryParse(raw['verifiedUtc'] as String? ?? ''),
    recordedAt: DateTime.tryParse(raw['recordedUtc'] as String? ?? ''),
  );
}

/// Passport schema 2 — `coverage`.
PassportCoverage? passportCoverageFromJson(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  return PassportCoverage(
    knownKinds: _kindList(raw['knownKinds']),
    unknownKinds: _kindList(raw['unknownKinds']),
    summary: passportNonEmpty(raw['summary']) ?? '',
  );
}

/// A trimmed string, or null when there were no words in it. Null is what
/// makes an absent field render as absent instead of as an empty label.
String? passportNonEmpty(Object? raw) {
  final value = raw is String ? raw.trim() : null;
  return (value == null || value.isEmpty) ? null : value;
}

List<String> _kindList(Object? raw) =>
    (raw as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
