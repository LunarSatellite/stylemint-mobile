import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';

class ReelStudioBriefingDto {
  const ReelStudioBriefingDto({
    required this.hookScore,
    required this.body,
    required this.explanationByKey,
    required this.computedUtc,
  });

  factory ReelStudioBriefingDto.fromJson(Map<String, dynamic> json) {
    return ReelStudioBriefingDto(
      hookScore: (json['hookScore'] as num?)?.toDouble() ?? 0,
      body: (json['body'] as Map?)?.cast<String, dynamic>() ?? const {},
      explanationByKey:
          (json['explanationByKey'] as Map?)?.cast<String, dynamic>() ??
          const {},
      computedUtc:
          DateTime.tryParse(json['computedUtc']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  final double hookScore;
  final Map<String, dynamic> body;
  final Map<String, dynamic> explanationByKey;
  final DateTime computedUtc;

  CoachingFeedback toDomain() {
    final captions = (body['captionVariants'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final captionScores = captions
        .map((item) => (item['engagementScoreEstimate'] as num?)?.toDouble())
        .whereType<double>()
        .toList(growable: false);
    final suggestions = <String>[
      if (explanationByKey['hook'] case final String hook when hook.isNotEmpty)
        hook,
      ...captions
          .take(3)
          .map((item) {
            final tone = item['tone']?.toString().trim();
            final text = item['text']?.toString().trim() ?? '';
            return tone == null || tone.isEmpty
                ? text
                : '${tone[0].toUpperCase()}${tone.substring(1)}: $text';
          })
          .where((text) => text.isNotEmpty),
      if (_hashtags.isNotEmpty) 'Suggested hashtags: ${_hashtags.join(' ')}',
    ];
    final areas = <FeedbackArea>[
      FeedbackArea(label: 'Hook', score: hookScore.clamp(0, 1)),
      if (captionScores.isNotEmpty)
        FeedbackArea(
          label: 'Captions',
          score: (captionScores.reduce((a, b) => a + b) / captionScores.length)
              .clamp(0, 1),
        ),
    ];
    final audioSuggestions = (body['audioSuggestions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AudioSuggestion(
            trackTitle: item['trackTitle']?.toString() ?? '',
            artist: item['artist']?.toString() ?? '',
            score: ((item['score'] as num?)?.toDouble() ?? 0).clamp(0, 1),
            rationale: item['rationale']?.toString() ?? '',
            externalListenUrl: switch (item['externalListenUrl']
                ?.toString()
                .trim()) {
              final String value when value.isNotEmpty => value,
              _ => null,
            },
          ),
        )
        .toList(growable: false);
    final captionVariants = captions
        .map(
          (item) => CaptionSuggestion(
            text: item['text']?.toString() ?? '',
            tone: item['tone']?.toString() ?? '',
            engagementScoreEstimate:
                ((item['engagementScoreEstimate'] as num?)?.toDouble() ?? 0)
                    .clamp(0, 1),
          ),
        )
        .where((item) => item.text.trim().isNotEmpty)
        .toList(growable: false);
    final postTimes = (body['postTimeRecommendations'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => PostTimeSuggestion(
            suggestedAtUtc:
                DateTime.tryParse(
                  item['suggestedAtUtc']?.toString() ?? '',
                )?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            timeZone: item['timeZone']?.toString() ?? 'Asia/Kathmandu',
            audienceActivityScore:
                ((item['audienceActivityScore'] as num?)?.toDouble() ?? 0)
                    .clamp(0, 1),
            rationale: item['rationale']?.toString() ?? '',
          ),
        )
        .where((item) => item.suggestedAtUtc.millisecondsSinceEpoch > 0)
        .toList(growable: false);
    final audienceJson =
        (body['predictedAudience'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return CoachingFeedback(
      overallScore: hookScore.clamp(0, 1),
      areas: areas,
      suggestions: suggestions,
      generatedAt: computedUtc,
      audioSuggestions: audioSuggestions,
      captionVariants: captionVariants,
      hashtagsReach: _stringList(body['hashtagsReach']),
      hashtagsNiche: _stringList(body['hashtagsNiche']),
      postTimeRecommendations: postTimes,
      predictedAudience: PredictedAudience(
        primaryAgeBucket: audienceJson['primaryAgeBucket']?.toString() ?? '',
        primaryRegions: _stringList(audienceJson['primaryRegions']),
        primaryGenderTilt: audienceJson['primaryGenderTilt']?.toString() ?? '',
        interestThemes: _stringList(audienceJson['interestThemes']),
        estimatedReachLow:
            (audienceJson['estimatedReachLow'] as num?)?.toInt() ?? 0,
        estimatedReachHigh:
            (audienceJson['estimatedReachHigh'] as num?)?.toInt() ?? 0,
      ),
      shelfLifePeakHours: (body['shelfLifePeakHours'] as num?)?.toDouble() ?? 0,
      shelfLifeTailHours: (body['shelfLifeTailHours'] as num?)?.toDouble() ?? 0,
    );
  }

  List<String> _stringList(dynamic value) => (value as List? ?? const [])
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);

  List<String> get _hashtags => [
    ...(body['hashtagsReach'] as List? ?? const []).map((item) => '$item'),
    ...(body['hashtagsNiche'] as List? ?? const []).map((item) => '$item'),
  ].where((tag) => tag.trim().isNotEmpty).take(8).toList(growable: false);
}
