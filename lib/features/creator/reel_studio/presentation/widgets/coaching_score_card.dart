import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';

class CoachingScoreCard extends StatelessWidget {
  const CoachingScoreCard({
    required this.overallScore,
    required this.areas,
    required this.suggestions,
    super.key,
    this.audioSuggestions = const <AudioSuggestion>[],
    this.captionVariants = const <CaptionSuggestion>[],
    this.hashtagsReach = const <String>[],
    this.hashtagsNiche = const <String>[],
    this.postTimeRecommendations = const <PostTimeSuggestion>[],
    this.predictedAudience = const PredictedAudience(),
    this.shelfLifePeakHours = 0,
    this.shelfLifeTailHours = 0,
  });

  final double overallScore;
  final List<FeedbackArea> areas;
  final List<String> suggestions;
  final List<AudioSuggestion> audioSuggestions;
  final List<CaptionSuggestion> captionVariants;
  final List<String> hashtagsReach;
  final List<String> hashtagsNiche;
  final List<PostTimeSuggestion> postTimeRecommendations;
  final PredictedAudience predictedAudience;
  final double shelfLifePeakHours;
  final double shelfLifeTailHours;

  @override
  Widget build(BuildContext context) {
    final scorePercent = (overallScore * 100).round();
    final Color scoreColor = overallScore >= 0.7
        ? DesignTokens.primaryGreen
        : overallScore >= 0.4
        ? DesignTokens.warning500
        : DesignTokens.colorError;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.s16),
      decoration: BoxDecoration(
        color: DesignTokens.bgAppBody,
        borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.coffee,
                color: DesignTokens.warning500,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.s8),
              Text('AI Coaching', style: DesignTokens.h3),
            ],
          ),
          const SizedBox(height: DesignTokens.s16),
          Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: overallScore,
                    strokeWidth: 6,
                    backgroundColor: DesignTokens.bgAppBodyLight,
                    valueColor: AlwaysStoppedAnimation(scoreColor),
                  ),
                  Center(
                    child: Text(
                      '$scorePercent%',
                      style: DesignTokens.oneLinerSemibold.copyWith(
                        color: scoreColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.s16),
          ...areas.map((area) => _AreaBar(area: area)),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.s12),
            const Divider(color: DesignTokens.borderDefault),
            const SizedBox(height: DesignTokens.s8),
            Text('Suggestions', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: DesignTokens.warning500,
                      size: 16,
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: Text(s, style: DesignTokens.smallRegular),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (audioSuggestions.isNotEmpty) ...[
            const _SectionDivider(),
            Text('Audio references', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Preview in the source app. Style Mint does not stream audio.',
              style: DesignTokens.tiny.copyWith(color: DesignTokens.textMuted),
            ),
            const SizedBox(height: DesignTokens.s8),
            ...audioSuggestions.map(
              (audio) => Container(
                key: ValueKey('audio-reference-${audio.trackTitle}'),
                margin: const EdgeInsets.only(bottom: DesignTokens.s8),
                padding: const EdgeInsets.all(DesignTokens.s8),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.music_note_outlined,
                      color: DesignTokens.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            audio.trackTitle.isEmpty
                                ? 'Suggested audio'
                                : audio.trackTitle,
                            style: DesignTokens.mediumSemibold,
                          ),
                          if (audio.artist.isNotEmpty)
                            Text(audio.artist, style: DesignTokens.tiny),
                          if (audio.rationale.isNotEmpty)
                            Text(
                              audio.rationale,
                              style: DesignTokens.tiny.copyWith(
                                color: DesignTokens.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (audio.externalListenUrl != null)
                      IconButton(
                        tooltip: 'Listen externally',
                        onPressed: () => _openAudio(
                          context,
                          audio.externalListenUrl!,
                        ),
                        icon: const Icon(
                          Icons.open_in_new,
                          color: DesignTokens.primaryGreen,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (captionVariants.isNotEmpty) ...[
            const _SectionDivider(),
            Text('Caption variants', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            ...captionVariants.map(
              (caption) => Container(
                margin: const EdgeInsets.only(bottom: DesignTokens.s8),
                padding: const EdgeInsets.all(DesignTokens.s8),
                decoration: BoxDecoration(
                  color: DesignTokens.bgAppBodyLight,
                  borderRadius: BorderRadius.circular(DesignTokens.s8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (caption.tone.isNotEmpty)
                            Text(
                              '${caption.tone} · ${(caption.engagementScoreEstimate * 100).round()}%',
                              style: DesignTokens.tiny.copyWith(
                                color: DesignTokens.primaryGreen,
                              ),
                            ),
                          Text(caption.text, style: DesignTokens.smallRegular),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy caption',
                      onPressed: () => _copyText(
                        context,
                        caption.text,
                        'Caption copied',
                      ),
                      icon: const Icon(Icons.copy_outlined, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (hashtagsReach.isNotEmpty || hashtagsNiche.isNotEmpty) ...[
            const _SectionDivider(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Suggested hashtags',
                    style: DesignTokens.mediumSemibold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copyText(
                    context,
                    [...hashtagsReach, ...hashtagsNiche].join(' '),
                    'Hashtags copied',
                  ),
                  icon: const Icon(Icons.copy_outlined, size: 16),
                  label: const Text('Copy all'),
                ),
              ],
            ),
            Wrap(
              spacing: DesignTokens.s4,
              runSpacing: DesignTokens.s4,
              children: [
                ...hashtagsReach.map((tag) => _TagChip(tag: tag, reach: true)),
                ...hashtagsNiche.map((tag) => _TagChip(tag: tag, reach: false)),
              ],
            ),
          ],
          if (postTimeRecommendations.isNotEmpty) ...[
            const _SectionDivider(),
            Text('Best times to post', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            ...postTimeRecommendations.map(
              (time) => Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.s8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      color: DesignTokens.primaryGreen,
                      size: 18,
                    ),
                    const SizedBox(width: DesignTokens.s8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatAudienceTime(time),
                            style: DesignTokens.mediumSemibold,
                          ),
                          if (time.rationale.isNotEmpty)
                            Text(time.rationale, style: DesignTokens.tiny),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_hasAudience) ...[
            const _SectionDivider(),
            Text('Predicted audience', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s8),
            Wrap(
              spacing: DesignTokens.s4,
              runSpacing: DesignTokens.s4,
              children: [
                if (predictedAudience.primaryAgeBucket.isNotEmpty)
                  _AudienceChip(predictedAudience.primaryAgeBucket),
                if (predictedAudience.primaryGenderTilt.isNotEmpty)
                  _AudienceChip(predictedAudience.primaryGenderTilt),
                ...predictedAudience.primaryRegions.map(_AudienceChip.new),
                ...predictedAudience.interestThemes.map(_AudienceChip.new),
              ],
            ),
            if (predictedAudience.estimatedReachHigh > 0) ...[
              const SizedBox(height: DesignTokens.s8),
              Text(
                'Estimated reach ${predictedAudience.estimatedReachLow}–${predictedAudience.estimatedReachHigh}',
                style: DesignTokens.tiny,
              ),
            ],
          ],
          if (shelfLifePeakHours > 0 || shelfLifeTailHours > 0) ...[
            const _SectionDivider(),
            Text('Expected shelf life', style: DesignTokens.mediumSemibold),
            const SizedBox(height: DesignTokens.s4),
            Text(
              'Peak ${_hoursLabel(shelfLifePeakHours)} · Tail ${_hoursLabel(shelfLifeTailHours)}',
              style: DesignTokens.smallRegular,
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasAudience =>
      predictedAudience.primaryAgeBucket.isNotEmpty ||
      predictedAudience.primaryGenderTilt.isNotEmpty ||
      predictedAudience.primaryRegions.isNotEmpty ||
      predictedAudience.interestThemes.isNotEmpty ||
      predictedAudience.estimatedReachHigh > 0;

  Future<void> _openAudio(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this audio reference.')),
      );
    }
  }

  Future<void> _copyText(
    BuildContext context,
    String text,
    String confirmation,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(confirmation)),
      );
    }
  }

  String _formatAudienceTime(PostTimeSuggestion time) {
    try {
      final location = tz.getLocation(time.timeZone);
      final zoned = tz.TZDateTime.from(time.suggestedAtUtc, location);
      return '${DateFormat('EEE, MMM d · h:mm a').format(zoned)} · ${time.timeZone}';
    } on Exception {
      return '${DateFormat('EEE, MMM d · HH:mm').format(time.suggestedAtUtc)} UTC';
    }
  }

  String _hoursLabel(double hours) => hours == hours.roundToDouble()
      ? '${hours.round()}h'
      : '${hours.toStringAsFixed(1)}h';
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: DesignTokens.s12),
    child: Divider(color: DesignTokens.borderDefault),
  );
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag, required this.reach});

  final String tag;
  final bool reach;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: DesignTokens.s4,
    ),
    decoration: BoxDecoration(
      color: reach
          ? DesignTokens.chipsSelectedFill
          : DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
    ),
    child: Text(tag, style: DesignTokens.tiny),
  );
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DesignTokens.s8,
      vertical: DesignTokens.s4,
    ),
    decoration: BoxDecoration(
      color: DesignTokens.bgAppBodyLight,
      borderRadius: BorderRadius.circular(DesignTokens.chipRadius),
    ),
    child: Text(label, style: DesignTokens.tiny),
  );
}

class _AreaBar extends StatelessWidget {
  const _AreaBar({required this.area});

  final FeedbackArea area;

  @override
  Widget build(BuildContext context) {
    final Color barColor = area.score >= 0.7
        ? DesignTokens.primaryGreen
        : area.score >= 0.4
        ? DesignTokens.warning500
        : DesignTokens.colorError;

    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.s8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(area.label, style: DesignTokens.smallRegular),
          ),
          const SizedBox(width: DesignTokens.s8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.s4),
              child: LinearProgressIndicator(
                value: area.score,
                minHeight: 6,
                backgroundColor: DesignTokens.bgAppBodyLight,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.s8),
          SizedBox(
            width: 36,
            child: Text(
              '${(area.score * 100).round()}%',
              style: DesignTokens.tiny,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
