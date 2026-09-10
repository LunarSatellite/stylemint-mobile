/// A surfaced brand↔creator match (`GET /v1/vendor/matches`).
class MatchRecommendation {
  const MatchRecommendation({
    required this.id,
    required this.creatorAccountId,
    required this.creatorHandle,
    required this.compatibilityScore,
    required this.reasonSummary,
  });

  final String id;
  final String creatorAccountId;
  final String creatorHandle;

  /// 0-100, derived from the API's 0-1 `score`.
  final int compatibilityScore;
  final String reasonSummary;

  String get normalizedCreatorHandle =>
      creatorHandle.trim().replaceFirst(RegExp(r'^@+'), '');

  String get displayCreatorHandle => normalizedCreatorHandle.isEmpty
      ? '@unknown'
      : '@$normalizedCreatorHandle';

  String get creatorInitial => normalizedCreatorHandle.isEmpty
      ? '?'
      : normalizedCreatorHandle[0].toUpperCase();
}

/// Returned by `POST /v1/vendor/matches/{id}/invite` — pre-fills a
/// partnership creation flow with the match's suggested commission.
class PartnershipPrefill {
  const PartnershipPrefill({
    required this.matchSnapshotId,
    required this.creatorAccountId,
    required this.creatorHandle,
    required this.proposedCommissionBps,
    required this.brandCommissionMinBps,
    required this.brandCommissionMaxBps,
    required this.matchScore,
    required this.reasonSummary,
    this.brandBriefId,
  });

  final String matchSnapshotId;
  final String creatorAccountId;
  final String creatorHandle;
  final int proposedCommissionBps;
  final int brandCommissionMinBps;
  final int brandCommissionMaxBps;
  final double matchScore;
  final String reasonSummary;
  final String? brandBriefId;

  double get proposedCommissionPercent => proposedCommissionBps / 100;
  double get brandCommissionMinPercent => brandCommissionMinBps / 100;
  double get brandCommissionMaxPercent => brandCommissionMaxBps / 100;
}
