import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/data/datasources/drop_party_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/data/repositories/drop_party_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/domain/repositories/drop_party_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/drop_party/presentation/notifiers/drop_party_notifier.dart';

final dropPartyRemoteDataSourceProvider = Provider<DropPartyRemoteDataSource>(
  (ref) => DropPartyRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final dropPartyRepositoryProvider = Provider<DropPartyRepository>(
  (ref) => DropPartyRepositoryImpl(
    remoteDataSource: ref.watch(dropPartyRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final dropPartiesNotifierProvider =
    StateNotifierProvider<DropPartyNotifier, DropPartiesState>(
  (ref) => DropPartyNotifier(ref.watch(dropPartyRepositoryProvider)),
);

final dropPartyDetailNotifierProvider =
    StateNotifierProvider.family<DropPartyDetailNotifier, DropPartyDetailState, String>(
  (ref, partyId) => DropPartyDetailNotifier(
    ref.watch(dropPartyRepositoryProvider),
    partyId,
  ),
);
