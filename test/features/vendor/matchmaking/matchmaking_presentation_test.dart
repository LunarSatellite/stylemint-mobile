import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/widgets/compatibility_score_widget.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/entities/vendor_partnership.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/presentation/screens/send_partnership_request_screen.dart';

void main() {
  group('MatchRecommendation presentation', () {
    test('normalizes an API handle for its label and avatar', () {
      const recommendation = MatchRecommendation(
        id: 'match-1',
        creatorAccountId: 'creator-1',
        creatorHandle: '@techwithrohan',
        compatibilityScore: 28,
        reasonSummary: 'Strong fit.',
      );

      expect(recommendation.displayCreatorHandle, '@techwithrohan');
      expect(recommendation.creatorInitial, 'T');
    });

    test('degrades safely when a handle only contains at signs', () {
      const recommendation = MatchRecommendation(
        id: 'match-1',
        creatorAccountId: 'creator-1',
        creatorHandle: '@@',
        compatibilityScore: 28,
        reasonSummary: 'Strong fit.',
      );

      expect(recommendation.displayCreatorHandle, '@unknown');
      expect(recommendation.creatorInitial, '?');
    });
  });

  test('creator invite normalizes API handles that already include @', () {
    const creator = CreatorInvite(
      creatorAccountId: 'creator-1',
      handle: '@techwithrohan',
    );

    expect(creator.displayHandle, '@techwithrohan');
    expect(creator.label, '@techwithrohan');
  });
  testWidgets('compatibility score has one meaningful semantics label', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CompatibilityScoreWidget(score: 28)),
      ),
    );

    expect(find.bySemanticsLabel('28% compatibility'), findsOneWidget);
    expect(find.bySemanticsLabel('28%'), findsNothing);

    semantics.dispose();
  });
  testWidgets('partnership request accepts the matchmaking prefill', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SendPartnershipRequestScreen(
            initialCreator: CreatorInvite(
              creatorAccountId: 'creator-1',
              handle: 'techwithrohan',
            ),
            initialCommissionPercent: 12.5,
            brandBriefId: 'brief-1',
          ),
        ),
      ),
    );

    expect(find.text('@techwithrohan'), findsOneWidget);
    expect(find.text('Matched creator'), findsOneWidget);
    final commission = tester.widget<TextField>(find.byType(TextField).first);
    expect(commission.controller!.text, '12.5');
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });
}
