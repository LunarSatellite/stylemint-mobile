import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/data/datasources/live_commerce_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/data/repositories/live_commerce_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/repositories/live_commerce_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/presentation/notifiers/live_sessions_notifier.dart';
import 'package:stylemint_mobile_frontend/features/social/live_commerce/presentation/services/live_commerce_realtime_service.dart';

export 'package:stylemint_mobile_frontend/features/social/live_commerce/domain/entities/live_session.dart';
export 'package:stylemint_mobile_frontend/features/social/live_commerce/presentation/notifiers/live_sessions_notifier.dart';
export 'package:stylemint_mobile_frontend/features/social/live_commerce/presentation/services/live_commerce_realtime_service.dart';

final liveCommerceRemoteDataSourceProvider = Provider<LiveCommerceRemoteDataSource>(
  (ref) => LiveCommerceRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final liveCommerceRepositoryProvider = Provider<LiveCommerceRepository>(
  (ref) => LiveCommerceRepositoryImpl(
    remoteDataSource: ref.watch(liveCommerceRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final liveSessionsNotifierProvider =
    StateNotifierProvider.autoDispose<LiveSessionsNotifier, LiveSessionsState>(
  (ref) => LiveSessionsNotifier(ref.watch(liveCommerceRepositoryProvider)),
);

/// One realtime connection per live-room visit — created when the room
/// screen mounts, disposed when it's popped. Deliberately NOT a
/// session-spanning singleton like messaging's, since a viewer is only
/// ever in at most one room at a time.
final liveCommerceRealtimeServiceProvider =
    Provider.autoDispose<LiveCommerceRealtimeService>((ref) {
  final service = LiveCommerceRealtimeService();
  ref.onDispose(service.dispose);
  return service;
});
