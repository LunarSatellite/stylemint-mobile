import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/handover_delegation.dart';

/// Wire shape of the buyer handover-delegation endpoints
/// (`/v1/deliveries/{trackingNumber}/handover-delegations`), backend
/// `ParcelHandoverDelegationDto`, serialized camelCase. Enums arrive as ints
/// (the backend registers no `JsonStringEnumConverter`); names are accepted
/// too so a later converter change cannot break the app.
class HandoverDelegationDto {
  const HandoverDelegationDto({
    required this.id,
    required this.trackingNumber,
    required this.delegateDisplayName,
    required this.relationship,
    required this.allowedExceptions,
    required this.windowStartUtc,
    required this.windowEndUtc,
    required this.status,
    this.consumedUtc,
    this.revokedUtc,
    this.revocationReason,
    this.createdUtc,
  });

  factory HandoverDelegationDto.fromJson(Map<String, dynamic> json) =>
      HandoverDelegationDto(
        id: _string(json['id']),
        trackingNumber: _string(json['trackingNumber']),
        delegateDisplayName: _string(json['delegateDisplayName']),
        relationship: parseDelegateRelationship(json['relationship']),
        allowedExceptions: _flags(json['allowedExceptions']),
        windowStartUtc: _utc(json['windowStartUtc']),
        windowEndUtc: _utc(json['windowEndUtc']),
        status: parseHandoverDelegationStatus(json['status']),
        consumedUtc: _utcOrNull(json['consumedUtc']),
        revokedUtc: _utcOrNull(json['revokedUtc']),
        revocationReason: _blankToNull(json['revocationReason']),
        createdUtc: _utcOrNull(json['createdUtc']),
      );

  final String id;
  final String trackingNumber;
  final String delegateDisplayName;
  final DelegateRelationship relationship;
  final int allowedExceptions;
  final DateTime windowStartUtc;
  final DateTime windowEndUtc;
  final HandoverDelegationStatus status;
  final DateTime? consumedUtc;
  final DateTime? revokedUtc;
  final String? revocationReason;
  final DateTime? createdUtc;

  HandoverDelegation toDomain() => HandoverDelegation(
    id: id,
    trackingNumber: trackingNumber,
    delegateDisplayName: delegateDisplayName,
    relationship: relationship,
    allowedExceptions: unpackDelegatedExceptions(allowedExceptions),
    windowStartUtc: windowStartUtc,
    windowEndUtc: windowEndUtc,
    status: status,
    consumedUtc: consumedUtc,
    revokedUtc: revokedUtc,
    revocationReason: revocationReason,
    createdUtc: createdUtc,
  );
}

/// Backend `IssuedParcelHandoverDelegationDto`.
///
/// Parsed straight into [IssuedHandoverDelegation] and handed to the caller —
/// there is no DTO field holding the code, so no DTO instance can be cached,
/// serialized or inspected with the code still in it.
IssuedHandoverDelegation parseIssuedHandoverDelegation(
  Map<String, dynamic> json,
) => IssuedHandoverDelegation(
  delegation: HandoverDelegationDto.fromJson(
    (json['delegation'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{},
  ).toDomain(),
  verificationCode: _string(json['verificationCode']),
);

/// Request body for POST `…/handover-delegations` (backend
/// `AuthoriseParcelHandoverVm`). Times go over the wire as UTC ISO-8601.
///
/// `delegateContact` is the minimum the backend needs to be able to deliver
/// the code, and it is hashed on arrival — it is never returned or logged.
Map<String, dynamic> authoriseHandoverBody({
  required String delegateDisplayName,
  required String delegateContact,
  required DelegateRelationship relationship,
  required Set<DelegatedException> allowedExceptions,
  required DateTime windowStartUtc,
  required DateTime windowEndUtc,
}) => <String, dynamic>{
  'delegateDisplayName': delegateDisplayName.trim(),
  'delegateContact': delegateContact.trim(),
  'relationship': relationship.value,
  'allowedExceptions': packDelegatedExceptions(allowedExceptions),
  'windowStartUtc': windowStartUtc.toUtc().toIso8601String(),
  'windowEndUtc': windowEndUtc.toUtc().toIso8601String(),
};

/// Backend `HandoverDelegationStatus`: Active=1, Revoked=2, Consumed=3,
/// Expired=4. Anything else is [HandoverDelegationStatus.unknown] — the UI
/// says so rather than pretending it is active.
HandoverDelegationStatus parseHandoverDelegationStatus(Object? raw) =>
    switch (_normalizeEnum(raw)) {
      1 || 'active' => HandoverDelegationStatus.active,
      2 || 'revoked' => HandoverDelegationStatus.revoked,
      3 || 'consumed' => HandoverDelegationStatus.consumed,
      4 || 'expired' => HandoverDelegationStatus.expired,
      _ => HandoverDelegationStatus.unknown,
    };

/// Backend `DelegateRelationship`: FamilyMember=1, Neighbour=2,
/// OfficeOrReception=3, PickupPoint=4.
DelegateRelationship parseDelegateRelationship(Object? raw) =>
    switch (_normalizeEnum(raw)) {
      1 || 'familymember' => DelegateRelationship.familyMember,
      2 || 'neighbour' || 'neighbor' => DelegateRelationship.neighbour,
      3 || 'officeorreception' => DelegateRelationship.officeOrReception,
      4 || 'pickuppoint' => DelegateRelationship.pickupPoint,
      _ => DelegateRelationship.unknown,
    };

/// `[Flags] DelegatedExceptionAllowance` as an int. A comma-separated name
/// list (what `JsonStringEnumConverter` would emit for a flags enum) is
/// accepted too.
int _flags(Object? raw) {
  final normalized = _normalizeEnum(raw);
  if (normalized is int) return normalized < 0 ? 0 : normalized;
  if (raw is String) {
    var mask = 0;
    for (final part in raw.split(',')) {
      mask |= switch (part.trim().toLowerCase().replaceAll(
        RegExp(r'[\s_\-]'),
        '',
      )) {
        'substitution' => DelegatedException.substitution.value,
        'visibledamage' => DelegatedException.visibleDamage.value,
        'partialdelivery' => DelegatedException.partialDelivery.value,
        _ => 0,
      };
    }
    return mask;
  }
  return 0;
}

Object? _normalizeEnum(Object? raw) {
  if (raw is int) return raw;
  if (raw is num && raw == raw.roundToDouble()) return raw.toInt();
  if (raw is String) {
    final trimmed = raw.trim();
    return int.tryParse(trimmed) ??
        trimmed.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
  }
  return null;
}

DateTime _utc(Object? raw) => _utcOrNull(raw) ?? DateTime.utc(1970);

DateTime? _utcOrNull(Object? raw) {
  if (raw is! String) return null;
  return DateTime.tryParse(raw.trim())?.toUtc();
}

String _string(Object? raw) => raw is String ? raw.trim() : '';

String? _blankToNull(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}
