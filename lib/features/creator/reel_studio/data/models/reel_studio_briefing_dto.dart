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
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
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
    return CoachingFeedback(
      overallScore: hookScore.clamp(0, 1),
      areas: areas,
      suggestions: suggestions,
      generatedAt: computedUtc,
    );
  }

  List<String> get _hashtags => [
    ...(body['hashtagsReach'] as List? ?? const []).map((item) => '$item'),
    ...(body['hashtagsNiche'] as List? ?? const []).map((item) => '$item'),
  ].where((tag) => tag.trim().isNotEmpty).take(8).toList(growable: false);
}
