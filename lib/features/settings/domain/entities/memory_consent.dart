/// Per-purpose consent for the Memory Vault.
///
/// The vault used to be governed by one `memoryPaused` boolean. One switch
/// cannot express "recall my size, but never message me", so the backend
/// replaced it with four purposes, each granted and withdrawn on its own,
/// each recording the explanation the customer was actually shown.
///
/// This client used to send only the boolean. The cost was invisible:
/// `recommendations` and `proactiveOutreach` were refused outright for every
/// customer — safe, but silently off — and the two older purposes ran on
/// [ConsentBasis.legacyGlobalPause] with `needsDecision: true`, a flag the
/// client dropped on the floor, so nobody was ever asked.
library;

/// A vault purpose, numbered as the backend's `MemoryPurpose` enum is.
///
/// The wire value is carried rather than derived from [index] because the
/// API serialises enums as integers and a reordering here must not silently
/// re-point a customer's decision at a different purpose.
enum MemoryPurpose {
  companionRecall(1),
  storefrontPersonalisation(2),
  recommendations(3),
  proactiveOutreach(4);

  const MemoryPurpose(this.wireValue);

  /// The integer the backend uses for this purpose.
  final int wireValue;

  /// Reads a purpose from its wire integer or its backend name.
  ///
  /// Returns null for anything this build does not know, so a purpose added
  /// to the backend after this release degrades to an unnamed row the
  /// customer can still refuse, rather than crashing the vault screen.
  static MemoryPurpose? fromWire(Object? value) {
    if (value is int) {
      for (final purpose in MemoryPurpose.values) {
        if (purpose.wireValue == value) return purpose;
      }
      return null;
    }
    if (value is String && value.isNotEmpty) {
      final lower = value.toLowerCase();
      for (final purpose in MemoryPurpose.values) {
        if (purpose.name.toLowerCase() == lower) return purpose;
      }
    }
    return null;
  }
}

/// What a purpose is running on, if anything.
enum ConsentBasis {
  /// No agreement: the purpose does not run.
  none(0),

  /// An explicit, revocable per-purpose grant by the customer.
  purposeGrant(1),

  /// The old global pause switch, still governing the two purposes that
  /// shipped under it. A weaker basis, and reported as such so we can ask.
  legacyGlobalPause(2);

  const ConsentBasis(this.wireValue);

  final int wireValue;

  static ConsentBasis fromWire(Object? value) {
    if (value is int) {
      for (final basis in ConsentBasis.values) {
        if (basis.wireValue == value) return basis;
      }
    }
    if (value is String && value.isNotEmpty) {
      final lower = value.toLowerCase();
      for (final basis in ConsentBasis.values) {
        if (basis.name.toLowerCase() == lower) return basis;
      }
    }
    return ConsentBasis.none;
  }
}

/// How one purpose reads to the customer right now.
///
/// [undecided] and [refused] are deliberately separate. "Nobody asked you"
/// and "you said no" are both off, but only one of them is a decision, and
/// showing them the same way would quietly claim a refusal the customer
/// never made.
enum ConsentStanding {
  /// The customer agreed, and the grant is live.
  granted,

  /// Running on the old global switch. The customer has not answered.
  legacyBasis,

  /// Nobody has asked, so it is off.
  undecided,

  /// The customer said no.
  refused,

  /// An agreement that has lapsed.
  expired,

  /// The global pause is on, which overrides every purpose.
  pausedGlobally,

  /// The consent state could not be read. Never treated as permission.
  unreadable,
}

/// One purpose's current decision, as `GET /memories/consents` reports it.
class MemoryConsent {
  const MemoryConsent({
    required this.purposeCode,
    required this.permitted,
    required this.basis,
    required this.reason,
    required this.needsDecision,
    this.purpose,
    this.expiresUtc,
  });

  /// What this client optimistically shows the moment a grant is accepted.
  MemoryConsent.grantedFor(MemoryPurpose this.purpose)
    : purposeCode = purpose.wireValue,
      permitted = true,
      basis = ConsentBasis.purposeGrant,
      reason = 'consent.granted',
      needsDecision = false,
      expiresUtc = null;

  /// What this client shows the moment a withdrawal is accepted.
  MemoryConsent.refusedFor(this.purposeCode)
    : purpose = MemoryPurpose.fromWire(purposeCode),
      permitted = false,
      basis = ConsentBasis.none,
      reason = 'consent.revoked',
      needsDecision = false,
      expiresUtc = null;

  /// A purpose the backend did not mention. Nothing was reported about it,
  /// so nothing is assumed about it.
  MemoryConsent.undecidedFor(MemoryPurpose this.purpose)
    : purposeCode = purpose.wireValue,
      permitted = false,
      basis = ConsentBasis.none,
      reason = 'consent.undecided',
      needsDecision = true,
      expiresUtc = null;

  /// Null when the backend named a purpose this build does not know.
  final MemoryPurpose? purpose;

