import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/data/datasources/social_connect_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/data/repositories/social_connect_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/domain/repositories/social_connect_repository.dart';
import 'package:stylemint_mobile_frontend/features/creator/social_connect/presentation/notifiers/social_connect_notifier.dart';

final socialConnectRemoteDataSourceProvider =
    Provider<SocialConnectRemoteDataSource>(
      (ref) => SocialConnectRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      ),
    );

final socialConnectRepositoryProvider = Provider<SocialConnectRepository>(
  (ref) => SocialConnectRepositoryImpl(
    remoteDataSource: ref.watch(socialConnectRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final socialConnectNotifierProvider =
    StateNotifierProvider<SocialConnectNotifier, SocialConnectState>(
      (ref) => SocialConnectNotifier(
        ref.watch(socialConnectRepositoryProvider),
      ),
    );
