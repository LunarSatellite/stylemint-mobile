import 'package:stylemint_mobile_frontend/core/network/api_client.dart';
import 'package:stylemint_mobile_frontend/features/notifications/data/models/notification_dispatch_dto.dart';

class NotificationsRemoteDataSource {
  NotificationsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// `GET /api/v1/notifications/inbox` — NOTE the `api/` prefix (unlike the
  /// other `/v1/...` routes). Cursor by [before] (the `queuedUtc` of the last
  /// item seen); [pageSize] defaults to 20. Returns a plain list (no
  /// `nextCursor`). Auth is added by the interceptor (`requiresToken`).
  Future<List<NotificationDispatchDto>> getInbox({
    DateTime? before,
    int pageSize = 20,
  }) async {
    final response = await apiClient.get(
      '/api/v1/notifications/inbox',
      queryParameters: <String, dynamic>{
        if (before != null) 'before': before.toUtc().toIso8601String(),
        'pageSize': pageSize,
      },
    );
    return (response as List<dynamic>? ?? const <dynamic>[])
        .map((e) => NotificationDispatchDto.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
