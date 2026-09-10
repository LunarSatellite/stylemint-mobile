import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/domain/entities/matchmaking.dart';
import 'package:stylemint_mobile_frontend/features/vendor/matchmaking/presentation/widgets/compatibility_score_widget.dart';

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
}
