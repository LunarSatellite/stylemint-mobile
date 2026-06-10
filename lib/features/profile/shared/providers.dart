import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/core/storage/token_storage.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:stylemint_mobile_frontend/features/profile/presentation/notifiers/profile_notifier.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  ),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(
    remoteDataSource: ref.watch(profileRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>(
      (ref) => ProfileNotifier(ref.watch(profileRepositoryProvider)),
    );

final editProfileNotifierProvider =
    StateNotifierProvider<EditProfileNotifier, EditProfileState>(
      (ref) => EditProfileNotifier(ref.watch(profileRepositoryProvider)),
    );

final followingNotifierProvider =
    StateNotifierProvider<FollowingNotifier, FollowingState>(
      (ref) => FollowingNotifier(ref.watch(profileRepositoryProvider)),
    );
