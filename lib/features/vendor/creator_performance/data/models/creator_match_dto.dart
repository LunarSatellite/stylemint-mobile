/// `MatchSnapshotDto` from `/v1/vendor/matches` — the closest available
/// signal for vendor-facing creator performance (match score + reason).
/// NOTE: true per-creator sales/earnings performance is not exposed by the
/// backend yet; this surfaces match-derived scoring.
class CreatorMatchDto {
  const CreatorMatchDto({
    required this.id,
    required this.creatorHandle,
    required this.scorePercent,
    required this.reasonSummary,
  });

  final String id;
  final String creatorHandle;
  final double scorePercent; // 0..100
  final String reasonSummary;

  factory CreatorMatchDto.fromJson(Map<String, dynamic> json) {
    final raw = (json['score'] as num?)?.toDouble() ?? 0;
    return CreatorMatchDto(
      id: (json['id'] as String?) ?? '',
      creatorHandle: (json['creatorHandle'] as String?) ?? '',
      scorePercent: raw <= 1 ? raw * 100 : raw,
      reasonSummary: (json['reasonSummary'] as String?) ?? '',
    );
  }
}
