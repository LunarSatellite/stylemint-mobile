import 'package:flutter_test/flutter_test.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/data/models/shopping_mission_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';

import 'mission_fixtures.dart';

void main() {
  group('wire mapping', () {
    test('mission and item states arrive as strings and stay meaningful', () {
      final mission = shoppingMissionFromJson(
        missionJson(
          state: 'Completed',
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
              state: 'Acquired',
              position: 1,
            ),
          ],
        ),
      );

      expect(mission.state, MissionState.completed);
      expect(mission.state.isTerminal, isTrue);
      expect(mission.items.first.state, MissionItemState.alreadyOwned);
      expect(mission.items.last.state, MissionItemState.acquired);
      expect(mission.items.every((i) => i.state.isResolved), isTrue);
    });

    test('items come back in plan order whatever order the API sent', () {
      final mission = shoppingMissionFromJson(
        missionJson(
          items: [
            itemJson(
              id: itemTwo,
              name: 'Floor lamp',
              price: 8000,
              position: 1,
            ),
            itemJson(id: itemOne, name: 'Kettle', price: 4000),
          ],
        ),
      );

      expect(mission.items.map((i) => i.name), ['Kettle', 'Floor lamp']);
    });

    test('an unknown state is read as planned rather than crashing', () {
      final mission = shoppingMissionFromJson(missionJson(state: 'Sideways'));
      expect(mission.state, MissionState.planned);
      expect(mission.state.isTerminal, isFalse);
    });
  });

  group('what the screen must not have to work out', () {
    test('coverage is a whole percent, not a decimal to interpret', () {
      final mission = shoppingMissionFromJson(missionJson(coverage: 0.6667));
      expect(mission.coveragePercent, 67);
    });

    test('a coverage ratio outside 0..1 is clamped', () {
      expect(
        shoppingMissionFromJson(missionJson(coverage: 1.4)).coveragePercent,
        100,
      );
      expect(
        shoppingMissionFromJson(missionJson(coverage: -1)).coveragePercent,
        0,
      );
    });

    test('the overshoot is a figure, and only when the server says over', () {
      final over = shoppingMissionFromJson(
        missionJson(total: 46500, withinBudget: false),
      );
      expect(over.overBudgetBy, 6500);

      final within = shoppingMissionFromJson(missionJson());
      expect(within.overBudgetBy, isNull);
    });

    test('a missing budget means no verdict at all', () {
      final mission = shoppingMissionFromJson(
        missionJson(budget: null, total: 99000, withinBudget: false),
      );
      expect(mission.hasBudget, isFalse);
      expect(mission.overBudgetBy, isNull);
    });

    test("withinBudget is the server's, never recomputed here", () {
      // Total is under the budget, but the server said otherwise — perhaps
      // for shipping it knows about. The client does not argue.
      final mission = shoppingMissionFromJson(
        missionJson(total: 100, withinBudget: false),
      );
      expect(mission.withinBudget, isFalse);
      expect(
        mission.overBudgetBy,
        isNull,
        reason: 'there is no positive overshoot to name',
      );
    });

    test("a terminal mission explains itself in the shopper's words", () {
      expect(
        shoppingMissionFromJson(missionJson(state: 'Completed')).terminalReason,
        'This mission is completed, so its checklist is closed.',
      );
      expect(
        shoppingMissionFromJson(missionJson(state: 'Abandoned')).terminalReason,
        'This mission was abandoned, so its checklist is closed.',
      );
      expect(
        shoppingMissionFromJson(missionJson()).terminalReason,
        isNull,
      );
    });
  });
}
