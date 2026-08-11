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
