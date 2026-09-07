import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:stylemint_mobile_frontend/features/messaging/presentation/notifiers/chat_notifier.dart';
import 'package:stylemint_mobile_frontend/features/messaging/presentation/services/messaging_realtime_service.dart';

export 'package:stylemint_mobile_frontend/features/messaging/data/models/direct_message_dto.dart';
export 'package:stylemint_mobile_frontend/features/messaging/data/models/message_thread_dto.dart';
export 'package:stylemint_mobile_frontend/features/messaging/domain/entities/direct_message.dart';
export 'package:stylemint_mobile_frontend/features/messaging/domain/entities/message_thread.dart';
export 'package:stylemint_mobile_frontend/features/messaging/domain/repositories/messaging_repository.dart';
export 'package:stylemint_mobile_frontend/features/messaging/presentation/notifiers/chat_notifier.dart';
export 'package:stylemint_mobile_frontend/features/messaging/presentation/services/messaging_realtime_service.dart';

final messagingRemoteDataSourceProvider = Provider<MessagingRemoteDataSource>(
  (ref) => MessagingRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final messagingRepositoryProvider = Provider<MessagingRepository>(
  (ref) => MessagingRepositoryImpl(
    remoteDataSource: ref.watch(messagingRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Singleton realtime service. Kept alive for the whole app session so
/// the SignalR connection survives screen-to-screen navigation.
final messagingRealtimeServiceProvider =
    Provider<MessagingRealtimeService>((ref) {
  final service = MessagingRealtimeService();
  ref.onDispose(service.dispose);
  return service;
});

/// The current caller''s account id, or empty if not authenticated.
/// Used by the chat notifier to decide which messages are "mine" and
/// by the realtime service to set up the SignalR connection.
final currentAccountIdProvider = Provider<String>(
  (ref) => ref.watch(sessionControllerProvider).maybeWhen(
        authenticated: (id) => id,
        orElse: () => '',
      ),
);

/// Notifier for the open chat of a single thread. Family-keyed by
/// threadId so each open thread maintains its own message list +
/// realtime handler.
final chatNotifierProvider = StateNotifierProvider.family<
    ChatNotifier, ChatState, String>((ref, threadId) {
  return ChatNotifier(
    threadId: threadId,
    repository: ref.watch(messagingRepositoryProvider),
    realtime: ref.watch(messagingRealtimeServiceProvider),
    currentAccountId: ref.watch(currentAccountIdProvider),
  );
});

/// Resolves a profile id to the owning account id (used so screens
/// that only have a profile id can open a chat thread). Cached per
/// id for the app session.
///
/// Tries the documented `GET /v1/accounts/by-profile/{id}` lookup first
/// (resolves CreatorProfile.Id / RoleProfile.Id / VendorProfile.Id).
/// If that 404s the id may actually be an Account.Id - partnerships
/// created by the legacy invite flow stored Account.Id into
/// Partnership.CreatorProfileId (the picker returned Account.Id but the
/// invite endpoint expected CreatorProfile.Id), so when those rows come
/// back through `GET /v1/vendor/partnerships` the only id the messaging
/// layer has is the Account.Id itself. We fall back to
/// `GET /v1/accounts/{id}` so those legacy partnerships can still open
/// the chat without the user recreating them. New invites go through
/// CreatorProfile.Id so the primary lookup wins.
final accountByProfileProvider = FutureProvider.family<String, String>(
  (ref, profileId) async {
    final api = ref.watch(apiClientProvider);
    try {
      final res = await api.get('/v1/accounts/by-profile/$profileId');
      final map = res as Map<String, dynamic>;
      final accountId = (map['accountId'] as String?) ?? '';
      if (accountId.isNotEmpty) return accountId;
    } catch (_) {
      // Fall through to the Account.Id lookup below.
    }
    try {
      final res = await api.get('/v1/accounts/$profileId');
      final map = res as Map<String, dynamic>;
      return (map['id'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  },
);
