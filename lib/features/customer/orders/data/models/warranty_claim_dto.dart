import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/warranty_claim.dart';

class WarrantyClaimDto {
  const WarrantyClaimDto({
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

  factory WarrantyClaimDto.fromJson(Map<String, dynamic> json) =>
      WarrantyClaimDto(
        id: json['id']?.toString() ?? '',
        claimNumber: json['claimNumber']?.toString() ?? '',
        subOrderLineId: json['subOrderLineId']?.toString() ?? '',
        state: _state(json['state']),
        issueKind: _issue(json['issueKind']),
        description: json['description']?.toString() ?? '',
        evidenceUrls: (json['evidenceUrls'] as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .where((value) => value.isNotEmpty)
            .toList(growable: false),
        decisionNote: _text(json['decisionNote']),
        submittedUtc:
            DateTime.tryParse(json['submittedUtc']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        resolvedUtc: DateTime.tryParse(json['resolvedUtc']?.toString() ?? ''),
      );

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

  WarrantyClaim toDomain() => WarrantyClaim(
    id: id,
    claimNumber: claimNumber,
    subOrderLineId: subOrderLineId,
    state: state,
    issueKind: issueKind,
    description: description,
    evidenceUrls: evidenceUrls,
    submittedUtc: submittedUtc,
    decisionNote: decisionNote,
    resolvedUtc: resolvedUtc,
  );
}

WarrantyClaimState _state(Object? raw) {
  final value = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  if (value != null) {
    return switch (value) {
      1 => WarrantyClaimState.submitted,
      2 => WarrantyClaimState.approved,
      3 => WarrantyClaimState.rejected,
      4 => WarrantyClaimState.repairInProgress,
      5 => WarrantyClaimState.replacementInProgress,
      6 => WarrantyClaimState.resolved,
      7 => WarrantyClaimState.cancelled,
      _ => WarrantyClaimState.unknown,
    };
  }
  final name = raw?.toString().toLowerCase().replaceAll(RegExp(r'[_\-\s]'), '');
  return WarrantyClaimState.values.firstWhere(
    (state) => state.name.toLowerCase() == name,
    orElse: () => WarrantyClaimState.unknown,
  );
}

WarrantyIssueKind _issue(Object? raw) {
  final value = raw is num ? raw.toInt() : int.tryParse(raw?.toString() ?? '');
  return WarrantyIssueKind.values.firstWhere(
    (issue) => issue.wireValue == value,
    orElse: () => WarrantyIssueKind.other,
  );
}

String? _text(Object? raw) {
  final value = raw?.toString().trim();
  return value == null || value.isEmpty ? null : value;
}
