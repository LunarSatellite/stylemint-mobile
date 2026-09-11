import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_date.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/data/models/reel_studio_extras_dto.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/domain/entities/reel_studio_extras.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/widgets/coaching_score_card.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/presentation/widgets/studio_insights_section.dart';
import 'package:stylemint_mobile_frontend/features/creator/reel_studio/shared/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  initTimezone();

  testWidgets('launchpad renders the nested journey response', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          launchpadProvider.overrideWith(
            (ref) async => _launchpad,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: StudioLaunchpadSection(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('studio-launchpad')), findsOneWidget);
    expect(find.text('Growing'), findsOneWidget);
    expect(find.text('Publish 25 reels'), findsOneWidget);
    expect(find.text('48%'), findsOneWidget);
    expect(find.textContaining('NPR 5000'), findsOneWidget);
    expect(find.textContaining('Make a stronger hook'), findsOneWidget);
  });

  testWidgets('personalised ideas render all live insight kinds', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          collabSuggestionsProvider.overrideWith(
            (ref) async => const [
              CollabSuggestion(
                otherCreatorId: 'creator-id',
                sharedProductId: 'product-id',
                otherCreatorHandle: 'qa_creator',
                sharedProductName: 'QA Jacket',
                matchReason: 'Your audiences overlap.',
              ),
            ],
          ),
          dropPartyPromptProvider.overrideWith(
            (ref) async => const DropPartyPrompt(
              vendorAccountId: 'vendor-id',
              highPerformingReelCount: 3,
              vendorName: 'QA Brand',
              suggestionText: 'Your recent launches are performing well.',
            ),
          ),
          tagNudgesProvider.overrideWith(
            (ref) async => const [
              TagNudge(
                reelId: 'reel-id',
                suggestedProductId: 'product-id',
                productName: 'QA Jacket',
                reason: 'It complements your recent reel.',
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StudioIdeasSection(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('studio-personalised-ideas')),
      findsOneWidget,
    );
    expect(find.textContaining('QA Brand'), findsOneWidget);
    expect(find.textContaining('@qa_creator'), findsOneWidget);
    expect(find.textContaining('Tag QA Jacket'), findsOneWidget);
  });

  testWidgets('briefing renders external audio and copyable variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CoachingScoreCard(
              overallScore: 0.8,
              areas: [FeedbackArea(label: 'Hook', score: 0.8)],
              suggestions: ['Keep the opening visual.'],
              audioSuggestions: [
                AudioSuggestion(
                  trackTitle: 'Reference Track',
                  artist: 'QA Artist',
                  score: 0.9,
                  rationale: 'Matches the pacing.',
                  externalListenUrl: 'https://example.com/listen',
                ),
              ],
              captionVariants: [
                CaptionSuggestion(
                  text: 'Lead with the finished look.',
                  tone: 'hook',
                  engagementScoreEstimate: 0.75,
                ),
              ],
              hashtagsReach: ['#style'],
              hashtagsNiche: ['#nepalstyle'],
              postTimeRecommendations: [
                PostTimeSuggestion(
                  suggestedAtUtc: _postTime,
                  timeZone: 'Asia/Kathmandu',
                  audienceActivityScore: 0.9,
                  rationale: 'Your audience is active then.',
                ),
              ],
              predictedAudience: PredictedAudience(
                primaryAgeBucket: '18–24',
                primaryRegions: ['Kathmandu'],
                estimatedReachLow: 1000,
                estimatedReachHigh: 2200,
              ),
              shelfLifePeakHours: 6,
              shelfLifeTailHours: 48,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audio references'), findsOneWidget);
    expect(find.text('Reference Track'), findsOneWidget);
    expect(find.byTooltip('Listen externally'), findsOneWidget);
    expect(find.text('Caption variants'), findsOneWidget);
    expect(find.byTooltip('Copy caption'), findsOneWidget);
    expect(find.textContaining('Asia/Kathmandu'), findsOneWidget);
    expect(find.textContaining('Estimated reach 1000–2200'), findsOneWidget);
    expect(find.text('Peak 6h · Tail 48h'), findsOneWidget);
  });
}

final _postTime = DateTime.utc(2026, 9, 12, 10);

const _launchpad = LaunchpadDto(
  journey: LaunchpadJourneyDto(
    currentPhase: 'Growing',
    totalReelsPublished: 12,
    totalRevenue: 3450.5,
    totalFollowers: 900,
    totalPartnerships: 2,
    nextMilestoneProgress: {'reels_25': 48},
  ),
  milestones: [
    LaunchpadMilestoneDto(
      key: 'reels_25',
      name: 'Publish 25 reels',
      description: 'Keep building your catalog.',
      completionPercent: 48,
      isCompleted: false,
    ),
  ],
  lessons: [
    LaunchpadLessonDto(
      id: 'lesson-id',
      title: 'Make a stronger hook',
      category: 'Production',
      content: 'Start with the result.',
      readingTimeMinutes: 4,
      difficultyLevel: 1,
      unlockPhase: 'Growing',
    ),
  ],
  forecast: LaunchpadForecastDto(
    projectedMonthlyEarnings: 5000,
    projectedMonthLabel: 'October 2026',
    growthRatePercent: 12.5,
    projectedReels: 8,
    projectedFollowers: 1100,
    recommendation: 'Publish twice a week.',
  ),
);
