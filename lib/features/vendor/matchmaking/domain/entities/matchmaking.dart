class MatchRecommendation {
  const MatchRecommendation({
    required this.creatorId,
    required this.creatorName,
    required this.avatarUrl,
    required this.handle,
    required this.category,
    required this.followersCount,
    required this.compatibilityScore,
    required this.reasons,
    this.sampleReelThumbnail,
  });

  final String creatorId;
  final String creatorName;
  final String avatarUrl;
  final String handle;
  final String category;
  final int followersCount;
  final int compatibilityScore;
  final List<String> reasons;
  final String? sampleReelThumbnail;

  MatchRecommendation copyWith({
    String? creatorId,
    String? creatorName,
    String? avatarUrl,
    String? handle,
    String? category,
    int? followersCount,
    int? compatibilityScore,
    List<String>? reasons,
    String? sampleReelThumbnail,
  }) {
    return MatchRecommendation(
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      handle: handle ?? this.handle,
      category: category ?? this.category,
      followersCount: followersCount ?? this.followersCount,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      reasons: reasons ?? this.reasons,
      sampleReelThumbnail: sampleReelThumbnail ?? this.sampleReelThumbnail,
    );
  }
}

class MatchmakingFilter {
  const MatchmakingFilter({
    this.categories,
    this.minFollowers,
    this.maxFollowers,
    this.minEngagementRate,
    this.budgetRange,
  });

  final List<String>? categories;
  final int? minFollowers;
  final int? maxFollowers;
  final double? minEngagementRate;
  final double? budgetRange;

  MatchmakingFilter copyWith({
    List<String>? categories,
    int? minFollowers,
    int? maxFollowers,
    double? minEngagementRate,
    double? budgetRange,
  }) {
    return MatchmakingFilter(
      categories: categories ?? this.categories,
      minFollowers: minFollowers ?? this.minFollowers,
      maxFollowers: maxFollowers ?? this.maxFollowers,
      minEngagementRate: minEngagementRate ?? this.minEngagementRate,
      budgetRange: budgetRange ?? this.budgetRange,
    );
  }
}
