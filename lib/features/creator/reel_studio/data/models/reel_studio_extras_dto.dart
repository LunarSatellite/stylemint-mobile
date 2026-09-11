/// Plain-Dart DTOs for Creator Studio endpoints that don't need code generation.
library;

import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio_extras.dart';

class CoachingTipDto {
  const CoachingTipDto({
    this.category,
    this.tip,
    this.exampleText,
    required this.priority,
    this.evidenceSummary,
  });

  final String? category;
  final String? tip;
  final String? exampleText;
  final int priority;
  final String? evidenceSummary;

  factory CoachingTipDto.fromJson(Map<String, dynamic> json) => CoachingTipDto(
    category: json['category'] as String?,
    tip: json['tip'] as String?,
    exampleText: json['exampleText'] as String?,
    priority: (json['priority'] as num?)?.toInt() ?? 0,
    evidenceSummary: json['evidenceSummary'] as String?,
  );
}

class CollabSuggestionDto {
  const CollabSuggestionDto({
    required this.otherCreatorId,
    this.otherCreatorHandle,
    required this.sharedProductId,
    this.sharedProductName,
    this.matchReason,
  });

  final String otherCreatorId;
  final String? otherCreatorHandle;
  final String sharedProductId;
  final String? sharedProductName;
  final String? matchReason;

  factory CollabSuggestionDto.fromJson(Map<String, dynamic> json) =>
      CollabSuggestionDto(
        otherCreatorId: (json['otherCreatorId'] as String?) ?? '',
        otherCreatorHandle: json['otherCreatorHandle'] as String?,
        sharedProductId: (json['sharedProductId'] as String?) ?? '',
        sharedProductName: json['sharedProductName'] as String?,
        matchReason: json['matchReason'] as String?,
      );
}

class DropPartyPromptDto {
  const DropPartyPromptDto({
    required this.vendorAccountId,
    this.vendorName,
    required this.highPerformingReelCount,
    this.suggestionText,
  });

  final String vendorAccountId;
  final String? vendorName;
  final int highPerformingReelCount;
  final String? suggestionText;

  factory DropPartyPromptDto.fromJson(Map<String, dynamic> json) =>
      DropPartyPromptDto(
        vendorAccountId: (json['vendorAccountId'] as String?) ?? '',
        vendorName: json['vendorName'] as String?,
        highPerformingReelCount:
            (json['highPerformingReelCount'] as num?)?.toInt() ?? 0,
        suggestionText: json['suggestionText'] as String?,
      );
}

class TagNudgeDto {
  const TagNudgeDto({
    required this.reelId,
    required this.suggestedProductId,
    this.productName,
    this.reason,
  });

  final String reelId;
  final String suggestedProductId;
  final String? productName;
  final String? reason;

  factory TagNudgeDto.fromJson(Map<String, dynamic> json) => TagNudgeDto(
    reelId: (json['reelId'] as String?) ?? '',
    suggestedProductId: (json['suggestedProductId'] as String?) ?? '',
    productName: json['productName'] as String?,
    reason: json['reason'] as String?,
  );
}

extension CoachingTipDtoMapper on CoachingTipDto {
  CoachingTip toDomain() => CoachingTip(
    priority: priority,
    category: category,
    tip: tip,
    exampleText: exampleText,
    evidenceSummary: evidenceSummary,
  );
}

extension CollabSuggestionDtoMapper on CollabSuggestionDto {
  CollabSuggestion toDomain() => CollabSuggestion(
    otherCreatorId: otherCreatorId,
    sharedProductId: sharedProductId,
    otherCreatorHandle: otherCreatorHandle,
    sharedProductName: sharedProductName,
    matchReason: matchReason,
  );
}

extension DropPartyPromptDtoMapper on DropPartyPromptDto {
  DropPartyPrompt toDomain() => DropPartyPrompt(
    vendorAccountId: vendorAccountId,
    highPerformingReelCount: highPerformingReelCount,
    vendorName: vendorName,
    suggestionText: suggestionText,
  );
}

extension TagNudgeDtoMapper on TagNudgeDto {
  TagNudge toDomain() => TagNudge(
    reelId: reelId,
    suggestedProductId: suggestedProductId,
    productName: productName,
    reason: reason,
  );
}

class ReelRecipeCardDto {
  const ReelRecipeCardDto({
    required this.recipeId,
    required this.recipeVersion,
    required this.title,
    required this.songTitle,
    required this.songArtist,
    required this.intendedDurationSeconds,
    required this.fromBrand,
    this.thumbnailUrl,
  });

  final String recipeId;
  final int recipeVersion;
  final String title;
  final String songTitle;
  final String songArtist;
  final int intendedDurationSeconds;
  final String? thumbnailUrl;
  final bool fromBrand;

