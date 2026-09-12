import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/datasources/orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/models/delivery_story_chapter.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/data/repositories/orders_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/repositories/orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/order_detail.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/cancel_order_controller.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';

final ordersRemoteDataSourceProvider = Provider<OrdersRemoteDataSource>(
  (ref) => OrdersRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

/// Delivery Story Mode is the authoritative customer-facing tracking history
/// for first-party P2P shipments. External carriers keep their own timeline.
final deliveryStoryProvider = FutureProvider.autoDispose
    .family<List<DeliveryStoryChapter>, String>((ref, trackingNumber) async {
      final api = ref.watch(apiClientProvider);
      final response = await api.get('/v1/deliveries/$trackingNumber/story');
      return (response as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(DeliveryStoryChapter.fromJson)
          .toList(growable: false)
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
    });

/// "AI Delivery Guardian" — best-effort risk assessment for one delivery.
/// A failure here should never block the order detail screen.
final deliveryRiskProvider = FutureProvider.autoDispose
    .family<DeliveryRiskAssessment?, String>((ref, trackingNumber) async {
      try {
        final api = ref.watch(apiClientProvider);
        final response =
            await api.get('/v1/deliveries/$trackingNumber/risk') as Map<String, dynamic>;
        return DeliveryRiskAssessment(
          atRisk: response['atRisk'] as bool? ?? false,
          customerMessage: response['customerMessage'] as String? ?? '',
          recommendedAction: response['recommendedAction'] as String?,
        );
      } catch (_) {
        return null;
      }
    });

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(
    remoteDataSource: ref.watch(ordersRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final orderInvoiceProvider = FutureProvider.autoDispose
    .family<OrderInvoice, String>((ref, orderNumber) async {
      final result = await ref
          .watch(ordersRepositoryProvider)
          .getOrderInvoice(
            orderNumber,
          );
      return result.match(
        (failure) => throw StateError(failure.toString()),
        (invoice) => invoice,
      );
    });

final trackOrdersNotifierProvider =
    StateNotifierProvider.autoDispose<TrackOrdersNotifier, TrackOrdersState>(
      (ref) => TrackOrdersNotifier(ref.watch(ordersRepositoryProvider)),
    );

/// Bumped by [CustomerShellScreen] every time the Orders tab is switched to.
/// autoDispose alone doesn't refetch here: go_router's StatefulNavigationShell
/// keeps every branch's widget tree mounted (just hidden) when you switch
/// tabs, so the screen never actually stops listening to the provider and it
/// never gets disposed — same reason the Home-tab reels refresh needs its own
/// [homeTabReselectedProvider]-style counter instead of relying on lifecycle.
final ordersTabVisitedProvider = StateProvider<int>((ref) => 0);

// family<orderNumber>.autoDispose — a single shared (non-family) notifier
// let an older in-flight loadOrder(orderA) response overwrite state after a
// newer loadOrder(orderB) had already started (navigating detail -> detail
// for a different order reuses the same instance), showing the wrong
// order's address/items. Keying by order number gives each order its own
// notifier, and autoDispose means revisiting one refetches fresh instead of
// showing whatever was last loaded into the shared singleton.
final orderDetailNotifierProvider = StateNotifierProvider.family
    .autoDispose<OrderDetailNotifier, OrderDetailState, String>(
      (ref, orderNumber) =>
          OrderDetailNotifier(ref.watch(ordersRepositoryProvider)),
    );

final cancelOrderControllerProvider =
    StateNotifierProvider.autoDispose<
      CancelOrderController,
      CancelOrderUiState
    >(
      (ref) => CancelOrderController(ref.watch(ordersRepositoryProvider)),
    );

final reorderSuggestionsNotifierProvider = StateNotifierProvider.autoDispose<
    ReorderSuggestionsNotifier, ReorderSuggestionsState>(
  (ref) => ReorderSuggestionsNotifier(ref.watch(ordersRepositoryProvider)),
);
