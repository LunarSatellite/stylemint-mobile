import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';

part 'matchmaking_dto.freezed.dart';
part 'matchmaking_dto.g.dart';

/// Mirrors `MatchSnapshotDto` (`GET /v1/vendor/matches`). Only the fields
/// the vendor match card actually needs are modeled — the backend also
/// returns `origin`/`state`/`contributionByFeatureJson`/timestamps/etc,
/// which json_serializable ignores since they aren't declared here.
@freezed
abstract class MatchRecommendationDto with _$MatchRecommendationDto {
  const factory MatchRecommendationDto({
    required String id,
    required String creatorAccountId,
    required String creatorHandle,
    required double score,
    required String reasonSummary,
  }) = _MatchRecommendationDto;

  const MatchRecommendationDto._();

  factory MatchRecommendationDto.fromJson(Map<String, dynamic> json) =>
      _$MatchRecommendationDtoFromJson(json);

  MatchRecommendation toDomain() => MatchRecommendation(
    id: id,
    creatorAccountId: creatorAccountId,
    creatorHandle: creatorHandle,
    compatibilityScore: (score * 100).round().clamp(0, 100),
    reasonSummary: reasonSummary,
  );
}

/// Mirrors `PartnershipPrefillDto` (`POST /v1/vendor/matches/{id}/invite`).
@freezed
abstract class PartnershipPrefillDto with _$PartnershipPrefillDto {
  const factory PartnershipPrefillDto({
    required String matchSnapshotId,
    required String creatorAccountId,
    required String creatorHandle,
    required int proposedCommissionBps,
    required int brandCommissionMinBps,
    required int brandCommissionMaxBps,
    required double matchScore,
    required String reasonSummary,
    String? brandBriefId,
  }) = _PartnershipPrefillDto;

  const PartnershipPrefillDto._();

  factory PartnershipPrefillDto.fromJson(Map<String, dynamic> json) =>
      _$PartnershipPrefillDtoFromJson(json);

  PartnershipPrefill toDomain() => PartnershipPrefill(
    matchSnapshotId: matchSnapshotId,
    creatorAccountId: creatorAccountId,
    creatorHandle: creatorHandle,
    proposedCommissionBps: proposedCommissionBps,
    brandCommissionMinBps: brandCommissionMinBps,
    brandCommissionMaxBps: brandCommissionMaxBps,
    matchScore: matchScore,
    reasonSummary: reasonSummary,
    brandBriefId: brandBriefId,
  );
}
