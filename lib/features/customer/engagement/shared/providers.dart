import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_queue_store.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/datasources/engagement_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/data/repositories/engagement_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/domain/repositories/engagement_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/engagement/presentation/engagement_tracker.dart';
import 'package:stylemint_mobile_frontend/features/customer/mall_home/shared/providers.dart';
import 'package:uuid/uuid.dart';

/// Where unsent events wait on this device. Tests override it.
final engagementQueueStoreProvider = Provider<EngagementQueueStore>(
  (ref) => const SharedPreferencesEngagementQueueStore(),
);

final engagementRepositoryProvider = Provider<EngagementRepository>(
  (ref) => EngagementRepositoryImpl(
    remoteDataSource: EngagementRemoteDataSource(
      apiClient: ref.watch(apiClientProvider),
    ),
    store: ref.watch(engagementQueueStoreProvider),
  ),
);

/// The signed-in account the engagement queue belongs to; null for a guest.
/// Asks the same sign-in flag the storefront does first, so a guest never
/// reaches the session itself.
final engagementOwnerProvider = Provider<String? Function()>(
  (ref) => () {
    if (!ref.read(mallViewerSignedInProvider)) return null;
    return ref
        .read(sessionControllerProvider)
        .maybeWhen(authenticated: (id) => id, orElse: () => null);
  },
);

const Uuid _uuid = Uuid();

/// Batches reel and product engagement for the personal feed (AI features
/// contract v1.0 §2.1). One per app run, so the queue, its retries and the
/// tag-tap attribution survive moving between screens. Flushed when the app
/// goes to the background, so a session's last events are not left waiting.
final engagementTrackerProvider = Provider<EngagementTracker>((ref) {
  final personalizer = ref.watch(storefrontPersonalizerProvider);
  final tracker = EngagementTracker(
    repository: ref.watch(engagementRepositoryProvider),
    allowed: personalizer.allowed,
    owner: ref.watch(engagementOwnerProvider),
    newId: _uuid.v4,
  );
  AppLifecycleListener? lifecycle;
  try {
    lifecycle = AppLifecycleListener(
      onHide: () => unawaited(tracker.flush()),
      onPause: () => unawaited(tracker.flush()),
    );
  } on Object catch (_) {
    // No binding (a plain unit test): flushes still run on their timer.
  }
  ref.onDispose(() {
    lifecycle?.dispose();
    tracker.dispose();
  });
  return tracker;
});
