import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/datasources/partnerships_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/data/repositories/partnerships_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/entities/partnership.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/domain/repositories/partnerships_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/partnerships/presentation/notifiers/partnerships_notifier.dart';

final partnershipsRemoteDataSourceProvider =
    Provider<PartnershipsRemoteDataSource>(
      (ref) => PartnershipsRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final partnershipsRepositoryProvider = Provider<PartnershipsRepository>(
  (ref) => PartnershipsRepositoryImpl(
    remoteDataSource: ref.watch(partnershipsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final partnershipsNotifierProvider =
    StateNotifierProvider<PartnershipsNotifier, PartnershipsState>(
      (ref) => PartnershipsNotifier(ref.watch(partnershipsRepositoryProvider)),
    );

/// Derived view: active partnerships only, empty while loading or on failure.
final activePartnershipsProvider = Provider<List<ActivePartnership>>((ref) {
  return ref.watch(partnershipsNotifierProvider).maybeWhen(
        loadSuccess: (_, active, _) => active,
        orElse: () => const [],
      );
});

/// Derived view: ended partnerships only, empty while loading or on failure.
final endedPartnershipsProvider = Provider<List<EndedPartnership>>((ref) {
  return ref.watch(partnershipsNotifierProvider).maybeWhen(
        loadSuccess: (_, _, ended) => ended,
        orElse: () => const [],
      );
});

/// Derived view: count of pending invites, 0 while loading or on failure.
final pendingInvitesCountProvider = Provider<int>((ref) {
  return ref.watch(partnershipsNotifierProvider).maybeWhen(
        loadSuccess: (invites, _, _) => invites
            .where((i) => i.status == PartnershipStatus.pending)
            .length,
        orElse: () => 0,
      );
});
