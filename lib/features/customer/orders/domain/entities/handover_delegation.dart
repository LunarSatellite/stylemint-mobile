/// Delegated parcel handover — the customer's side.
///
/// A customer who cannot be home authorises **one named person, for one
/// parcel, inside one time window**, and can withdraw that authorisation right
/// up to the moment the courier hands the parcel over.
///
/// Backend: `StyleMint.Modules.Delivery` —
/// `ParcelHandoverDelegation` / `ParcelHandoverDelegationDto`.
///
/// ## The verification code is deliberately absent from every type here
///
/// The backend returns `verificationCode` exactly once, in the creation
/// response, and keeps only its hash. Nothing in this file models it, because
/// nothing that survives a screen is allowed to hold it. The one carrier is
/// [IssuedHandoverDelegation], which the data source hands straight to the
/// widget state that draws it and to nowhere else.
library;

import 'package:flutter/foundation.dart';

/// Backend `HandoverDelegationStatus`. These four are the whole vocabulary —
/// the UI never invents a fifth.
enum HandoverDelegationStatus {
  /// Live. This is the only status that can authorise a handover, and the
  /// only one the customer can revoke.
  active(1),

  /// The customer withdrew it.
  revoked(2),

  /// Spent — the delegate took the parcel. One delegation, one handover.
  consumed(3),

  /// The window closed without anyone using it.
  expired(4),

  /// A status this build does not know. Rendered as "Unavailable" rather
  /// than guessed at.
  unknown(0);

  const HandoverDelegationStatus(this.value);

  final int value;

  bool get isActive => this == HandoverDelegationStatus.active;
}

/// Backend `DelegateRelationship`. The courier is shown this at the door so
/// they know whom to expect; it is the only relationship fact stored.
enum DelegateRelationship {
  familyMember(1),
  neighbour(2),
  officeOrReception(3),
  pickupPoint(4),
  unknown(0);

  const DelegateRelationship(this.value);

  final int value;
}

/// Backend `[Flags] DelegatedExceptionAllowance`.
///
/// Absent a flag the delegate may accept only a complete, undamaged,
/// as-ordered parcel — anything else waits for the customer. Every one of
/// these is a decision with a consequence, so the UI defaults to none and
/// spells each out in words rather than showing the flag name.
enum DelegatedException {
  substitution(1),
  visibleDamage(2),
  partialDelivery(4);

  const DelegatedException(this.value);

  final int value;
}

/// Packs a chosen set into the backend's flags int. Empty set -> `0` (None).
int packDelegatedExceptions(Set<DelegatedException> chosen) =>
    chosen.fold(0, (mask, e) => mask | e.value);

/// Unpacks the backend's flags int. Unknown bits are dropped rather than
/// rendered as a mystery permission.
Set<DelegatedException> unpackDelegatedExceptions(int mask) => {
  for (final e in DelegatedException.values)
    if (mask & e.value == e.value) e,
};

/// One delegation as the customer sees it. Note what is not here: the
/// verification code, and the delegate's contact. Neither is ever read back.
@immutable
class HandoverDelegation {
  const HandoverDelegation({
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

  final String id;
  final String trackingNumber;
  final String delegateDisplayName;
  final DelegateRelationship relationship;
  final Set<DelegatedException> allowedExceptions;
  final DateTime windowStartUtc;
  final DateTime windowEndUtc;
  final HandoverDelegationStatus status;
  final DateTime? consumedUtc;
  final DateTime? revokedUtc;
  final String? revocationReason;
  final DateTime? createdUtc;

  /// The status to *draw*, which is not always the status the backend last
  /// wrote: an `active` row whose window has closed is expired in fact, and
  /// saying "Active" about it would be a lie. Never invents a status outside
  /// [HandoverDelegationStatus].
  HandoverDelegationStatus effectiveStatusAt(DateTime nowUtc) =>
      status == HandoverDelegationStatus.active &&
          !nowUtc.isBefore(windowEndUtc)
      ? HandoverDelegationStatus.expired
      : status;

  /// Whether the customer's escape hatch applies. Revocation reaches a
  /// handover already in progress, so this stays true for the whole window —
  /// right up to the moment of handover.
  bool canRevokeAt(DateTime nowUtc) =>
      effectiveStatusAt(nowUtc) == HandoverDelegationStatus.active;

  /// True while the window has not opened yet.
  bool isPendingAt(DateTime nowUtc) =>
      status == HandoverDelegationStatus.active &&
      nowUtc.isBefore(windowStartUtc);
}

/// The creation response, and the only place a verification code ever exists
/// in this app.
///
/// This type is intentionally **not** const-constructible into any cache, has
/// no `toJson`, no `toString` override and no equality: it is built by the
/// data source, read once by the widget that shows the code, and dropped.
class IssuedHandoverDelegation {
  IssuedHandoverDelegation({
    required this.delegation,
    required this.verificationCode,
  });

  final HandoverDelegation delegation;

  /// Shown once. Never stored, never logged, never in a URL.
  ///
  /// Anything that keeps this beyond the frame that draws it is a bug — see
  /// `handover_delegation_secrecy_test.dart`, which fails the build if this
  /// field reaches storage, a log, a route or the clipboard.
  final String verificationCode;

  /// Deliberately hides the code from every accidental stringification —
  /// `'$issued'` in a log line, an error message, a crash report breadcrumb.
  @override
  String toString() =>
      'IssuedHandoverDelegation(${delegation.id}, code: <redacted>)';
}

// ── Window rules, enforced here so the server never rejects a filled form ──

/// Backend `ParcelHandoverDelegation.MinWindowLength`.
const Duration kHandoverMinWindow = Duration(minutes: 15);

/// Backend `ParcelHandoverDelegation.MaxWindowLength`.
const Duration kHandoverMaxWindow = Duration(hours: 72);

/// Backend `ParcelHandoverDelegation.MaxLeadTime`.
const Duration kHandoverMaxLeadTime = Duration(days: 14);

/// Why a window is not allowed. Each case gets its own sentence — collapsing
/// them into "invalid window" would leave the customer guessing which of four
/// rules they broke.
enum HandoverWindowProblem {
  endsBeforeStart,
  tooShort,
  tooLong,
  alreadyPast,
  tooFarAhead,
}

/// Checks a proposed window against the same four rules the backend applies,
/// so a customer is told before they submit rather than after.
/// Returns `null` when the window is acceptable.
HandoverWindowProblem? validateHandoverWindow({
  required DateTime startUtc,
  required DateTime endUtc,
  required DateTime nowUtc,
}) {
  if (!endUtc.isAfter(startUtc)) return HandoverWindowProblem.endsBeforeStart;
  final length = endUtc.difference(startUtc);
  if (length < kHandoverMinWindow) return HandoverWindowProblem.tooShort;
  if (length > kHandoverMaxWindow) return HandoverWindowProblem.tooLong;
  if (!endUtc.isAfter(nowUtc)) return HandoverWindowProblem.alreadyPast;
  if (startUtc.difference(nowUtc) > kHandoverMaxLeadTime) {
    return HandoverWindowProblem.tooFarAhead;
  }
  return null;
}
