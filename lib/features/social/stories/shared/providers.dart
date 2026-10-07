import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:stylemint_mobile_frontend/features/profile/shared/providers.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/data/datasources/stories_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/data/repositories/stories_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/domain/repositories/stories_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/stories/presentation/notifiers/stories_notifier.dart';

final storiesRemoteDataSourceProvider = Provider<StoriesRemoteDataSource>(
  (ref) => StoriesRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final storiesRepositoryProvider = Provider<StoriesRepository>(
  (ref) => StoriesRepositoryImpl(
    remoteDataSource: ref.watch(storiesRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final storiesNotifierProvider =
    StateNotifierProvider<StoriesNotifier, StoriesState>(
      (ref) => StoriesNotifier(
        ref.watch(storiesRepositoryProvider),
        // Read at call time: fills the author on the viewer's just-posted
        // story. Watching it would rebuild the notifier and blink the tray.
        readViewer: () {
          final me = ref.read(storiesCurrentUserProvider);
          return (displayName: me.displayName, avatarUrl: me.avatarUrl);
        },
      ),
    );

/// The signed-in person as the stories UI needs them: who owns "Your story"
/// and which avatar sits in its bubble.
class StoriesCurrentUser {
  const StoriesCurrentUser({
    required this.accountId,
    this.displayName = '',
    this.avatarUrl = '',
  });

  /// Empty when signed out (or before the session has been read).
  final String accountId;
  final String displayName;
  final String avatarUrl;

  bool owns(String userId) => accountId.isNotEmpty && accountId == userId;
}

/// The signed-in account id, straight from secure storage.
///
/// Read from storage rather than the session controller on purpose: the tray
/// is embedded in the reels feed and Community, and watching the session
/// would build its whole dependency graph (cart, follows, profile fetch)
/// wherever a tray appears. Auto-disposed, so it is read afresh after a
/// sign-out tears the signed-in shell down.
final storiesAccountIdProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(tokenStorageProvider).accountId,
);

/// Account id from storage; avatar and name from the profile header, which the
/// signed-in app keeps loaded. Signed out, the profile is never touched.
/// Overridden in tests.
final storiesCurrentUserProvider = Provider.autoDispose<StoriesCurrentUser>((
  ref,
) {
  final accountId = ref.watch(storiesAccountIdProvider).asData?.value ?? '';
  if (accountId.isEmpty) return const StoriesCurrentUser(accountId: '');
  final profile = ref
      .watch(profileNotifierProvider)
      .maybeWhen(loadSuccess: (summary) => summary, orElse: () => null);
  return StoriesCurrentUser(
    accountId: accountId,
    displayName: profile?.displayName ?? '',
    avatarUrl: profile?.avatarUrl ?? '',
  );
});
