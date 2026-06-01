import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/datasources/reels_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/data/repositories/reels_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/domain/repositories/reels_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/reels/presentation/notifiers/reels_feed_notifier.dart';

final reelsRemoteDataSourceProvider = Provider<ReelsRemoteDataSource>(
  (ref) => ReelsRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final reelsRepositoryProvider = Provider<ReelsRepository>(
  (ref) => ReelsRepositoryImpl(
    remoteDataSource: ref.watch(reelsRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final reelsFeedNotifierProvider =
    StateNotifierProvider<ReelsFeedNotifier, ReelsFeedState>(
      (ref) => ReelsFeedNotifier(ref.watch(reelsRepositoryProvider)),
    );
