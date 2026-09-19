/// Pure Dart — no JSON, no Dio.
///
/// A shopping mission is a sentence ("kit out a new flat under 40k") turned
/// into a checklist the shopper works through. The plan is a suggestion; the
/// shopper marks what they already own and what they have acquired. Nothing
/// here buys, reserves or pays for anything.
library;

/// Mission lifecycle. These arrive as **strings** on the wire, while the
/// assistant's mood/context arrive as numbers. That split is deliberate on
/// the backend for now, so each is parsed as it comes.
enum MissionState {
  planned,
  active,
  completed,
  abandoned;

  static MissionState parse(Object? raw) => switch (raw) {
    'Planned' => MissionState.planned,
    'Active' => MissionState.active,
    'Completed' => MissionState.completed,
    'Abandoned' => MissionState.abandoned,
    _ => MissionState.planned,
  };

  String get wire => switch (this) {
    MissionState.planned => 'Planned',
    MissionState.active => 'Active',
    MissionState.completed => 'Completed',
    MissionState.abandoned => 'Abandoned',
  };

  /// A finished mission accepts no further change. The API answers
  /// `409 state.invalid_transition`; the UI must not offer the controls at
  /// all, and must say why when asked.
  bool get isTerminal =>
      this == MissionState.completed || this == MissionState.abandoned;

  String get label => switch (this) {
    MissionState.planned => 'Planned',
    MissionState.active => 'In progress',
    MissionState.completed => 'Completed',
    MissionState.abandoned => 'Abandoned',
  };
}

/// What the shopper has decided about one planned item.
enum MissionItemState {
  suggested,
  alreadyOwned,
  acquired;

  static MissionItemState parse(Object? raw) => switch (raw) {
    'Suggested' => MissionItemState.suggested,
    'AlreadyOwned' => MissionItemState.alreadyOwned,
    'Acquired' => MissionItemState.acquired,
    _ => MissionItemState.suggested,
  };

  String get wire => switch (this) {
    MissionItemState.suggested => 'Suggested',
    MissionItemState.alreadyOwned => 'AlreadyOwned',
    MissionItemState.acquired => 'Acquired',
  };

  String get label => switch (this) {
    MissionItemState.suggested => 'Still to sort',
    MissionItemState.alreadyOwned => 'Already own it',
    MissionItemState.acquired => 'Got it',
  };

  /// Resolved items are the ones that count towards coverage.
  bool get isResolved => this != MissionItemState.suggested;
}

class MissionItem {
  const MissionItem({
    required this.id,
    required this.missionId,
    required this.productId,
    required this.name,
    required this.priceAmount,
    required this.reason,
    required this.position,
    required this.state,
    this.thumbnailUrl,
    this.resolvedUtc,
  });

  final String id;
  final String missionId;
  final String productId;
  final String name;
  final double priceAmount;
  final String reason;
  final int position;
  final MissionItemState state;

  /// Sent by the API and deliberately **not** drawn: the Mall is video-first
  /// and product photos live on the product details page only. Kept so the
  /// detail page can use it.
  final String? thumbnailUrl;

  final DateTime? resolvedUtc;

  MissionItem copyWith({MissionItemState? state}) => MissionItem(
    id: id,
    missionId: missionId,
    productId: productId,
    name: name,
    priceAmount: priceAmount,
    reason: reason,
    position: position,
    state: state ?? this.state,
    thumbnailUrl: thumbnailUrl,
    resolvedUtc: resolvedUtc,
  );
}

class ShoppingMission {
  const ShoppingMission({
    required this.id,
    required this.missionText,
    required this.missionSummary,
    required this.currency,
    required this.maxItems,
    required this.state,
    required this.totalEstimatedCost,
    required this.withinBudget,
    required this.planRevision,
    required this.itemCount,
    required this.itemsResolvedCount,
    required this.itemsAlreadyOwnedCount,
    required this.itemsAcquiredCount,
    required this.coverageRatio,
    required this.items,
    this.budgetAmount,
    this.startedUtc,
    this.completedUtc,
    this.abandonedUtc,
  });

  final String id;
  final String missionText;
  final String missionSummary;
  final double? budgetAmount;
  final String currency;
  final int maxItems;
  final MissionState state;
  final double totalEstimatedCost;

  /// The server's verdict. Never recomputed on the client — a budget the
  /// shopper is told about must be the one the backend enforced.
  final bool withinBudget;

  final int planRevision;
  final int itemCount;
  final int itemsResolvedCount;
  final int itemsAlreadyOwnedCount;
  final int itemsAcquiredCount;

  /// Resolved ÷ planned, 0–1.
  final double coverageRatio;

  final List<MissionItem> items;
  final DateTime? startedUtc;
  final DateTime? completedUtc;
  final DateTime? abandonedUtc;

  bool get hasBudget => budgetAmount != null;

  /// How far over the budget the plan runs, or null when there is no budget
  /// or the plan fits. Straight subtraction, so the screen never has to do
  /// arithmetic in front of the shopper.
  double? get overBudgetBy {
    final budget = budgetAmount;
    if (budget == null || withinBudget) return null;
    final over = totalEstimatedCost - budget;
    return over > 0 ? over : null;
  }

  /// Coverage as whole percent, for a label that needs no mental maths.
  int get coveragePercent => (coverageRatio * 100).round().clamp(0, 100);

  bool get isTerminal => state.isTerminal;

  /// Why a finished mission cannot change, in the shopper's words.
  String? get terminalReason => switch (state) {
    MissionState.completed =>
      'This mission is completed, so its checklist is closed.',
    MissionState.abandoned =>
      'This mission was abandoned, so its checklist is closed.',
    _ => null,
  };
}

/// A cursor page of missions.
class MissionList {
  const MissionList({required this.items, this.nextCursor});

  final List<ShoppingMission> items;
  final String? nextCursor;
}
