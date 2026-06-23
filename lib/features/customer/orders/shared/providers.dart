import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/cancel_order_controller.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/mock_orders_repository.dart';

// ── Repository provider ───────────────────────────────────────────────────────
// Using MockOrdersRepository for development/demo (static data, no API needed).
// To restore the real network implementation, replace the body below with:
//
//   OrdersRepositoryImpl(
//     remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
//     networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
//   )
//
final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => MockOrdersRepository(),
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
