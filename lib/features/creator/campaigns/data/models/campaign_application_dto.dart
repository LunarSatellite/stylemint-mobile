import 'package:stylemint_mobile_frontend/features/creator/campaigns/domain/entities/campaign_application.dart';

/// Maps `CampaignApplicationDto` from the campaign-application routes.
class CampaignApplicationDto {
  const CampaignApplicationDto({
    required this.id,
    required this.brandBriefId,
    required this.brandBriefRootId,
    required this.brandBriefVersion,
    required this.vendorProfileId,
    required this.creatorProfileId,
    required this.stateWire,
    required this.submittedUtc,
    this.message,
    this.decidedUtc,
    this.declineReason,
    this.withdrawnUtc,
  });

  factory CampaignApplicationDto.fromJson(Map<String, dynamic> json) =>
      CampaignApplicationDto(
        id: json['id'] as String? ?? '',
        brandBriefId: json['brandBriefId'] as String? ?? '',
        brandBriefRootId: json['brandBriefRootId'] as String? ?? '',
        brandBriefVersion: (json['brandBriefVersion'] as num?)?.toInt() ?? 0,
        vendorProfileId: json['vendorProfileId'] as String? ?? '',
        creatorProfileId: json['creatorProfileId'] as String? ?? '',
        stateWire: (json['state'] as num?)?.toInt(),
        submittedUtc: DateTime.tryParse(json['submittedUtc'] as String? ?? '')
                ?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        message: _nonBlank(json['message'] as String?),
        decidedUtc: _utc(json['decidedUtc'] as String?),
        declineReason: _nonBlank(json['declineReason'] as String?),
        withdrawnUtc: _utc(json['withdrawnUtc'] as String?),
      );

  final String id;
  final String brandBriefId;
  final String brandBriefRootId;
  final int brandBriefVersion;
  final String vendorProfileId;
  final String creatorProfileId;

  /// Carried as the raw wire int so an unrecognised value survives to the
  /// domain as null instead of being coerced into a state the server did not
  /// send.
  final int? stateWire;

  final DateTime submittedUtc;
  final String? message;
  final DateTime? decidedUtc;
  final String? declineReason;
  final DateTime? withdrawnUtc;
}

String? _nonBlank(String? v) => (v == null || v.trim().isEmpty) ? null : v;

DateTime? _utc(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toUtc();
}

extension CampaignApplicationDtoMapper on CampaignApplicationDto {
  CampaignApplication toDomain() => CampaignApplication(
    id: id,
    brandBriefId: brandBriefId,
    brandBriefRootId: brandBriefRootId,
    brandBriefVersion: brandBriefVersion,
    vendorProfileId: vendorProfileId,
    creatorProfileId: creatorProfileId,
    state: CampaignApplicationState.tryParseWire(stateWire),
    submittedUtc: submittedUtc,
    message: message,
    decidedUtc: decidedUtc,
    declineReason: declineReason,
    withdrawnUtc: withdrawnUtc,
  );
}