  /// The wire value to send back, known purpose or not.
  final int purposeCode;

  /// The only field that means "this may run".
  final bool permitted;

  final ConsentBasis basis;

  /// The backend's stable reason code, e.g. `consent.undecided`.
  final String reason;

  /// The backend asking us to get a real per-purpose answer.
  final bool needsDecision;

  final DateTime? expiresUtc;

  /// How this reads to the customer, given the global pause.
  ///
  /// The pause is applied here rather than trusted from [reason] so that
  /// toggling it stays consistent on screen without a round trip: the
  /// backend reports `consent.paused` for every purpose while paused, which
  /// tells us nothing about the underlying answers.
  ConsentStanding standingWhilePaused({required bool paused}) {
    if (paused) return ConsentStanding.pausedGlobally;
    return standing;
  }

  /// How this reads on its own, ignoring the global pause.
  ConsentStanding get standing {
    if (reason == 'consent.paused') return ConsentStanding.pausedGlobally;
    if (reason == 'consent.unreadable' || reason == 'consent.unidentified') {
      return ConsentStanding.unreadable;
    }
    if (permitted) {
      return basis == ConsentBasis.legacyGlobalPause
          ? ConsentStanding.legacyBasis
          : ConsentStanding.granted;
    }
    return switch (reason) {
      'consent.revoked' => ConsentStanding.refused,
      'consent.expired' => ConsentStanding.expired,
      // An "off" whose reason this build does not recognise. Undecided is
      // the honest reading: it neither claims the customer agreed nor puts
      // a refusal in their mouth, and it asks.
      _ => ConsentStanding.undecided,
    };
  }

  MemoryConsent copyWith({
    bool? permitted,
    ConsentBasis? basis,
    String? reason,
    bool? needsDecision,
  }) => MemoryConsent(
    purpose: purpose,
    purposeCode: purposeCode,
    permitted: permitted ?? this.permitted,
    basis: basis ?? this.basis,
    reason: reason ?? this.reason,
    needsDecision: needsDecision ?? this.needsDecision,
    expiresUtc: expiresUtc,
  );
}

/// The words for each purpose.
///
/// [explanationOf] is the text the customer is shown *and* the text that is
/// submitted with a grant, because the backend stores it as the thing they
/// agreed to. Display and submission read this one constant — paraphrasing
/// between the two would make the stored record a lie.
abstract final class MemoryPurposeCopy {
  static const _companionRecallExplanation =
      'Let the companion use what it already knows about you while you are '
      'chatting with it: your sizes, the brands you keep coming back to, '
      'what you asked for last time. Refuse and it still answers you, but '
      'it starts every conversation blank — you will give it your size, '
      'your fit and your preferences again each time.';

  static const _storefrontExplanation =
      'Let your home page rearrange itself around you, putting the '
      'categories you shop, the brands you follow and the sizes you '
      'actually buy nearer the top. Refuse and you get the same Mall as '
      'everyone else: nothing is hidden from you, but nothing is brought '
      'forward either, and you will scroll further to reach your size.';

  static const _recommendationsExplanation =
      'Let us suggest products from what you have bought, liked and sent '
      'back — including the things that did not work, so we stop offering '
      'them. Refuse and suggestions fall back to what is popular in '
      'general, which will include sizes you do not wear and items you '
      'have already returned.';

  static const _outreachExplanation =
      'Let the companion message you first: a restock of the exact thing '
      'you wanted, a price drop on something you saved, a reminder that '
      'your return window is closing. Refuse and we only reply when you '
      'speak to us — nothing arrives unasked, and time-limited things will '
      'pass you by unless you check yourself.';

  /// The exact text shown beside the choice, and sent with a grant.
  static String explanationOf(MemoryPurpose purpose) => switch (purpose) {
    MemoryPurpose.companionRecall => _companionRecallExplanation,
    MemoryPurpose.storefrontPersonalisation => _storefrontExplanation,
    MemoryPurpose.recommendations => _recommendationsExplanation,
    MemoryPurpose.proactiveOutreach => _outreachExplanation,
  };

  /// The row heading.
  static String titleOf(MemoryPurpose purpose) => switch (purpose) {
    MemoryPurpose.companionRecall => 'Remembering you in conversation',
    MemoryPurpose.storefrontPersonalisation => 'A home page shaped by you',
    MemoryPurpose.recommendations => 'Suggestions from what you have bought',
    MemoryPurpose.proactiveOutreach => 'Messages we send you first',
  };

  /// The spoken name, for semantics labels like "Allow companion recall".
  static String spokenNameOf(MemoryPurpose purpose) => switch (purpose) {
    MemoryPurpose.companionRecall => 'remembering you in conversation',
    MemoryPurpose.storefrontPersonalisation => 'a home page shaped by you',
    MemoryPurpose.recommendations => 'suggestions from what you have bought',
    MemoryPurpose.proactiveOutreach => 'messages we send you first',
  };
}
