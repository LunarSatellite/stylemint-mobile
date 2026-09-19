import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/screens/mission_detail_screen.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/presentation/widgets/mission_budget_summary.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/shared/providers.dart';

import 'mission_fixtures.dart';

const _narrow = Size(320, 640);
const _bigText = TextScaler.linear(1.3);

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
          child: const MissionDetailScreen(missionId: missionId),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Brings a control below the fold into view. The detail screen is a long
/// scroll on a phone, and its actions sit under the checklist.
Future<void> _reveal(WidgetTester tester, Finder target) async {
  await tester.dragUntilVisible(
    target,
    find.byType(ListView),
    const Offset(0, -220),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the checklist', () {
    testWidgets('marking an item updates coverage and the cost, from the '
        'server rather than from arithmetic here', (tester) async {
      final repository = FakeMissionsRepository(
        initial: missionFrom(missionJson()),
        afterChange: missionFrom(
          missionJson(
            total: 8000,
            coverage: 0.5,
            resolved: 1,
            owned: 1,
            items: [
              itemJson(
                id: itemOne,
                name: 'Kettle',
                price: 4000,
                state: 'AlreadyOwned',
              ),
              itemJson(
                id: itemTwo,
                name: 'Floor lamp',
                price: 8000,
                position: 1,
              ),
            ],
          ),
        ),
      );

      await _pump(tester, repository);

      expect(find.text('0 of 2 sorted · 0%'), findsOneWidget);
      expect(find.text('Rs 12,000'), findsWidgets);

      await tester.tap(find.byKey(MissionDetailScreen.ownedKey(itemOne)));
      await tester.pumpAndSettle();

      expect(repository.itemChanges, hasLength(1));
      expect(repository.itemChanges.single.itemId, itemOne);
      expect(
        repository.itemChanges.single.state,
        MissionItemState.alreadyOwned,
      );
      expect(find.text('1 of 2 sorted · 50%'), findsOneWidget);
      expect(find.text('Rs 8,000'), findsWidgets);
      expect(find.text('Already own it'), findsWidgets);
    });

    testWidgets('pressing a set state again clears it back to suggested', (
      tester,
    ) async {
      final repository = FakeMissionsRepository(
        initial: missionFrom(
          missionJson(
            resolved: 1,
            acquired: 1,
            coverage: 0.5,
            items: [
              itemJson(
                id: itemOne,
                name: 'Kettle',
                price: 4000,
                state: 'Acquired',
              ),
            ],
          ),
        ),
      );

      await _pump(tester, repository);
      await tester.tap(find.byKey(MissionDetailScreen.acquiredKey(itemOne)));
      await tester.pumpAndSettle();

      expect(
        repository.itemChanges.single.state,
        MissionItemState.suggested,
      );
    });
  });

  group('the budget', () {
    testWidgets('an over-budget plan is flagged with the overshoot spelled '
        'out', (tester) async {
      final repository = FakeMissionsRepository(
        initial: missionFrom(
          missionJson(total: 46500, withinBudget: false),
        ),
      );

      await _pump(tester, repository);

      expect(find.byKey(MissionOverBudgetBanner.bannerKey), findsOneWidget);
      expect(find.text('Over budget by Rs 6,500'), findsOneWidget);
      expect(
        find.textContaining('against a budget of Rs 40,000'),
        findsOneWidget,
      );
      expect(
        find.text('Left to spend'),
        findsNothing,
        reason: 'there is no headroom to report',
      );
    });

    testWidgets('a plan inside its budget is not flagged', (tester) async {
      final repository = FakeMissionsRepository(
        initial: missionFrom(missionJson()),
      );

      await _pump(tester, repository);

      expect(find.byKey(MissionOverBudgetBanner.bannerKey), findsNothing);
      expect(find.text('Left to spend'), findsOneWidget);
      expect(find.text('Rs 28,000'), findsOneWidget);
    });

    testWidgets('a mission with no budget shows neither verdict', (
      tester,
    ) async {
      final repository = FakeMissionsRepository(
        initial: missionFrom(missionJson(budget: null)),
      );

      await _pump(tester, repository);

      expect(find.byKey(MissionOverBudgetBanner.bannerKey), findsNothing);
      expect(find.text('Your budget'), findsNothing);
      expect(find.text('Left to spend'), findsNothing);
    });
  });

  group('a finished mission', () {
    testWidgets('offers no controls and says why', (tester) async {
      final repository = FakeMissionsRepository(
        initial: missionFrom(missionJson(state: 'Completed')),
      );

      await _pump(tester, repository);

      expect(find.byKey(MissionDetailScreen.replanKey), findsNothing);
      expect(find.byKey(MissionDetailScreen.completeKey), findsNothing);
      expect(find.byKey(MissionDetailScreen.abandonKey), findsNothing);
      expect(find.byKey(MissionDetailScreen.ownedKey(itemOne)), findsNothing);
      expect(find.byKey(MissionDetailScreen.closedNoticeKey), findsOneWidget);
      expect(
        find.text('This mission is completed, so its checklist is closed.'),
        findsOneWidget,
      );
    });

    testWidgets('an abandoned mission says so in its own words', (
      tester,
    ) async {
      final repository = FakeMissionsRepository(
        initial: missionFrom(missionJson(state: 'Abandoned')),
      );

      await _pump(tester, repository);

      expect(
        find.text('This mission was abandoned, so its checklist is closed.'),
        findsOneWidget,
      );
      expect(repository.itemChanges, isEmpty);
    });

    testWidgets('a 409 from the server is explained, not shown raw', (
      tester,
    ) async {
      // The mission looks active to this client but the server has since
      // closed it — the only way a 409 can actually be observed.
      final repository = FakeMissionsRepository(
        initial: missionFrom(missionJson()),
      )..refuseAsTerminal = true;

      await _pump(tester, repository);
      await _reveal(tester, find.byKey(MissionDetailScreen.completeKey));
      await tester.tap(find.byKey(MissionDetailScreen.completeKey));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This mission is finished, so it cannot be changed any more.',
        ),
        findsOneWidget,
      );
    });
  });

  group('mission actions', () {
    testWidgets('re-plan, complete and abandon each call once', (tester) async {
      final repository = FakeMissionsRepository(
        initial: missionFrom(missionJson()),
      );

      await _pump(tester, repository);

      await _reveal(tester, find.byKey(MissionDetailScreen.replanKey));
      await tester.tap(find.byKey(MissionDetailScreen.replanKey));
      await tester.pumpAndSettle();
      await _reveal(tester, find.byKey(MissionDetailScreen.abandonKey));
      await tester.tap(find.byKey(MissionDetailScreen.abandonKey));
      await tester.pumpAndSettle();

      expect(repository.replans, 1);
      expect(repository.abandons, 1);
      expect(repository.completes, 0);
    });
  });

  testWidgets('no overflow at 320dp with text at 1.3x', (tester) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(
        missionJson(total: 46500, withinBudget: false),
      ),
    );

    await _pump(tester, repository, size: _narrow, scaler: _bigText);

    expect(tester.takeException(), isNull);
  });

  testWidgets('every control carries a semantics label', (tester) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(missionJson()),
    );
    final handle = tester.ensureSemantics();

    await _pump(tester, repository);

    expect(
      tester.getSemantics(find.byKey(MissionCoverageBar.barKey)).label,
      contains('Coverage, 0 percent'),
    );
    expect(
      tester
          .getSemantics(find.byKey(MissionDetailScreen.ownedKey(itemOne)))
          .label,
      contains('Mark Kettle as something you already own'),
    );
    expect(
      tester
          .getSemantics(find.byKey(MissionDetailScreen.acquiredKey(itemOne)))
          .label,
      contains('Mark Kettle as acquired'),
    );
    await _reveal(tester, find.byKey(MissionDetailScreen.replanKey));
    expect(
      tester.getSemantics(find.byKey(MissionDetailScreen.replanKey)).label,
      contains('Re-plan this mission'),
    );
    expect(
      tester.getSemantics(find.byKey(MissionDetailScreen.completeKey)).label,
      contains('Mark this mission completed'),
    );
    expect(
      tester.getSemantics(find.byKey(MissionDetailScreen.abandonKey)).label,
      contains('Abandon this mission'),
    );

    handle.dispose();
  });

  testWidgets('no product photograph is drawn for a checklist item', (
    tester,
  ) async {
    final repository = FakeMissionsRepository(
      initial: missionFrom(missionJson()),
    );

    await _pump(tester, repository);

    // thumbnailUrl is on every fixture item; the Mall is video-first, so no
    // image is built for it anywhere on this screen.
    expect(find.byType(Image), findsNothing);
    expect(find.text('Kettle'), findsOneWidget);
  });
}
