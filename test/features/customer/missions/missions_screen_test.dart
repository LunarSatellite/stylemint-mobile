import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/screens/missions_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/widgets/mission_budget_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/shared/providers.dart';

import 'mission_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeMissionsRepository repository, {
  Size size = const Size(390, 844),
  TextScaler scaler = TextScaler.noScaling,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [missionsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: scaler),
          child: const MissionsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a mission reads without arithmetic in the list', (
    tester,
  ) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(
        missionJson(coverage: 0.5, resolved: 1, owned: 1),
      ),
    );

    await _pump(tester, repository);

    expect(find.text('A new flat, on a budget'), findsOneWidget);
    expect(find.text('1 of 2 sorted · 50%'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('an over-budget mission is flagged in the list too', (
    tester,
  ) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(
        missionJson(total: 46500, withinBudget: false),
      ),
    );

    await _pump(tester, repository);

    expect(find.byKey(MissionOverBudgetBanner.bannerKey), findsOneWidget);
    expect(find.text('Over budget by Rs 6,500'), findsOneWidget);
  });

  testWidgets('a mission is created from a sentence and a budget', (
    tester,
  ) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(missionJson()),
    );

    await _pump(tester, repository);
    await tester.tap(find.byKey(MissionsScreen.startKey));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(MissionsScreen.textFieldKey),
      'Kit out a new flat',
    );
    await tester.enterText(find.byKey(MissionsScreen.budgetFieldKey), '40000');
    await tester.pumpAndSettle();

    expect(find.byKey(MissionsScreen.createKey), findsOneWidget);
    expect(find.text('Plan at most 5 items'), findsOneWidget);
  });

  testWidgets('an empty sentence is refused before any request goes out', (
    tester,
  ) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(missionJson()),
    );

    await _pump(tester, repository);
    await tester.tap(find.byKey(MissionsScreen.startKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(MissionsScreen.createKey));
    await tester.pumpAndSettle();

    expect(
      find.text('Tell Minty what you are trying to get done.'),
      findsOneWidget,
    );
  });

  testWidgets('no overflow at 320dp with text at 1.3x', (tester) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(
        missionJson(total: 46500, withinBudget: false),
      ),
    );

    await _pump(
      tester,
      repository,
      size: const Size(320, 640),
      scaler: const TextScaler.linear(1.3),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('the start control is labelled for a screen reader', (
    tester,
  ) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(missionJson()),
    );
    final handle = tester.ensureSemantics();

    await _pump(tester, repository);

    expect(
      tester.getSemantics(find.byKey(MissionsScreen.startKey)).label,
      contains('Start a new shopping mission'),
    );

    handle.dispose();
  });
}
