/// A creator's application to a published campaign, and the four things that
/// can be true of it.
library;

/// Mirrors `StyleMint.Modules.Partnerships.Enums.CampaignApplicationState`.
///
/// Every transition is out of [pending] and every one is terminal. [pending]
/// and [accepted] are the *live* pair — the two that occupy the creator's one
/// application slot per brief lineage. [withdrawn] and [declined] free the
/// slot, so a creator who withdrew may apply again.
enum CampaignApplicationState {
  pending(1),
  withdrawn(2),
  accepted(3),
  declined(4);

  const CampaignApplicationState(this.wire);

  final int wire;

  /// Unknown wire values map to null rather than to a default member. A state
  /// the client does not understand must not be silently shown as pending —
  /// that would tell a creator their application is live when the server may
  /// have settled it.
  static CampaignApplicationState? tryParseWire(int? wire) {
    for (final s in CampaignApplicationState.values) {
      if (s.wire == wire) return s;
    }
    return null;
  }

  /// Whether this state still occupies the creator's slot for the brief.
  bool get isLive =>
      this == CampaignApplicationState.pending ||
      this == CampaignApplicationState.accepted;

  /// Whether the creator may withdraw from here. Only a pending application
  /// can be withdrawn; the server enforces the same rule and answers 409.
  bool get canWithdraw => this == CampaignApplicationState.pending;
}

/// One application, in whatever state it has reached.
class CampaignApplication {
  const CampaignApplication({
    required this.id,
    required this.brandBriefId,
    required this.brandBriefRootId,
    required this.brandBriefVersion,
    required this.vendorProfileId,
    required this.creatorProfileId,
    required this.state,
    required this.submittedUtc,
    this.message,
    this.decidedUtc,
    this.declineReason,
    this.withdrawnUtc,
  });

  final String id;
  final String brandBriefId;
  final String brandBriefRootId;
  final int brandBriefVersion;
  final String vendorProfileId;
  final String creatorProfileId;

  /// Null when the server sent a state this build does not know. Callers must
  /// render that as unknown rather than guessing.
  final CampaignApplicationState? state;

  final DateTime submittedUtc;

  /// The creator's pitch. Null when they applied without one — which is
  /// allowed, and different from an empty pitch.
  final String? message;

  final DateTime? decidedUtc;

  /// Why the vendor passed. Null when they declined without saying, which is
  /// also allowed; the UI must not substitute a reason of its own.
  final String? declineReason;

  final DateTime? withdrawnUtc;

  bool get canWithdraw => state?.canWithdraw ?? false;
}
