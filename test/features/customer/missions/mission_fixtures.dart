import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/data/models/shopping_mission_dto.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';
import 'package:stylemint_mobile_frontend/features/customer/missions/domain/repositories/missions_repository.dart';

const missionId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const itemOne = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb1';
const itemTwo = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbb2';

Map<String, dynamic> itemJson({
  required String id,
  required String name,
  required double price,
  String state = 'Suggested',
  int position = 0,
  String reason = 'Covers the gap',
}) => {
  'id': id,
  'missionId': missionId,
  'productId': 'p-$id',
  'name': name,
  'thumbnailUrl': 'https://example.test/$id.jpg',
  'priceAmount': price,
  'reason': reason,
  'position': position,
  'state': state,
  'resolvedUtc': state == 'Suggested' ? null : '2026-09-19T09:00:00Z',
};

/// A mission exactly as the API sends one. The server owns every derived
/// figure, so they are passed in rather than computed here.
Map<String, dynamic> missionJson({
  String state = 'Active',
  double? budget = 40000,
  double total = 12000,
  bool withinBudget = true,
  double coverage = 0,
  int resolved = 0,
  int owned = 0,
  int acquired = 0,
  List<Map<String, dynamic>>? items,
}) => {
  'id': missionId,
  'accountId': 'acc-1',
  'missionText': 'Kit out a new flat under 40,000',
  'missionSummary': 'A new flat, on a budget',
  'budgetAmount': budget,
  'currency': 'NPR',
  'maxItems': 5,
  'state': state,
  'totalEstimatedCost': total,
  'withinBudget': withinBudget,
  'planRevision': 1,
  'itemCount': (items ?? _defaultItems).length,
  'itemsResolvedCount': resolved,
  'itemsAlreadyOwnedCount': owned,
  'itemsAcquiredCount': acquired,
  'coverageRatio': coverage,
  'startedUtc': '2026-09-19T08:00:00Z',
  'completedUtc': null,
  'abandonedUtc': null,
  'abandonedFromState': null,
  'createdUtc': '2026-09-19T08:00:00Z',
  'updatedUtc': '2026-09-19T08:00:00Z',
  'items': items ?? _defaultItems,
};

final List<Map<String, dynamic>> _defaultItems = [
  itemJson(id: itemOne, name: 'Kettle', price: 4000),
  itemJson(id: itemTwo, name: 'Floor lamp', price: 8000, position: 1),
];

ShoppingMission missionFrom(Map<String, dynamic> json) =>
    shoppingMissionFromJson(json);

/// Serves a queue of missions, so a test can say what the server returns
/// after each change without pretending to recompute coverage itself.
class FakeMissionsRepository implements MissionsRepository {
  FakeMissionsRepository({required this.initial, this.afterChange});

  ShoppingMission initial;

  /// Returned by every mutation when set.
  ShoppingMission? afterChange;

  /// Set to make the next mutation fail the way a terminal mission does.
  bool refuseAsTerminal = false;

  final List<({String itemId, MissionItemState state})> itemChanges = [];
  int replans = 0;
  int completes = 0;
  int abandons = 0;

  Either<NetworkExceptions, ShoppingMission> _result() {
    if (refuseAsTerminal) {
      return left(
        const NetworkExceptions.validation(
          code: 'state.invalid_transition',
        ),
      );
    }
    return right(afterChange ?? initial);
  }

  @override
  Future<Either<NetworkExceptions, MissionList>> list({
    MissionState? state,
    String? cursor,
  }) async => right(MissionList(items: [initial]));

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> get(
    String missionId,
  ) async => right(initial);

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> start({
    required String missionText,
    required int maxItems,
    double? budgetAmount,
  }) async => right(initial);

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> replan(
    String missionId,
  ) async {
    replans++;
    return _result();
  }

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> setItemState({
    required String missionId,
    required String itemId,
    required MissionItemState state,
  }) async {
    itemChanges.add((itemId: itemId, state: state));
    return _result();
  }

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> complete(
    String missionId,
  ) async {
    completes++;
    return _result();
  }

  @override
  Future<Either<NetworkExceptions, ShoppingMission>> abandon(
    String missionId,
  ) async {
    abandons++;
    return _result();
  }
}
