enum WarrantyIssueKind {
  manufacturingDefect(1, 'Manufacturing defect'),
  stoppedWorking(2, 'Stopped working'),
  materialFailure(3, 'Material failure'),
  missingPart(4, 'Missing part'),
  other(5, 'Other');

  const WarrantyIssueKind(this.wireValue, this.label);
  final int wireValue;
  final String label;
}

enum WarrantyClaimState {
  submitted,
  approved,
  rejected,
  repairInProgress,
  replacementInProgress,
  resolved,
  cancelled,
  unknown,
}

/// The physical item a claim was filed against, as it stands now — backend
/// `WarrantyClaimUnitDto`.
///
/// When the tag was later corrected, [isLive] is false and [supersededUtc] and
/// [supersededByBindingId] are set. The claim is **not** moved to the
/// correction: it keeps naming the item that was actually complained about and
/// says plainly that the tag has since been corrected. Quietly redirecting it
/// would be the platform deciding, after the fact, that the buyer meant a
/// different garment.
class WarrantyClaimUnit {
  const WarrantyClaimUnit({
    required this.bindingId,
    required this.markerReference,
    required this.isLive,
    this.inServiceSinceUtc,
    this.supersededUtc,
    this.supersededByBindingId,
  });

  final String bindingId;

  /// The non-secret `UM…` reference. Never the marker value itself.
  final String markerReference;
  final DateTime? inServiceSinceUtc;
  final bool isLive;
  final DateTime? supersededUtc;
  final String? supersededByBindingId;
}

class WarrantyClaim {
  const WarrantyClaim({
    required this.id,
    required this.claimNumber,
    required this.subOrderLineId,
    required this.state,
    required this.issueKind,
    required this.description,
    required this.evidenceUrls,
    required this.submittedUtc,
    this.decisionNote,
    this.resolvedUtc,
    this.unitMarkerBindingId,
    this.unit,
  });

  final String id;
  final String claimNumber;
  final String subOrderLineId;
  final WarrantyClaimState state;
  final WarrantyIssueKind issueKind;
  final String description;
  final List<String> evidenceUrls;
  final String? decisionNote;
  final DateTime submittedUtc;
  final DateTime? resolvedUtc;

  /// Null for a line-level claim — every claim filed before markers existed,
  /// and every claim on an unmarked item since. It is never inferred.
  final String? unitMarkerBindingId;

  /// The unit as it stands now. Null when the claim names no unit, and also
  /// when a named binding no longer resolves — absent rather than filled in
  /// with a placeholder reference or date.
  final WarrantyClaimUnit? unit;

  /// True when this claim is about one physical item rather than a whole line.
  bool get isUnitBound => unitMarkerBindingId != null;
}
