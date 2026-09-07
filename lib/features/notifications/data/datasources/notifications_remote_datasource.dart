import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/notifications/data/models/notification_dispatch_dto.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /v1/notifications/inbox`. Cursor by [before] (the `queuedUtc` of
  /// the last item seen); [pageSize] defaults to 20. Returns a plain list
  /// (no `nextCursor`). Auth is added by the interceptor (`requiresToken`).
  Future<List<NotificationDispatchDto>> getInbox({
    DateTime? before,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/v1/notifications/inbox',
      queryParameters: <String, dynamic>{
        if (before != null) 'before': before.toUtc().toIso8601String(),
        'pageSize': pageSize,
      },
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => NotificationDispatchDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// `GET /v1/creator/activity` — cursor-paged reverse-chronological activity
  /// feed for the authenticated creator. Requires Creator role.
  Future<List<ActivityItem>> getCreatorActivity({
    int pageSize = 25,
  }) async {
    final response = await apiClient.get(
      '/v1/creator/activity',
      queryParameters: <String, dynamic>{'pageSize': pageSize},
    );
    final json = response as Map<String, dynamic>;
    final items = json['items'] as List<dynamic>? ?? const <dynamic>[];
    return items.map((e) {
      final entry = e as Map<String, dynamic>;
      return ActivityItem(
        id: (entry['id'] ?? '').toString(),
        title: entry['headline'] as String? ?? '',
        occurredAt: _parseDate(entry['occurredUtc']),
        isRead: false,
      );
    }).toList(growable: false);
  }

  static DateTime? _parseDate(dynamic v) =>
      v is String ? DateTime.tryParse(v) : null;
}
