/// Wire shapes for the "Permissioned Chain-of-Custody Proof" capability —
/// `GET /v1/deliveries/{trackingNumber}/custody` and `.../custody/verify`.
///
/// The backend keeps an append-only, Merkle-chained, ECDSA-signed record of
/// every handover of a parcel (`ChainOfCustodyEntry`). `VerifyAsync` walks the
/// chain, recomputes every hash and checks every signature, and deliberately
/// returns **Ok with `isValid: false`** for a broken chain rather than
/// throwing — so "the chain failed verification" and "we could not run the
/// verification" arrive here as two genuinely different outcomes, and this
/// file keeps them apart.
library;

/// Backend `ChainEventKind` — the discriminator on one custody entry.
///
/// [unknown] exists so a kind added on the server renders as a plain handover
/// instead of crashing or, worse, being silently dropped from the log.
enum CustodyEventKind {
  unknown(0),
  sealApplied(1),
  pickedUp(2),
  handedOff(3),
  deliveryConfirmed(4),
  exception(5),
  returnInitiated(6);

  const CustodyEventKind(this.code);

  final int code;

  static CustodyEventKind fromCode(int? code) => CustodyEventKind.values
      .firstWhere((kind) => kind.code == code, orElse: () => unknown);
}

/// One signed handover, backend `ChainOfCustodyEntryDto`.
///
/// Every field here is read straight off the wire. Nothing on this class is
/// derived from another entry: there is no interpolated "in transit" step and
/// no timestamp computed from a neighbour's. The custody log is evidence, and
/// evidence that the server did not send is not evidence.
class CustodyEntry {
  const CustodyEntry({
    required this.id,
    required this.sequence,
    required this.eventKind,
    required this.occurredUtc,
    this.notes,
    this.receivedByDelegateName,
    this.proofPhotoUrl,
  });

  factory CustodyEntry.fromJson(Map<String, dynamic> json) => CustodyEntry(
    id: json['id'] as String? ?? '',
    sequence: (json['sequence'] as num?)?.toInt() ?? 0,
    eventKind: CustodyEventKind.fromCode((json['eventKind'] as num?)?.toInt()),
    occurredUtc: DateTime.tryParse(json['occurredUtc'] as String? ?? ''),
    notes: _trimToNull(json['notes'] as String?),
    receivedByDelegateName: _trimToNull(
      json['receivedByDelegateName'] as String?,
    ),
    proofPhotoUrl: _trimToNull(json['proofPhotoUrl'] as String?),
  );

  final String id;
  final int sequence;
  final CustodyEventKind eventKind;

  /// When the handover happened, exactly as the entry records it. Null when
  /// the server sent no parsable timestamp — the UI then shows no time at all
  /// rather than guessing one from the entry before or after it.
  final DateTime? occurredUtc;

  final String? notes;

  /// Non-null when an authorised delegate, not the customer, took the parcel.
  /// The name is inside the signed payload, so the chain proves *who actually
  /// took it* and not merely that something was delivered.
  final String? receivedByDelegateName;

  final String? proofPhotoUrl;

  bool get isDelegatedHandover => receivedByDelegateName != null;

  static String? _trimToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// How much we can say about the integrity of a custody log.
///
/// Three states, not two. Collapsing [couldNotVerify] into either of the
/// others throws away exactly the distinction a signed chain exists to
/// provide: a log we could not check must never read as one that passed, and
/// it is not the same claim as one that failed.
enum CustodyVerificationState {
  /// The backend walked the chain: hashes recomputed, signatures checked, all
  /// of it held.
  verified,

  /// The backend walked the chain and it did not hold. This is a statement
  /// about the record, never an accusation against anyone who carried the
  /// parcel.
  failed,

  /// The check did not run, or its answer never arrived.
  couldNotVerify,
}

/// Backend `ChainIntegrityReport`, reduced to what a customer is shown.
///
/// The report also carries `entriesVerified`, `expectedSequenceCount` and a
/// per-failure breakdown. None of that is surfaced: a count of good entries
/// against expected ones reads as a score, and this capability deliberately
/// offers no score. The outcome is the outcome.
class CustodyVerification {
  const CustodyVerification._(this.state);

  /// The verification ran and the chain held.
  const CustodyVerification.verified()
    : this._(CustodyVerificationState.verified);

  /// The verification ran and the chain did not hold.
  const CustodyVerification.failed() : this._(CustodyVerificationState.failed);

  /// The verification did not run, or its answer never arrived.
  const CustodyVerification.couldNotVerify()
    : this._(CustodyVerificationState.couldNotVerify);

  /// Reads `isValid` off a `ChainIntegrityReport`. A response missing the
  /// field is [CustodyVerificationState.couldNotVerify] — an absent answer is
  /// not a passing one.
  factory CustodyVerification.fromJson(Map<String, dynamic> json) {
    final isValid = json['isValid'];
    if (isValid is! bool) return const CustodyVerification.couldNotVerify();
    return isValid
        ? const CustodyVerification.verified()
        : const CustodyVerification.failed();
  }

  final CustodyVerificationState state;
}

/// The whole proof for one parcel: the entries, in the order the server
/// returned them, and what the integrity check had to say about them.
class CustodyProof {
  const CustodyProof({required this.entries, required this.verification});

  /// Entries exactly as returned. Not re-sorted: the server owns the chain's
  /// order, and re-ordering a hash-chained log client-side would be inventing
  /// a sequence the signatures do not cover.
  final List<CustodyEntry> entries;

  final CustodyVerification verification;

  /// A parcel with no entries has no proof to show, and renders nothing.
  bool get isEmpty => entries.isEmpty;
}
