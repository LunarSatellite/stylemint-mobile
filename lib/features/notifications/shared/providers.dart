import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/entities/activity_item.dart';
import 'package:stylemint_mobile_frontend/features/notifications/domain/repositories/notifications_repository.dart';

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>(
  (ref) => NotificationsRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
  ),
);

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepositoryImpl(
    remoteDataSource: ref.watch(notificationsRemoteDataSourceProvider),
  ),
);

/// Recent activity for the dashboard. Best-effort: folds any failure to an
/// empty list so the dashboard shows a clean "no activity" state rather than an
/// error. (The backend inbox currently returns empty for real users due to a
/// known auth-helper bug — this provider degrades gracefully until that lands.)
final recentActivityProvider =
    FutureProvider.autoDispose<List<ActivityItem>>((ref) async {
  final either =
      await ref.watch(notificationsRepositoryProvider).getRecentActivity();
  return either.fold((_) => const <ActivityItem>[], (items) => items);
});
