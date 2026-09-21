import 'package:stylemint_mobile_frontend/features/vendor/reel_approvals/domain/entities/reel_approval_request.dart';

/// Maps `ReelApprovalRequestDto` from the creator and vendor approval routes.
class ReelApprovalRequestDto {
  const ReelApprovalRequestDto({
    required this.id,
    required this.reelId,
    required this.creatorAccountId,
    required this.vendorAccountId,
    required this.partnershipId,
    required this.brandBriefId,
    required this.brandBriefVersion,
    required this.round,
    required this.stateWire,
    required this.submittedUtc,
    this.creatorNote,
    this.decidedUtc,
    this.rejectionReason,
    this.expiredUtc,
  });

  factory ReelApprovalRequestDto.fromJson(Map<String, dynamic> json) =>
      ReelApprovalRequestDto(
        id: json['id'] as String? ?? '',
        reelId: json['reelId'] as String? ?? '',
        creatorAccountId: json['creatorAccountId'] as String? ?? '',
        vendorAccountId: json['vendorAccountId'] as String? ?? '',
        partnershipId: json['partnershipId'] as String? ?? '',
        brandBriefId: json['brandBriefId'] as String? ?? '',
        brandBriefVersion: (json['brandBriefVersion'] as num?)?.toInt() ?? 0,
        round: (json['round'] as num?)?.toInt() ?? 1,
        stateWire: (json['state'] as num?)?.toInt(),
        submittedUtc:
            DateTime.tryParse(json['submittedUtc'] as String? ?? '')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        creatorNote: _nonBlank(json['creatorNote'] as String?),
        decidedUtc: _utc(json['decidedUtc'] as String?),
        rejectionReason: _nonBlank(json['rejectionReason'] as String?),
        expiredUtc: _utc(json['expiredUtc'] as String?),
      );

  final String id;
  final String reelId;
  final String creatorAccountId;
  final String vendorAccountId;
  final String partnershipId;
  final String brandBriefId;
  final int brandBriefVersion;
  final int round;

  /// Kept as the raw wire int so an unrecognised value reaches the domain as
  /// null instead of being coerced into a state the server did not send.
  final int? stateWire;

  final DateTime submittedUtc;
  final String? creatorNote;
  final DateTime? decidedUtc;
  final String? rejectionReason;
  final DateTime? expiredUtc;
}

String? _nonBlank(String? v) => (v == null || v.trim().isEmpty) ? null : v;

DateTime? _utc(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

extension ReelApprovalRequestDtoMapper on ReelApprovalRequestDto {
  ReelApprovalRequest toDomain() => ReelApprovalRequest(
    id: id,
    reelId: reelId,
    creatorAccountId: creatorAccountId,
    vendorAccountId: vendorAccountId,
    partnershipId: partnershipId,
    brandBriefId: brandBriefId,
    brandBriefVersion: brandBriefVersion,
    round: round,
    state: ReelApprovalState.tryParseWire(stateWire),
    submittedUtc: submittedUtc,
    creatorNote: creatorNote,
    decidedUtc: decidedUtc,
    rejectionReason: rejectionReason,
    expiredUtc: expiredUtc,
  );
}
