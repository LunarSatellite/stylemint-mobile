import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/vendor/demand_signals/presentation/widgets/intent_decision_board_panel.dart';

void main() {
  test('parses merchant action evidence and governance', () {
    final board = IntentDecisionBoard.fromJson({
      'governance':
          'Pseudonyms are never returned; evidence expires after 90 days.',
      'channels': [
        {'channel': 'Cart', 'signalCount': 4, 'knownShopperCount': 3},
      ],
      'opportunities': [
        {
          'subject': 'variant:abc',
          'searches': 2,
          'unmetSearches': 1,
          'cartActions': 4,
          'purchases': 1,
          'purchaseConversionPercent': 25,
          'recommendation': 'protect_availability',
        },
      ],
    });

    expect(board.channels.single.knownShopperCount, 3);
    expect(board.opportunities.single.action, 'Protect stock availability');
    expect(board.governance, contains('90 days'));
  });

  testWidgets('loads lazily and renders ranked next move', (tester) async {
    const board = IntentDecisionBoard(
      governance: 'Aggregated only; raw signals expire after 90 days.',
      channels: [],
      opportunities: [
        IntentOpportunity(
          subject: 'linen saree',
          searches: 8,
          unmet: 5,
          cartActions: 0,
          purchases: 0,
          conversion: 0,
          recommendation: 'assess_catalog_gap',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          intentDecisionBoardProvider(7).overrideWith((ref) async => board),
        ],
        child: const MaterialApp(
          home: Scaffold(body: IntentDecisionBoardPanel(days: 7)),
        ),
      ),
    );

    expect(find.text('Intent decision board'), findsOneWidget);
    expect(find.text('linen saree'), findsNothing);
    await tester.tap(find.byKey(IntentDecisionBoardPanel.loadKey));
    await tester.pumpAndSettle();
    expect(find.text('linen saree'), findsOneWidget);
    expect(find.text('Consider stocking this gap'), findsOneWidget);
    expect(find.textContaining('8 search'), findsOneWidget);
  });
}
