import 'package:stylemint_mobile_frontend/features/customer/missions/domain/entities/shopping_mission.dart';

/// Wire mapping for `/v1/customer/mission-shopping`. Every mutation returns
/// the whole mission, so there is exactly one reader here and the screen
/// never patches a mission locally.

double _num(Object? raw) => switch (raw) {
  final num value => value.toDouble(),
  final String value => double.tryParse(value) ?? 0,
  _ => 0,
};

int _int(Object? raw) => _num(raw).round();

String _str(Object? raw) => raw is String ? raw : '';

DateTime? _utc(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

MissionItem missionItemFromJson(Map<String, dynamic> json) => MissionItem(
  id: _str(json['id']),
  missionId: _str(json['missionId']),
  productId: _str(json['productId']),
  name: _str(json['name']),
  priceAmount: _num(json['priceAmount']),
  reason: _str(json['reason']),
  position: _int(json['position']),
  state: MissionItemState.parse(json['state']),
  thumbnailUrl: json['thumbnailUrl'] as String?,
  resolvedUtc: _utc(json['resolvedUtc']),
);

ShoppingMission shoppingMissionFromJson(Map<String, dynamic> json) {
  final items =
      (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(missionItemFromJson)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));
  return ShoppingMission(
    id: _str(json['id']),
    missionText: _str(json['missionText']),
    missionSummary: _str(json['missionSummary']),
    budgetAmount: json['budgetAmount'] == null
        ? null
        : _num(json['budgetAmount']),
    currency: _str(json['currency']).isEmpty ? 'NPR' : _str(json['currency']),
    maxItems: _int(json['maxItems']),
    state: MissionState.parse(json['state']),
    totalEstimatedCost: _num(json['totalEstimatedCost']),
    // Never inferred from the numbers: this is the server's verdict.
    withinBudget: json['withinBudget'] != false,
    planRevision: _int(json['planRevision']),
    itemCount: _int(json['itemCount']),
    itemsResolvedCount: _int(json['itemsResolvedCount']),
    itemsAlreadyOwnedCount: _int(json['itemsAlreadyOwnedCount']),
    itemsAcquiredCount: _int(json['itemsAcquiredCount']),
    coverageRatio: _num(json['coverageRatio']).clamp(0.0, 1.0),
    items: List.unmodifiable(items),
    startedUtc: _utc(json['startedUtc']),
    completedUtc: _utc(json['completedUtc']),
    abandonedUtc: _utc(json['abandonedUtc']),
  );
}

MissionList missionListFromJson(Map<String, dynamic> json) => MissionList(
  items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map<String, dynamic>>()
      .map(shoppingMissionFromJson)
      .toList(growable: false),
  nextCursor: json['nextCursor'] as String?,
);
