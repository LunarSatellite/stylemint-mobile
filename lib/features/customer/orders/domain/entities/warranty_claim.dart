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
}
