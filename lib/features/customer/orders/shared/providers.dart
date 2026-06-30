import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/repositories/orders_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/cancel_order_controller.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>(
  (ref) => OrdersRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final trackOrdersNotifierProvider =
    StateNotifierProvider<TrackOrdersNotifier, TrackOrdersState>(
      (ref) => TrackOrdersNotifier(ref.watch(ordersRepositoryProvider)),
    );

final orderDetailNotifierProvider =
    StateNotifierProvider<OrderDetailNotifier, OrderDetailState>(
      (ref) => OrderDetailNotifier(ref.watch(ordersRepositoryProvider)),
    );

final cancelOrderControllerProvider = StateNotifierProvider.autoDispose<
    CancelOrderController, CancelOrderUiState>(
  (ref) => CancelOrderController(ref.watch(ordersRepositoryProvider)),
);
