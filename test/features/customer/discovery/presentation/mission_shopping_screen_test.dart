import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/entities/product_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/domain/repositories/discovery_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/presentation/screens/mission_shopping_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/discovery/shared/providers.dart';

class _Repository extends Mock implements DiscoveryRepository {}

Future<void> _pump(WidgetTester tester, DiscoveryRepository repository) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        discoveryRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(home: MissionShoppingScreen()),
    ),
  );
}

void main() {
  testWidgets('shows a guided customer-first mission composer', (tester) async {
    await _pump(tester, _Repository());

    expect(
      find.text('Don’t search products.\nDescribe the outcome.'),
      findsOneWidget,
    );
    expect(find.text('Wedding guest'), findsOneWidget);
    expect(find.text('Flexible'), findsOneWidget);
    expect(find.text('In stock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('submits mission and presents an explained complete edit', (
    tester,
  ) async {
    final repository = _Repository();
    when(
      () => repository.getMissionShoppingPlan(
        missionText: any(named: 'missionText'),
        budgetAmount: any(named: 'budgetAmount'),
      ),
    ).thenAnswer(
      (_) async => right(
        const MissionShoppingPlan(
          missionSummary: 'A polished dinner edit with relaxed proportions.',
          items: [
            MissionShoppingItem(
              productId: 'p-1',
              name: 'Oxford blue shirt',
              thumbnailUrl: null,
              priceAmount: 3200,
              reason: 'Adds structure while staying comfortable.',
            ),
          ],
          totalEstimatedCost: 3200,
          currency: 'NPR',
          budgetAmount: 5000,
          withinBudget: true,
        ),
      ),
    );
    await _pump(tester, repository);

    await tester.enterText(
      find.byKey(MissionShoppingScreen.fieldKey),
      'Build a relaxed dinner look',
    );
    await tester.ensureVisible(find.text('Rs 5k'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rs 5k'));
    await tester.ensureVisible(find.byKey(MissionShoppingScreen.submitKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MissionShoppingScreen.submitKey));
    await tester.pumpAndSettle();

    expect(find.byKey(MissionShoppingScreen.resultKey), findsOneWidget);
    expect(find.text('Oxford blue shirt'), findsOneWidget);
    expect(
      find.text('Adds structure while staying comfortable.'),
      findsOneWidget,
    );
    expect(find.text('Within your budget'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('has no overflow on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          discoveryRepositoryProvider.overrideWithValue(_Repository()),
        ],
        child: const MaterialApp(home: MissionShoppingScreen()),
      ),
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
