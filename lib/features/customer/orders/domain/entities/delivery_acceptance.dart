/// Voyager "Verified Scan-to-Receive Handover" — the buyer's own record of
/// what arrived: accepted, accepted with an issue, or refused, with whether
/// the tamper seal was intact. Written once per package and never edited.
/// Backend `DeliveryAcceptanceDto`.
class DeliveryAcceptance {
  const DeliveryAcceptance({
    required this.id,
    required this.packageId,
    required this.trackingNumber,
    required this.outcome,
    this.sealIntact,
    this.issueNote,
    this.photoUrls = const <String>[],
    this.recordedUtc,
    this.itemsVerified = false,
    this.trackingCodeScanned = false,
    this.receivedItems = const <DeliveryReceivedItemCheck>[],
  });

  final String id;
  final String packageId;
  final String trackingNumber;
  final DeliveryAcceptanceOutcome outcome;

  /// Whether the tamper seal was intact; null when the package had no seal.
  final bool? sealIntact;

  final String? issueNote;
  final List<String> photoUrls;
  final DateTime? recordedUtc;
  final bool itemsVerified;
  final bool trackingCodeScanned;
  final List<DeliveryReceivedItemCheck> receivedItems;
}

class DeliveryReceivedItemInput {
  const DeliveryReceivedItemInput({
    required this.subOrderLineId,
    required this.productTitle,
    required this.expectedQuantity,
    required this.receivedQuantity,
    this.condition = 'Good',
    this.batchOrLotCode,
    this.expiryDate,
  });

  final String subOrderLineId;
  final String productTitle;
  final int expectedQuantity;
  final int receivedQuantity;
  final String condition;
  final String? batchOrLotCode;
  final DateTime? expiryDate;

  DeliveryReceivedItemInput copyWith({
    int? receivedQuantity,
    String? condition,
    String? batchOrLotCode,
    DateTime? expiryDate,
    bool clearBatch = false,
    bool clearExpiry = false,
  }) => DeliveryReceivedItemInput(
    subOrderLineId: subOrderLineId,
    productTitle: productTitle,
    expectedQuantity: expectedQuantity,
    receivedQuantity: receivedQuantity ?? this.receivedQuantity,
    condition: condition ?? this.condition,
    batchOrLotCode: clearBatch ? null : batchOrLotCode ?? this.batchOrLotCode,
    expiryDate: clearExpiry ? null : expiryDate ?? this.expiryDate,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'subOrderLineId': subOrderLineId,
    'receivedQuantity': receivedQuantity,
    'condition': condition,
    if (batchOrLotCode?.trim().isNotEmpty ?? false)
      'batchOrLotCode': batchOrLotCode!.trim(),
    if (expiryDate != null)
      'expiryDate':
          '${expiryDate!.year.toString().padLeft(4, '0')}-'
          '${expiryDate!.month.toString().padLeft(2, '0')}-'
          '${expiryDate!.day.toString().padLeft(2, '0')}',
  };
}

class DeliveryReceivedItemCheck {
  const DeliveryReceivedItemCheck({
    required this.subOrderLineId,
    required this.productTitle,
    required this.expectedQuantity,
    required this.receivedQuantity,
    required this.condition,
    this.batchOrLotCode,
    this.expiryDate,
  });

  final String subOrderLineId;
  final String productTitle;
  final int expectedQuantity;
  final int receivedQuantity;
  final String condition;
  final String? batchOrLotCode;
  final DateTime? expiryDate;
}

/// What the buyer recorded. Backend `DeliveryAcceptanceOutcome`.
enum DeliveryAcceptanceOutcome {
  accepted(1),
  acceptedWithIssue(2),
  refused(3),

  /// A value this app version doesn't know yet (never sent).
  unknown(0);

  const DeliveryAcceptanceOutcome(this.value);

  /// The int the backend expects; it registers no JsonStringEnumConverter.
  final int value;

  /// Anything other than "all good" must say what was wrong.
  bool get needsNote => this == acceptedWithIssue || this == refused;
}

/// Backend `PackageState`, in its int order (Created=1 ... Returned=10).
enum DeliveryPackageState {
  created,
  awaitingPickup,
  pickedUp,
  inTransit,
  atHandoff,
  outForDelivery,
  delivered,
  failedDelivery,
  returning,
  returned,
  unknown,
}

/// The parts of a StyleMint package the acceptance card needs.
class DeliveryPackageStatus {
  const DeliveryPackageStatus({required this.state, required this.hasSeal});

  final DeliveryPackageState state;

  /// Whether the seller sealed the package (backend `Package.HasSeal`), in
  /// which case the buyer must say whether the seal was intact.
  final bool hasSeal;

  /// The backend only records an answer once the parcel is out for delivery
  /// or delivered.
  bool get canRecordAcceptance =>
      state == DeliveryPackageState.outForDelivery ||
      state == DeliveryPackageState.delivered;
}

/// Backend `DeliveryAcceptance.MaxNoteLength`.
const deliveryAcceptanceMaxNoteLength = 1000;

/// Why this answer can't be sent yet, in the buyer's words, or null when it
/// can. Mirrors the rules the backend enforces in `DeliveryAcceptance.Record`.
String? deliveryAcceptanceProblem({
  required DeliveryAcceptanceOutcome? outcome,
  required bool hasSeal,
  bool? sealIntact,
  String? issueNote,
  List<DeliveryReceivedItemInput> receivedItems =
      const <DeliveryReceivedItemInput>[],
}) {
  if (hasSeal && sealIntact == null) {
    return 'Tell us whether the seal was intact.';
  }
  if (outcome == null || outcome == DeliveryAcceptanceOutcome.unknown) {
    return 'Choose what happened with your parcel.';
  }
  if (hasSeal &&
      sealIntact == false &&
      outcome == DeliveryAcceptanceOutcome.accepted) {
    return "A parcel with a broken seal can't be marked as all good. "
        "Choose Something's wrong or Refuse it.";
  }
  if (outcome == DeliveryAcceptanceOutcome.accepted &&
      receivedItems.isNotEmpty &&
      receivedItems.any(
        (item) =>
            item.receivedQuantity != item.expectedQuantity ||
            item.condition != 'Good' ||
            (item.expiryDate != null &&
                !item.expiryDate!.isAfter(DateTime.now())),
      )) {
    return 'Mark every item present, in good condition, and not expired before choosing All good.';
  }
  if (outcome.needsNote) {
    final note = issueNote?.trim() ?? '';
    if (note.isEmpty) return 'Tell us what was wrong.';
    if (note.length > deliveryAcceptanceMaxNoteLength) {
      return 'Keep your note to 1,000 characters or fewer.';
    }
  }
  return null;
}
