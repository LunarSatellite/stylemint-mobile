import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/datasources/feed_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/data/repositories/feed_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/domain/repositories/feed_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/feed/presentation/notifiers/feed_notifier.dart';

final feedRemoteDataSourceProvider = Provider<FeedRemoteDataSource>(
  (ref) => FeedRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepositoryImpl(
    remoteDataSource: ref.watch(feedRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final feedNotifierProvider = StateNotifierProvider<FeedNotifier, FeedState>(
  (ref) => FeedNotifier(ref.watch(feedRepositoryProvider)),
);
