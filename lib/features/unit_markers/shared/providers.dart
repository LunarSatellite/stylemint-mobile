import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/data/datasources/unit_markers_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/data/repositories/unit_markers_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/domain/repositories/unit_markers_repository.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/notifiers/unit_marker_bind_notifier.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/notifiers/unit_marker_provision_notifier.dart';
import 'package:stylemint_mobile_frontend/features/unit_markers/presentation/notifiers/unit_passport_notifier.dart';

export 'package:stylemint_mobile_frontend/features/unit_markers/presentation/notifiers/unit_marker_bind_notifier.dart';
export 'package:stylemint_mobile_frontend/features/unit_markers/presentation/notifiers/unit_marker_provision_notifier.dart';
export 'package:stylemint_mobile_frontend/features/unit_markers/presentation/notifiers/unit_passport_notifier.dart';

final unitMarkersRemoteDataSourceProvider =
    Provider<UnitMarkersRemoteDataSource>(
      (ref) =>
          UnitMarkersRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final unitMarkersRepositoryProvider = Provider<UnitMarkersRepository>(
  (ref) => UnitMarkersRepositoryImpl(
    remoteDataSource: ref.watch(unitMarkersRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// **autoDispose, and that is a security property, not a convenience.**
///
/// The revealed state holds the only copy of each tag's cleartext secret that
/// will ever exist. Leaving the provisioning screen disposes this notifier,
/// so the secrets become unreachable the moment the route is popped. Nothing
/// on this path writes one to storage, so there is nothing to clean up
/// afterwards.
final StateNotifierProvider<
  UnitMarkerProvisionNotifier,
  UnitMarkerProvisionState
>
unitMarkerProvisionNotifierProvider =
    StateNotifierProvider.autoDispose<
      UnitMarkerProvisionNotifier,
      UnitMarkerProvisionState
    >(
      (ref) =>
          UnitMarkerProvisionNotifier(ref.watch(unitMarkersRepositoryProvider)),
    );

/// One bind session per order line. autoDispose so reopening the screen
/// starts from idle rather than from the last refusal.
final StateNotifierProviderFamily<
  UnitMarkerBindNotifier,
  UnitMarkerBindState,
  BindTarget
>
unitMarkerBindNotifierProvider = StateNotifierProvider.autoDispose
    .family<UnitMarkerBindNotifier, UnitMarkerBindState, BindTarget>(
      (ref, target) => UnitMarkerBindNotifier(
        ref.watch(unitMarkersRepositoryProvider),
        target,
      ),
    );

/// Keyed by the **opaque** unit marker id. Never by a marker secret.
final StateNotifierProviderFamily<
  UnitPassportNotifier,
  UnitPassportState,
  String
>
unitPassportNotifierProvider = StateNotifierProvider.autoDispose
    .family<UnitPassportNotifier, UnitPassportState, String>(
      (ref, unitMarkerId) => UnitPassportNotifier(
        ref.watch(unitMarkersRepositoryProvider),
        unitMarkerId,
      ),
    );
