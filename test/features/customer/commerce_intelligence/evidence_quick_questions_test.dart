import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/domain/entities/evidence_answer.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/presentation/widgets/evidence_answer_panel.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/shared/providers.dart';

import 'evidence_fixtures.dart';

const _productId = '11111111-1111-1111-1111-111111111111';

Future<FakeCommerceIntelligenceRepository> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? payload,
  List<String> quickQuestions = EvidenceAnswerPanel.productQuestions,
  bool autoAsk = false,
}) async {
  final repository = FakeCommerceIntelligenceRepository(
    result: payload == null ? null : answerFrom(payload),
  );
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        commerceIntelligenceRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EvidenceAnswerPanel(
              familyKey: 'quick',
              seedQuery: 'Linen shirt',
              currentProductId: _productId,
              now: kNow,
              autoAsk: autoAsk,
              quickQuestions: quickQuestions,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

Map<String, dynamic> _scopedAnswer({
  String mode = 'grounded-ai',
  List<String> cited = const ['f-material'],
}) => {
  ...answerJson(
    query: 'What is it made of?',
    answer: 'It is made of 100% linen.',
    evidence: [
      factJson(),
      {
        ...factJson(
          factId: 'f-material',
          kind: 'provenance:material',
          statement: 'Material: 100% linen',
        ),
        'kindLabel': 'Material',
      },
    ],
  ),
  'answerMode': mode,
  'citedFactIds': cited,
};

void main() {
  group('dto', () {
    test('reads answerMode, citedFactIds and kindLabel', () {
      final answer = answerFrom(_scopedAnswer());
      expect(answer.isGroundedAi, isTrue);
      expect(answer.citedFactIds, ['f-material']);
      expect(answer.citedFacts.single.kindLabel, 'Material');
    });

    test('an older backend without the new fields still parses', () {
      final answer = answerFrom(answerJson());
      expect(answer.answerMode, EvidenceAnswer.summaryMode);
      expect(answer.citedFactIds, isEmpty);
      expect(answer.evidence.single.kindLabel, isNull);
    });

    test('a cited id the backend did not send is not drawn', () {
      final answer = answerFrom(_scopedAnswer(cited: ['f-material', 'ghost']));
      expect(answer.citedFacts.map((f) => f.factId), ['f-material']);
    });
  });

  group('quick questions', () {
    testWidgets('are offered on the product page', (tester) async {
      await _pump(tester);
      expect(find.byKey(EvidenceAnswerPanel.chipsKey), findsOneWidget);
      for (final question in EvidenceAnswerPanel.productQuestions) {
        expect(find.text(question), findsOneWidget);
      }
      expect(find.text('When should I reorder?'), findsNothing);
    });

    testWidgets('are not drawn when none are given', (tester) async {
      await _pump(tester, quickQuestions: const []);
      expect(find.byKey(EvidenceAnswerPanel.chipsKey), findsNothing);
    });

    testWidgets('tapping one fills the field and asks about this product', (
      tester,
    ) async {
      final repository = await _pump(tester, payload: _scopedAnswer());

      await tester.tap(find.text('What is it made of?'));
      await tester.pumpAndSettle();

      expect(repository.queries, ['What is it made of?']);
      expect(repository.productIds, [_productId]);
      final field = tester.widget<TextField>(
        find.byKey(EvidenceAnswerPanel.fieldKey),
      );
      expect(field.controller!.text, 'What is it made of?');
    });

    testWidgets('typed questions are product-scoped too', (tester) async {
      final repository = await _pump(tester, autoAsk: true);
      expect(repository.productIds, [_productId]);
    });
  });

  group('the answer sentence', () {
    testWidgets('shows the sentence and highlights the cited record', (
      tester,
    ) async {
      await _pump(tester, payload: _scopedAnswer(), autoAsk: true);

      expect(find.byKey(EvidenceAnswerPanel.answerKey), findsOneWidget);
      expect(find.text('It is made of 100% linen.'), findsOneWidget);
      expect(
        find.byKey(EvidenceAnswerPanel.citedKey('f-material')),
        findsOneWidget,
      );
      expect(find.byKey(EvidenceAnswerPanel.citedKey('f-1')), findsNothing);
      expect(find.text('Used in the answer'), findsOneWidget);
      expect(find.text('Based on: Material'), findsOneWidget);
    });

    testWidgets('records still come before the sentence', (tester) async {
      await _pump(tester, payload: _scopedAnswer(), autoAsk: true);
      final factY = tester.getTopLeft(find.text('Material: 100% linen')).dy;
      final answerY = tester
          .getTopLeft(find.byKey(EvidenceAnswerPanel.answerKey))
          .dy;
      expect(factY, lessThan(answerY));
    });

    testWidgets('a model-written sentence is labelled as such', (tester) async {
      await _pump(tester, payload: _scopedAnswer(), autoAsk: true);
      expect(
        find.textContaining(
          RegExp('written by ai', caseSensitive: false),
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

    testWidgets('a summary sentence is not labelled as AI', (tester) async {
      await _pump(
        tester,
        payload: _scopedAnswer(mode: 'summary'),
        autoAsk: true,
      );
      expect(
        find.textContaining(
          RegExp('written by ai', caseSensitive: false),
          findRichText: true,
        ),
        findsNothing,
      );
    });

    testWidgets('the backend label replaces the raw kind token', (
      tester,
    ) async {
      await _pump(tester, payload: _scopedAnswer(), autoAsk: true);
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' | ');
      expect(texts.toLowerCase(), isNot(contains('provenance')));
    });
  });
}
