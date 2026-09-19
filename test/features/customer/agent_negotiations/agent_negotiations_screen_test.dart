import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/agent_negotiations/presentation/agent_negotiations_screen.dart';

void main() {
  test('parses named protocol enums and proof bundle', () {
    final negotiation = AgentNegotiation.fromJson({
      'id': 'room-1',
      'status': 'AgreementPendingCustomer',
      'expiresUtc': '2026-09-18T14:00:00Z',
      'authorityLimit': 1000,
      'currency': 'NPR',
      'turns': [
        {
          'sequence': 1,
          'party': 'ShopperAgent',
          'kind': 'Proposal',
          'amount': 800,
          'currency': 'NPR',
          'terms': 'Complete basket',
          'proofBundleJson': '{"price":"quoted"}',
          'expiresUtc': '2026-09-18T12:20:00Z',
        },
      ],
    });

    expect(negotiation.status, 2);
    expect(negotiation.turns.single.party, 1);
    expect(negotiation.turns.single.kind, 1);
    expect(negotiation.turns.single.proofBundle['price'], 'quoted');
  });

  testWidgets('shows final terms, proof and explicit customer decision', (
    tester,
  ) async {
    final negotiation = AgentNegotiation(
      id: 'room-1',
      status: 2,
      expiresUtc: DateTime.utc(2026, 9, 18, 14),
      authorityLimit: 1000,
      currency: 'NPR',
      turns: [
        AgentNegotiationTurn(
          sequence: 1,
          party: 1,
          kind: 1,
          amount: 800,
          currency: 'NPR',
          terms: 'Complete basket',
          proofBundle: const {'price': 'quoted'},
          expiresUtc: DateTime.utc(2026, 9, 18, 12, 20),
        ),
        AgentNegotiationTurn(
          sequence: 2,
          party: 2,
          kind: 2,
          amount: 900,
          currency: 'NPR',
          terms: 'Ships today',
          proofBundle: const {'stock': 'held'},
          expiresUtc: DateTime.utc(2026, 9, 18, 12, 30),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentNegotiationsProvider.overrideWith(
            (ref) async => [negotiation],
          ),
        ],
        child: const MaterialApp(home: AgentNegotiationsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agents can negotiate. You decide.'), findsOneWidget);
    expect(find.text('YOUR DECISION'), findsOneWidget);
    expect(find.text('NPR 900'), findsOneWidget);
    expect(find.text('Ships today'), findsOneWidget);
    expect(find.text('stock: held'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('negotiation-confirm-room-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('negotiation-reject-room-1')),
      findsOneWidget,
    );
  });

  testWidgets('expands proof-bearing negotiation history', (tester) async {
    final negotiation = AgentNegotiation(
      id: 'room-2',
      status: 1,
      expiresUtc: DateTime.utc(2026, 9, 18, 14),
      authorityLimit: 1000,
      currency: 'NPR',
      turns: [
        AgentNegotiationTurn(
          sequence: 1,
          party: 1,
          kind: 1,
          amount: 800,
          currency: 'NPR',
          terms: 'Complete basket',
          proofBundle: const {'inventory': 'verified'},
          expiresUtc: DateTime.utc(2026, 9, 18, 12, 20),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentNegotiationsProvider.overrideWith(
            (ref) async => [negotiation],
          ),
        ],
        child: const MaterialApp(home: AgentNegotiationsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('negotiation-history-room-2')),
    );
    await tester.pump();

    expect(find.text('Your agent · offered NPR 800'), findsOneWidget);
    expect(find.text('Hide negotiation history'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('negotiation-confirm-room-2')),
      findsNothing,
    );
  });
}
