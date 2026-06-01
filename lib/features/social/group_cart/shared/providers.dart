import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/data/datasources/group_cart_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/data/repositories/group_cart_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/domain/repositories/group_cart_repository.dart';
import 'package:stylemint_mobile_frontend/features/social/group_cart/presentation/notifiers/group_cart_notifier.dart';

final groupCartRemoteDataSourceProvider = Provider<GroupCartRemoteDataSource>(
  (ref) => GroupCartRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final groupCartRepositoryProvider = Provider<GroupCartRepository>(
  (ref) => GroupCartRepositoryImpl(
    remoteDataSource: ref.watch(groupCartRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final groupCartsNotifierProvider =
    StateNotifierProvider<GroupCartNotifier, GroupCartsState>(
  (ref) => GroupCartNotifier(ref.watch(groupCartRepositoryProvider)),
);

final groupCartDetailNotifierProvider =
    StateNotifierProvider.family<GroupCartDetailNotifier, GroupCartDetailState, String>(
  (ref, cartId) => GroupCartDetailNotifier(
    ref.watch(groupCartRepositoryProvider),
    cartId,
  ),
);
