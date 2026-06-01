import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

class FeedbackArea {
  const FeedbackArea({
    required this.label,
    required this.score,
  });

  final String label;
  final double score; // 0.0 to 1.0
}

class CoachingFeedback {
  const CoachingFeedback({
    required this.overallScore,
    required this.areas,
    required this.suggestions,
    required this.generatedAt,
  });

  final double overallScore; // 0.0 to 1.0
  final List<FeedbackArea> areas;
  final List<String> suggestions;
  final DateTime generatedAt;

  CoachingFeedback copyWith({
    double? overallScore,
    List<FeedbackArea>? areas,
    List<String>? suggestions,
    DateTime? generatedAt,
  }) {
    return CoachingFeedback(
      overallScore: overallScore ?? this.overallScore,
      areas: areas ?? this.areas,
      suggestions: suggestions ?? this.suggestions,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

class ReelRecipe {
  const ReelRecipe({
    required this.id,
    required this.title,
    required this.description,
    required this.hashtags,
    required this.suggestedMusic,
    required this.platform,
  });

  final String id;
  final String title;
  final String description;
  final List<String> hashtags;
  final String suggestedMusic;
  final SocialPlatform platform;

  ReelRecipe copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? hashtags,
    String? suggestedMusic,
    SocialPlatform? platform,
  }) {
    return ReelRecipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hashtags: hashtags ?? this.hashtags,
      suggestedMusic: suggestedMusic ?? this.suggestedMusic,
      platform: platform ?? this.platform,
    );
  }
}

enum ReelDraftStatus { draft, coaching, ready }

class ReelDraft {
  const ReelDraft({
    required this.id,
    required this.caption,
    required this.hashtags,
    required this.taggedProductIds,
    required this.platform,
    required this.status,
    this.coaching,
    required this.createdAt,
  });

  final String id;
  final String caption;
  final List<String> hashtags;
  final List<String> taggedProductIds;
  final SocialPlatform platform;
  final ReelDraftStatus status;
  final CoachingFeedback? coaching;
  final DateTime createdAt;

  ReelDraft copyWith({
    String? id,
    String? caption,
    List<String>? hashtags,
    List<String>? taggedProductIds,
    SocialPlatform? platform,
    ReelDraftStatus? status,
    CoachingFeedback? coaching,
    DateTime? createdAt,
  }) {
    return ReelDraft(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      hashtags: hashtags ?? this.hashtags,
      taggedProductIds: taggedProductIds ?? this.taggedProductIds,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      coaching: coaching ?? this.coaching,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