  factory ReelRecipeCardDto.fromJson(
    Map<String, dynamic> json, {
    required bool fromBrand,
  }) => ReelRecipeCardDto(
    recipeId: json['recipeId']?.toString() ?? '',
    recipeVersion: (json['recipeVersion'] as num?)?.toInt() ?? 1,
    title: json['title']?.toString() ?? '',
    songTitle: json['songTitle']?.toString() ?? '',
    songArtist: json['songArtist']?.toString() ?? '',
    intendedDurationSeconds:
        (json['intendedDurationSeconds'] as num?)?.toInt() ?? 0,
    thumbnailUrl: switch (json['thumbnailUrl']?.toString().trim()) {
      final String value when value.isNotEmpty => value,
      _ => null,
    },
    fromBrand: json['fromBrand'] as bool? ?? fromBrand,
  );
}

class LaunchpadJourneyDto {
  const LaunchpadJourneyDto({
    required this.currentPhase,
    required this.totalReelsPublished,
    required this.totalRevenue,
    required this.totalFollowers,
    required this.totalPartnerships,
    required this.nextMilestoneProgress,
  });

  final String currentPhase;
  final int totalReelsPublished;
  final double totalRevenue;
  final int totalFollowers;
  final int totalPartnerships;
  final Map<String, double> nextMilestoneProgress;

  factory LaunchpadJourneyDto.fromJson(
    Map<String, dynamic> json,
  ) => LaunchpadJourneyDto(
    currentPhase: json['currentPhase']?.toString() ?? '',
    totalReelsPublished: (json['totalReelsPublished'] as num?)?.toInt() ?? 0,
    totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
    totalFollowers: (json['totalFollowers'] as num?)?.toInt() ?? 0,
    totalPartnerships: (json['totalPartnerships'] as num?)?.toInt() ?? 0,
    nextMilestoneProgress: ((json['nextMilestoneProgress'] as Map?) ?? const {})
        .map<String, double>(
          (key, value) => MapEntry(
            key.toString(),
            (value as num?)?.toDouble() ?? 0,
          ),
        ),
  );
}

class LaunchpadMilestoneDto {
  const LaunchpadMilestoneDto({
    required this.key,
    required this.name,
    required this.description,
    required this.completionPercent,
    required this.isCompleted,
  });

  final String key;
  final String name;
  final String description;
  final double completionPercent;
  final bool isCompleted;

  factory LaunchpadMilestoneDto.fromJson(Map<String, dynamic> json) =>
      LaunchpadMilestoneDto(
        key: json['key'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        completionPercent: (json['completionPercent'] as num?)?.toDouble() ?? 0,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}

class LaunchpadLessonDto {
  const LaunchpadLessonDto({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.readingTimeMinutes,
    required this.difficultyLevel,
    required this.unlockPhase,
  });

  final String id;
  final String title;
  final String category;
  final String content;
  final int readingTimeMinutes;
  final int difficultyLevel;
  final String unlockPhase;

  factory LaunchpadLessonDto.fromJson(Map<String, dynamic> json) =>
      LaunchpadLessonDto(
        id: json['id']?.toString() ?? '',
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        content: json['content'] as String? ?? '',
        readingTimeMinutes: (json['readingTimeMinutes'] as num?)?.toInt() ?? 0,
        difficultyLevel: (json['difficultyLevel'] as num?)?.toInt() ?? 1,
        unlockPhase: json['unlockPhase'] as String? ?? '',
      );
}

class LaunchpadForecastDto {
  const LaunchpadForecastDto({
    required this.projectedMonthlyEarnings,
    required this.projectedMonthLabel,
    required this.growthRatePercent,
    required this.projectedReels,
    required this.projectedFollowers,
    required this.recommendation,
  });

  final double projectedMonthlyEarnings;
  final String projectedMonthLabel;
  final double growthRatePercent;
  final int projectedReels;
  final int projectedFollowers;
  final String recommendation;

  factory LaunchpadForecastDto.fromJson(Map<String, dynamic> json) =>
      LaunchpadForecastDto(
        projectedMonthlyEarnings:
            (json['projectedMonthlyEarnings'] as num?)?.toDouble() ?? 0,
        projectedMonthLabel: json['projectedMonthLabel'] as String? ?? '',
        growthRatePercent: (json['growthRatePercent'] as num?)?.toDouble() ?? 0,
        projectedReels: (json['projectedReels'] as num?)?.toInt() ?? 0,
        projectedFollowers: (json['projectedFollowers'] as num?)?.toInt() ?? 0,
        recommendation: json['recommendation'] as String? ?? '',
      );
}

class LaunchpadDto {
  const LaunchpadDto({
    required this.journey,
    required this.milestones,
    required this.lessons,
    this.forecast,
  });

  final LaunchpadJourneyDto journey;
  final List<LaunchpadMilestoneDto> milestones;
  final List<LaunchpadLessonDto> lessons;
  final LaunchpadForecastDto? forecast;

  factory LaunchpadDto.fromJson(Map<String, dynamic> json) => LaunchpadDto(
    journey: LaunchpadJourneyDto.fromJson(
      (json['journey'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    milestones: (json['milestones'] as List<dynamic>? ?? const [])
        .map((e) => LaunchpadMilestoneDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    lessons: (json['lessons'] as List<dynamic>? ?? const [])
        .map((e) => LaunchpadLessonDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    forecast: switch ((json['forecast'] as Map?)?.cast<String, dynamic>()) {
      final Map<String, dynamic> value => LaunchpadForecastDto.fromJson(value),
      _ => null,
    },
  );
}
