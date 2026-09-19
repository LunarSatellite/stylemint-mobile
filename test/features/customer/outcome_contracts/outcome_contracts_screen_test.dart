import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/outcome_contracts/presentation/outcome_contracts_screen.dart';

void main() {
  test('parses enum names and authoritative delivery progress', () {
    final contract = OutcomeContract.fromJson({
      'id': 'contract-1',
      'missionText': 'Build a complete work edit',
      'deadlineUtc': '2026-09-25T12:00:00Z',
      'status': 'Active',
      'recoveryObligation': 'CustomerCredit',
      'assurancePrice': 120,
      'currency': 'NPR',
      'orderId': 'order-1',
      'deliveredProductIds': ['product-1'],
      'plan': {
        'items': [
          {'productId': 'product-1'},
          {'productId': 'product-2'},
        ],
      },
    });

    expect(contract.status, 1);
    expect(contract.recovery, 3);
    expect(contract.deliveredCount, 1);
    expect(contract.planCount, 2);
    expect(contract.orderId, 'order-1');
  });

  testWidgets('shows contract promise and authoritative delivery progress', (
    tester,
  ) async {
    final contract = OutcomeContract(
      id: 'contract-1',
      mission: 'Build a complete work edit',
      deadline: DateTime.utc(2026, 9, 25),
      status: 1,
      recovery: 3,
      assurancePrice: 120,
      currency: 'NPR',
      orderId: 'order-1',
      deliveredCount: 1,
      planCount: 2,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          outcomeContractsProvider.overrideWith((ref) async => [contract]),
        ],
        child: const MaterialApp(home: OutcomeContractsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The result is the product.'), findsOneWidget);
    expect(find.text('Build a complete work edit'), findsOneWidget);
    expect(find.text('1 of 2 planned products delivered'), findsOneWidget);
    expect(find.text('StyleMint credit'), findsOneWidget);
    expect(find.text('NPR 120'), findsOneWidget);
  });

  testWidgets('opens guided creation and rejects an empty promise', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          outcomeContractsProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: OutcomeContractsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OutcomeContractsScreen.createKey));
    await tester.pumpAndSettle();

    expect(find.text('Create an outcome promise'), findsOneWidget);
    expect(find.text('Automatic StyleMint credit'), findsOneWidget);
    final confirm = find.byKey(const ValueKey('outcome-contract-confirm'));
    await tester.ensureVisible(confirm);
    await tester.pumpAndSettle();
    await tester.tap(confirm);
    await tester.pump();
    expect(
      find.text('Add a mission, positive budget and success criterion.'),
      findsOneWidget,
    );
  });
}
