/// A single "recent activity" row, derived from a notification inbox dispatch.
/// Pure Dart — no JSON.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.occurredAt,
    required this.isRead,
    this.templateKey,
    this.variablesJson,
  });

  final String id;
  final String title;
  final DateTime? occurredAt;
  final bool isRead;

  /// The inbox row's template key (`order.packed`, `delivery.interest`, …)
  /// and its raw variables — what decides where tapping the row goes. Null
  /// for activity-feed rows, which open nothing.
  final String? templateKey;
  final String? variablesJson;
}
