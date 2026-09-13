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
  if (outcome.needsNote) {
    final note = issueNote?.trim() ?? '';
    if (note.isEmpty) return 'Tell us what was wrong.';
    if (note.length > deliveryAcceptanceMaxNoteLength) {
      return 'Keep your note to 1,000 characters or fewer.';
    }
  }
  return null;
}
