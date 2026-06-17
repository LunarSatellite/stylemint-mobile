/// A single "recent activity" row, derived from a notification inbox dispatch.
/// Pure Dart — no JSON.
class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.occurredAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final DateTime? occurredAt;
  final bool isRead;
}
