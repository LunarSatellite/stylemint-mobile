/// One round of campaign-reel review.
///
/// Exactly one row per reel is [ReelApprovalState.pending] at a time; every
/// other row is a settled round kept for the record, which is what makes
/// revise-and-resubmit legible to both sides.
library;

/// Mirrors `StyleMint.Modules.Reels.Enums.ReelApprovalState`.
enum ReelApprovalState {
  /// Submitted, nobody has answered. The only live state.
  pending(1),

  /// The campaign's vendor approved; the reel published.
  approved(2),

  /// The vendor rejected, with or without a reason. The reel went back to
  /// draft and the creator may revise and resubmit.
  rejected(3),

  /// Nobody answered inside the configured window and the sweep returned the
  /// reel to draft.
  ///
  /// Distinct from [rejected] on purpose, and the UI must keep them apart: a
  /// brand that said nothing did not say no. Collapsing the two would tell a
  /// creator they were turned down when they were only ignored.
  expired(4);

  const ReelApprovalState(this.wire);

  final int wire;

  /// Unknown wire values map to null rather than to a default member — a state
  /// this build does not understand must not be shown as pending, which would
  /// invite a vendor to act on a round the server has already settled.
  static ReelApprovalState? tryParseWire(int? wire) {
    for (final s in ReelApprovalState.values) {
      if (s.wire == wire) return s;
    }
    return null;
  }

  bool get isPending => this == ReelApprovalState.pending;
}

/// A creator's request for a vendor to approve a campaign reel.
class ReelApprovalRequest {
  const ReelApprovalRequest({
    required this.id,
    required this.reelId,
    required this.creatorAccountId,
    required this.vendorAccountId,
    required this.partnershipId,
    required this.brandBriefId,
    required this.brandBriefVersion,
    required this.round,
    required this.state,
    required this.submittedUtc,
    this.creatorNote,
    this.decidedUtc,
    this.rejectionReason,
    this.expiredUtc,
  });

  final String id;
  final String reelId;
  final String creatorAccountId;
  final String vendorAccountId;
  final String partnershipId;
  final String brandBriefId;
  final int brandBriefVersion;

  /// 1 for the first submission, 2 for the first resubmission, and so on.
  final int round;

  /// Null when the server sent a state this build does not know.
  final ReelApprovalState? state;

  final DateTime submittedUtc;

  /// What the creator said when submitting. Null when they said nothing.
  final String? creatorNote;

  final DateTime? decidedUtc;

  /// Why the vendor rejected. Null when they rejected without saying — which
  /// is allowed, and must not be rendered as though a reason were given.
  final String? rejectionReason;

  final DateTime? expiredUtc;

  bool get isPending => state?.isPending ?? false;

  /// True only for the first round. Used to label a resubmission as such, so a
  /// vendor reading round 3 knows they have seen this reel before.
  bool get isFirstRound => round <= 1;
}
