import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/entities/social_account.dart';

class AudioSuggestion {
  const AudioSuggestion({
    required this.trackTitle,
    required this.artist,
    required this.score,
    required this.rationale,
    this.externalListenUrl,
  });

  final String trackTitle;
  final String artist;
  final double score;
  final String rationale;
  final String? externalListenUrl;
}

class CaptionSuggestion {
  const CaptionSuggestion({
    required this.text,
    required this.tone,
    required this.engagementScoreEstimate,
  });

  final String text;
  final String tone;
  final double engagementScoreEstimate;
}

class PostTimeSuggestion {
  const PostTimeSuggestion({
    required this.suggestedAtUtc,
    required this.timeZone,
    required this.audienceActivityScore,
    required this.rationale,
  });

  final DateTime suggestedAtUtc;
  final String timeZone;
  final double audienceActivityScore;
  final String rationale;
}

class PredictedAudience {
  const PredictedAudience({
    this.primaryAgeBucket = '',
    this.primaryRegions = const <String>[],
    this.primaryGenderTilt = '',
    this.interestThemes = const <String>[],
    this.estimatedReachLow = 0,
    this.estimatedReachHigh = 0,
  });

  final String primaryAgeBucket;
  final List<String> primaryRegions;
  final String primaryGenderTilt;
  final List<String> interestThemes;
  final int estimatedReachLow;
  final int estimatedReachHigh;
}

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
    this.audioSuggestions = const <AudioSuggestion>[],
    this.captionVariants = const <CaptionSuggestion>[],
    this.hashtagsReach = const <String>[],
    this.hashtagsNiche = const <String>[],
    this.postTimeRecommendations = const <PostTimeSuggestion>[],
    this.predictedAudience = const PredictedAudience(),
    this.shelfLifePeakHours = 0,
    this.shelfLifeTailHours = 0,
  });

  final double overallScore; // 0.0 to 1.0
  final List<FeedbackArea> areas;
  final List<String> suggestions;
  final DateTime generatedAt;
  final List<AudioSuggestion> audioSuggestions;
  final List<CaptionSuggestion> captionVariants;
  final List<String> hashtagsReach;
  final List<String> hashtagsNiche;
  final List<PostTimeSuggestion> postTimeRecommendations;
  final PredictedAudience predictedAudience;
  final double shelfLifePeakHours;
  final double shelfLifeTailHours;

  CoachingFeedback copyWith({
    double? overallScore,
    List<FeedbackArea>? areas,
    List<String>? suggestions,
    DateTime? generatedAt,
    List<AudioSuggestion>? audioSuggestions,
    List<CaptionSuggestion>? captionVariants,
    List<String>? hashtagsReach,
    List<String>? hashtagsNiche,
    List<PostTimeSuggestion>? postTimeRecommendations,
    PredictedAudience? predictedAudience,
    double? shelfLifePeakHours,
    double? shelfLifeTailHours,
  }) {
    return CoachingFeedback(
      overallScore: overallScore ?? this.overallScore,
      areas: areas ?? this.areas,
      suggestions: suggestions ?? this.suggestions,
      generatedAt: generatedAt ?? this.generatedAt,
      audioSuggestions: audioSuggestions ?? this.audioSuggestions,
      captionVariants: captionVariants ?? this.captionVariants,
      hashtagsReach: hashtagsReach ?? this.hashtagsReach,
      hashtagsNiche: hashtagsNiche ?? this.hashtagsNiche,
      postTimeRecommendations:
          postTimeRecommendations ?? this.postTimeRecommendations,
      predictedAudience: predictedAudience ?? this.predictedAudience,
      shelfLifePeakHours: shelfLifePeakHours ?? this.shelfLifePeakHours,
      shelfLifeTailHours: shelfLifeTailHours ?? this.shelfLifeTailHours,
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
    this.recipeVersion = 1,
    this.songTitle = '',
    this.songArtist = '',
    this.intendedDurationSeconds = 0,
    this.thumbnailUrl,
    this.fromBrand = false,
  });

  final String id;
  final String title;
  final String description;
  final List<String> hashtags;
  final String suggestedMusic;
  final SocialPlatform platform;
  final int recipeVersion;
  final String songTitle;
  final String songArtist;
  final int intendedDurationSeconds;
  final String? thumbnailUrl;
  final bool fromBrand;

  ReelRecipe copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? hashtags,
    String? suggestedMusic,
    SocialPlatform? platform,
    int? recipeVersion,
    String? songTitle,
    String? songArtist,
    int? intendedDurationSeconds,
    String? thumbnailUrl,
    bool? fromBrand,
  }) {
    return ReelRecipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hashtags: hashtags ?? this.hashtags,
      suggestedMusic: suggestedMusic ?? this.suggestedMusic,
      platform: platform ?? this.platform,
      recipeVersion: recipeVersion ?? this.recipeVersion,
      songTitle: songTitle ?? this.songTitle,
      songArtist: songArtist ?? this.songArtist,
      intendedDurationSeconds:
          intendedDurationSeconds ?? this.intendedDurationSeconds,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      fromBrand: fromBrand ?? this.fromBrand,
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
