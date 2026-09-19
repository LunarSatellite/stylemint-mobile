import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/delivery_acceptance.dart';

/// Wire shape of GET/POST `/v1/deliveries/{trackingNumber}/acceptance` —
/// backend `DeliveryAcceptanceDto { Id, PackageId, TrackingNumber, Outcome,
/// SealIntact?, IssueNote?, PhotoUrls[], RecordedUtc }`, serialized
/// camelCase. `outcome` arrives as an int (the backend registers no
/// JsonStringEnumConverter); string names are accepted too.
class DeliveryAcceptanceDto {
  const DeliveryAcceptanceDto({
    required this.id,
    required this.packageId,
    required this.trackingNumber,
    required this.outcome,
    required this.photoUrls,
    this.sealIntact,
    this.issueNote,
    this.recordedUtc,
    this.itemsVerified = false,
    this.trackingCodeScanned = false,
    this.receivedItems = const <DeliveryReceivedItemCheck>[],
  });

  factory DeliveryAcceptanceDto.fromJson(Map<String, dynamic> json) =>
      DeliveryAcceptanceDto(
        id: _string(json['id']),
        packageId: _string(json['packageId']),
        trackingNumber: _string(json['trackingNumber']),
        outcome: parseDeliveryAcceptanceOutcome(json['outcome']),
        sealIntact: json['sealIntact'] is bool
            ? json['sealIntact'] as bool
            : null,
        issueNote: _blankToNull(json['issueNote']),
        photoUrls: _strings(json['photoUrls']),
        recordedUtc: json['recordedUtc'] is String
            ? DateTime.tryParse(json['recordedUtc'] as String)
            : null,
        itemsVerified: json['itemsVerified'] == true,
        trackingCodeScanned: json['trackingCodeScanned'] == true,
        receivedItems: _receivedItems(json['receivedItems']),
      );

  final String id;
  final String packageId;
  final String trackingNumber;
  final DeliveryAcceptanceOutcome outcome;
  final bool? sealIntact;
  final String? issueNote;
  final List<String> photoUrls;
  final DateTime? recordedUtc;
  final bool itemsVerified;
  final bool trackingCodeScanned;
  final List<DeliveryReceivedItemCheck> receivedItems;

  DeliveryAcceptance toDomain() => DeliveryAcceptance(
    id: id,
    packageId: packageId,
    trackingNumber: trackingNumber,
    outcome: outcome,
    sealIntact: sealIntact,
    issueNote: issueNote,
    photoUrls: photoUrls,
    recordedUtc: recordedUtc,
    itemsVerified: itemsVerified,
    trackingCodeScanned: trackingCodeScanned,
    receivedItems: receivedItems,
  );
}

/// The fields of GET `/v1/deliveries/{trackingNumber}` (backend `PackageDto`)
/// the acceptance card needs. `PackageDto` exposes no `hasSeal`, so it is
/// derived the way backend `Package.HasSeal` is: a seal id and a seal photo.
class DeliveryPackageStatusDto {
  const DeliveryPackageStatusDto({required this.state, required this.hasSeal});

  factory DeliveryPackageStatusDto.fromJson(Map<String, dynamic> json) =>
      DeliveryPackageStatusDto(
        state: parseDeliveryPackageState(json['state']),
        hasSeal:
            _blankToNull(json['sealId']) != null &&
            _blankToNull(json['sealPhotoUrl']) != null,
      );

  final DeliveryPackageState state;
  final bool hasSeal;

  DeliveryPackageStatus toDomain() =>
      DeliveryPackageStatus(state: state, hasSeal: hasSeal);
}

/// Request body for POST `/v1/deliveries/{trackingNumber}/acceptance`
/// (backend `RecordDeliveryAcceptanceVm`). Null seal answers and blank notes
/// are left out. No `photoUrls`: the app's only upload helper does not return
/// the https links the backend requires.
Map<String, dynamic> recordDeliveryAcceptanceBody({
  required DeliveryAcceptanceOutcome outcome,
  bool? sealIntact,
  String? issueNote,
  List<DeliveryReceivedItemInput> receivedItems =
      const <DeliveryReceivedItemInput>[],
  String? scannedTrackingCode,
}) {
  final note = issueNote?.trim() ?? '';
  return <String, dynamic>{
    'outcome': outcome.value,
    'sealIntact': ?sealIntact,
    if (note.isNotEmpty) 'issueNote': note,
    if (receivedItems.isNotEmpty)
      'receivedItems': receivedItems
          .map((e) => e.toJson())
          .toList(growable: false),
    if (scannedTrackingCode?.trim().isNotEmpty ?? false)
      'scannedTrackingCode': scannedTrackingCode!.trim(),
  };
}

/// Backend `DeliveryAcceptanceOutcome`: Accepted=1, AcceptedWithIssue=2,
/// Refused=3. Accepts the int, a numeric string or the name in any casing /
/// snake_case; anything else is [DeliveryAcceptanceOutcome.unknown].
DeliveryAcceptanceOutcome parseDeliveryAcceptanceOutcome(Object? raw) =>
    switch (_normalizeEnum(raw)) {
      1 || 'accepted' => DeliveryAcceptanceOutcome.accepted,
      2 || 'acceptedwithissue' => DeliveryAcceptanceOutcome.acceptedWithIssue,
      3 || 'refused' => DeliveryAcceptanceOutcome.refused,
      _ => DeliveryAcceptanceOutcome.unknown,
    };

/// Backend `PackageState`: Created=1 ... Returned=10, ints or names.
DeliveryPackageState parseDeliveryPackageState(Object? raw) =>
    switch (_normalizeEnum(raw)) {
      1 || 'created' => DeliveryPackageState.created,
      2 || 'awaitingpickup' => DeliveryPackageState.awaitingPickup,
      3 || 'pickedup' => DeliveryPackageState.pickedUp,
      4 || 'intransit' => DeliveryPackageState.inTransit,
      5 || 'athandoff' => DeliveryPackageState.atHandoff,
      6 || 'outfordelivery' => DeliveryPackageState.outForDelivery,
      7 || 'delivered' => DeliveryPackageState.delivered,
      8 || 'faileddelivery' => DeliveryPackageState.failedDelivery,
      9 || 'returning' => DeliveryPackageState.returning,
      10 || 'returned' => DeliveryPackageState.returned,
      _ => DeliveryPackageState.unknown,
    };

/// An int for int / whole-number / numeric-string input, a lowercase name
/// with `_`, `-` and spaces removed for other strings, else null.
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

List<DeliveryReceivedItemCheck> _receivedItems(Object? raw) {
  if (raw is! List) return const <DeliveryReceivedItemCheck>[];
  return raw
      .whereType<Map<Object?, Object?>>()
      .map((entry) {
        final json = Map<String, dynamic>.from(entry);
        return DeliveryReceivedItemCheck(
          subOrderLineId: _string(json['subOrderLineId']),
          productTitle: _string(json['productTitle']),
          expectedQuantity: (json['expectedQuantity'] as num?)?.toInt() ?? 0,
          receivedQuantity: (json['receivedQuantity'] as num?)?.toInt() ?? 0,
          condition: _string(json['condition']),
          batchOrLotCode: _blankToNull(json['batchOrLotCode']),
          expiryDate: json['expiryDate'] is String
              ? DateTime.tryParse(json['expiryDate'] as String)
              : null,
        );
      })
      .toList(growable: false);
}

String _string(Object? raw) => raw is String ? raw.trim() : '';

String? _blankToNull(Object? raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw
      .whereType<String>()
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}
