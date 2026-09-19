import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/presentation/widgets/evidence_answer_panel.dart';
import 'package:stylemint_mobile_frontend/features/customer/commerce_intelligence/shared/providers.dart';

import 'evidence_fixtures.dart';

/// A phone that is small and set large: the combination that overflows.
const _narrow = Size(320, 640);
const _bigText = TextScaler.linear(1.3);

Future<FakeCommerceIntelligenceRepository> _pump(
  WidgetTester tester, {
  Map<String, dynamic>? payload,
  NetworkExceptions? failure,
  String seedQuery = 'Atelier Nord parka',
  String? currentProductId,
  DateTime? now,
  Size size = const Size(390, 844),
  TextScaler scaler = TextScaler.noScaling,
}) async {
  final repository = FakeCommerceIntelligenceRepository(
    result: payload == null ? null : answerFrom(payload),
    failure: failure,
  );

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        commerceIntelligenceRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: scaler),
          child: Scaffold(
            body: SingleChildScrollView(
              child: EvidenceAnswerPanel(
                familyKey: 'test',
                seedQuery: seedQuery,
                currentProductId: currentProductId,
                now: now ?? kNow,
                autoAsk: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Every string the tree actually draws, so a test can assert on what a
/// reader sees rather than on which widget drew it.
List<String> _renderedText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
    .toList();

/// Every spoken label, for the same reason.
List<String> _semanticLabels(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .map((node) => node.properties.label ?? '')
    .where((label) => label.isNotEmpty)
    .toList();

void main() {
  group('an answer with evidence', () {
    testWidgets('draws every fact it rests on, unfolded', (tester) async {
      await _pump(
        tester,
        payload: answerJson(
          evidence: [
            factJson(statement: 'Atelier Nord is verified'),
            factJson(
              factId: 'f-2',
              kind: 'provenance:origin',
              statement: 'Woven in Biella, Italy',
              confidence: 0.65,
            ),
          ],
        ),
      );

      expect(find.text('Atelier Nord is verified'), findsOneWidget);
      expect(find.text('Woven in Biella, Italy'), findsOneWidget);
      expect(find.text('What this rests on'), findsOneWidget);
      expect(find.text('2 records, each shown in full.'), findsOneWidget);
      // No disclosure widget stands between the reader and the evidence.
      expect(find.byType(ExpansionTile), findsNothing);
    });

    testWidgets('humanises the backend kind token without renaming it', (
      tester,
    ) async {
      await _pump(
        tester,
        // The fixture's default kind is the backend's own token.
        payload: answerJson(evidence: [factJson()]),
      );
      // MallEyebrow sets its own case; the token itself is untouched.
      expect(find.text('VENDOR VERIFICATION'), findsOneWidget);
    });

    testWidgets('an unknown kind survives rather than being dropped', (
      tester,
    ) async {
      await _pump(
        tester,
        payload: answerJson(
          evidence: [factJson(kind: 'carbon-ledger:tier-2')],
        ),
      );
      expect(find.text('CARBON LEDGER TIER 2'), findsOneWidget);
    });

    testWidgets('the prose summary is placed after the records', (
      tester,
    ) async {
      await _pump(
        tester,
        payload: answerJson(
          answer: 'This seller is verified.',
          evidence: [factJson(statement: 'Atelier Nord is verified')],
        ),
      );

      final factY = tester.getTopLeft(find.text('Atelier Nord is verified')).dy;
      final summaryY = tester
          .getTopLeft(find.text('This seller is verified.'))
          .dy;
      expect(summaryY, greaterThan(factY));
    });

    testWidgets('renders the backend limitations verbatim', (tester) async {
      await _pump(
        tester,
        payload: answerJson(
          limitations: const ['Some evidence is uncertain; verify it.'],
        ),
      );
      expect(
        find.text('Some evidence is uncertain; verify it.'),
        findsOneWidget,
      );
    });

    testWidgets('a forecast names the facts it rests on', (tester) async {
      await _pump(
        tester,
        payload: answerJson(
          evidence: [
            factJson(statement: 'Runs out in about 5 days'),
          ],
          consequences: [
            consequenceJson(outcome: 'Waiting may create a gap.'),
          ],
        ),
      );

      expect(find.text('Waiting may create a gap.'), findsOneWidget);
      expect(find.text('Rests on'), findsOneWidget);
      expect(find.text('Runs out in about 5 days'), findsNWidgets(2));
      expect(find.text('Probability the backend gave: 62%'), findsOneWidget);
      expect(find.text('within 5 days'), findsOneWidget);
    });

    testWidgets('a zero horizon draws no horizon line', (tester) async {
      await _pump(
        tester,
        payload: answerJson(
          consequences: [consequenceJson(horizonDays: 0)],
        ),
      );
      expect(
        _renderedText(tester).where((t) => t.contains('within')),
        isEmpty,
      );
    });
  });

  group('as-of timing in plain language', () {
    testWidgets('a current answer says when the evidence stood', (
      tester,
    ) async {
      await _pump(tester, payload: answerJson());
      expect(
        _renderedText(tester).any(
          (text) => text.startsWith('Evidence as it stood at'),
        ),
        isTrue,
      );
    });

    testWidgets('a historical answer says so without calling it stale', (
      tester,
    ) async {
      await _pump(
        tester,
        payload: answerJson(asOfUtc: '2026-08-01T09:00:00Z'),
      );

      final line = _renderedText(tester).firstWhere(
        (text) => text.contains('how things stood'),
        orElse: () => '',
      );
      expect(line, contains('not necessarily how they stand now'));
      expect(line, contains('Aug 1, 2026'));
    });

    testWidgets('a missing as-of makes no claim about time at all', (
      tester,
    ) async {
      await _pump(tester, payload: answerJson(asOfUtc: null));
      final texts = _renderedText(tester).join(' | ');
      expect(texts, isNot(contains('Evidence as it stood')));
      expect(texts, isNot(contains('how things stood')));
    });

    testWidgets('a fact draws its own validity window', (tester) async {
      await _pump(
        tester,
        payload: answerJson(
          evidence: [
            factJson(validToUtc: '2026-10-01T00:00:00Z'),
          ],
        ),
      );
      expect(
        _renderedText(tester).any(
          (text) => text.startsWith('True from') && text.contains('until'),
        ),
        isTrue,
      );
    });

    testWidgets('a fact with no timestamps draws no time lines', (
      tester,
    ) async {
      await _pump(
        tester,
        payload: answerJson(
          evidence: [
            factJson(validFromUtc: null, observedUtc: null),
          ],
        ),
      );
      final texts = _renderedText(tester).join(' | ');
      expect(texts, isNot(contains('True since')));
      expect(texts, isNot(contains('Recorded')));
    });
  });

  group('an answer with no evidence', () {
    testWidgets('is not presented as an answer', (tester) async {
      await _pump(
        tester,
        payload: answerJson(
          answer: 'I could not find evidence that was valid as of …',
          evidence: const [],
          limitations: const [
            'No time-valid commerce evidence matched this question.',
          ],
        ),
      );

      // The backend's prose is suppressed outright.
      expect(
        find.text('I could not find evidence that was valid as of …'),
        findsNothing,
      );
      expect(find.text('No evidence answers this yet'), findsOneWidget);
      // The backend's own account of why is still shown.
      expect(
        find.text('No time-valid commerce evidence matched this question.'),
        findsOneWidget,
      );
      // No "In short" block, because there is no short.
      expect(find.text('In short, from the records above'), findsNothing);
    });

    testWidgets('still says which moment was searched', (tester) async {
      await _pump(
        tester,
        payload: answerJson(evidence: const []),
      );
      expect(
        _renderedText(tester).any((text) => text.contains('Evidence as it')),
        isTrue,
      );
    });
  });

  group('nothing is invented', () {
    testWidgets(
      'no confidence, probability, score or badge appears when the '
      'backend sent none',
      (tester) async {
        await _pump(
          tester,
          payload: answerJson(
            evidence: [factJson()..remove('confidence')],
            consequences: [consequenceJson()..remove('probability')],
          ),
        );

        final visible = [
          ..._renderedText(tester),
          ..._semanticLabels(tester),
        ].join(' | ').toLowerCase();

        for (final forbidden in const [
          'confidence',
          'probability',
          '%',
          'verified badge',
          'score',
          'rating',
          'out of 5',
          'trusted',
          'recommended',
        ]) {
          expect(
            visible,
            isNot(contains(forbidden)),
            reason: '"$forbidden" was drawn but the backend never sent it',
          );
        }
        expect(find.byIcon(Icons.star), findsNothing);
        expect(find.byIcon(Icons.star_rounded), findsNothing);
        expect(find.byIcon(Icons.verified), findsNothing);
      },
    );

    testWidgets('a confidence the backend did send is attributed to it', (
      tester,
    ) async {
      await _pump(
        tester,
        payload: answerJson(
          evidence: [factJson()],
        ),
      );
      expect(
        find.text(
          'Source confidence 95%, reported by catalog.product-passport',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an unrecognised forecast direction reads neutrally', (
      tester,
    ) async {
      await _pump(
        tester,
        payload: answerJson(
          consequences: [consequenceJson(direction: 'something-new')],
        ),
      );
      expect(find.text('Something new'), findsOneWidget);
    });
  });

  group('safety', () {
    testWidgets('offers nothing that could mutate a cart or an order', (
      tester,
    ) async {
      await _pump(
        tester,
        payload: answerJson(consequences: [consequenceJson()]),
      );

      final visible = [
        ..._renderedText(tester),
        ..._semanticLabels(tester),
      ].join(' | ').toLowerCase();

      for (final forbidden in const [
        'add to bag',
        'add to cart',
        'buy now',
        'checkout',
        'reserve',
        'pay',
        'order now',
      ]) {
        expect(visible, isNot(contains(forbidden)));
      }
      expect(find.byIcon(Icons.shopping_bag_outlined), findsNothing);
      expect(find.byIcon(Icons.shopping_cart), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('a fact about this very product offers no link to itself', (
      tester,
    ) async {
      await _pump(
        tester,
        currentProductId: '11111111-1111-1111-1111-111111111111',
        payload: answerJson(),
      );
      expect(find.text('Open this product'), findsNothing);
    });

    testWidgets('a fact about another product offers a plain open link', (
      tester,
    ) async {
      await _pump(
        tester,
        currentProductId: 'a-different-product',
        payload: answerJson(),
      );
      expect(find.text('Open this product'), findsOneWidget);
    });

    testWidgets('the question is sent with no as-of, leaving time to the '
        'server clock', (tester) async {
      final repository = await _pump(tester, payload: answerJson());
      expect(repository.queries, ['Atelier Nord parka']);
      expect(repository.asOfArguments, [null]);
    });
  });

  group('failure', () {
    testWidgets('shows no answer at all when the call fails', (tester) async {
      await _pump(
        tester,
        failure: const NetworkExceptions.serverUnavailable(),
      );

      expect(
        find.text('That question could not be answered'),
        findsOneWidget,
      );
      expect(find.text('What this rests on'), findsNothing);
      expect(find.text('In short, from the records above'), findsNothing);
    });
  });

  group('layout and semantics', () {
    testWidgets('does not overflow at 320dp with text scale 1.3', (
      tester,
    ) async {
      await _pump(
        tester,
        size: _narrow,
        scaler: _bigText,
        payload: answerJson(
          evidence: [
            factJson(
              statement:
                  'Atelier Nord has verified seller identity under the '
                  'product passport scheme, recorded by the catalogue',
              sourceReference:
                  '/v1/public/products/11111111-1111-1111-1111-111111111111'
                  '/passport',
            ),
            factJson(
              factId: 'f-2',
              kind: 'replenishment',
              statement: 'Merino base layer: you usually reorder every 46 days',
            ),
          ],
          consequences: [consequenceJson()],
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the evidence-free state also survives 320dp at 1.3', (
      tester,
    ) async {
      await _pump(
        tester,
        size: _narrow,
        scaler: _bigText,
        payload: answerJson(evidence: const []),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('every control carries a semantics label', (tester) async {
      await _pump(
        tester,
        currentProductId: 'a-different-product',
        payload: answerJson(),
      );

      final labels = _semanticLabels(tester);
      expect(labels, contains('Ask a question about this product'));
      expect(labels, contains('Ask and show the evidence'));
      expect(labels, contains('Open the product this record is about'));
      expect(
        labels.any((label) => label.startsWith('Evidence digest')),
        isTrue,
      );
    });
  });
}
