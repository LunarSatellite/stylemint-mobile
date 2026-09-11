import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/data/datasources/group_buy_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/data/repositories/group_buy_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/domain/entities/group_buy.dart';
import 'package:stylemint_mobile_frontend/features/customer/group_buy/domain/repositories/group_buy_repository.dart';

final groupBuyRemoteDataSourceProvider = Provider<GroupBuyRemoteDataSource>(
  (ref) => GroupBuyRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final groupBuyRepositoryProvider = Provider<GroupBuyRepository>(
  (ref) => GroupBuyRepositoryImpl(
    remoteDataSource: ref.watch(groupBuyRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

/// Active group buys for one product, for the PDP banner. Best-effort —
/// a failure here should never block the product screen.
final activeGroupBuysForProductProvider = FutureProvider.autoDispose
    .family<List<GroupBuy>, String>((ref, productId) async {
      final either = await ref
          .watch(groupBuyRepositoryProvider)
          .getActiveForProduct(productId);
      return either.fold((_) => const <GroupBuy>[], (list) => list);
    });
