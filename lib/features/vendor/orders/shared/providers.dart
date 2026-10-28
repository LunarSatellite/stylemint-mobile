import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:fpdart/fpdart.dart';
import 'package:stylemint_mobile_frontend/core/network/dio_client.dart';
import 'package:stylemint_mobile_frontend/core/network/network_exceptions.dart';
import 'package:stylemint_mobile_frontend/core/network/network_info_impl.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/return_pickup.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/datasources/vendor_orders_remote_datasource.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/data/repositories/vendor_orders_repository_impl.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/rider_profile_for_vendor.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/delivery_partner_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';

final vendorOrdersRemoteDataSourceProvider =
    Provider<VendorOrdersRemoteDataSource>(
      (ref) =>
          VendorOrdersRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
    );

final vendorOrdersRepositoryProvider = Provider<VendorOrdersRepository>(
  (ref) => VendorOrdersRepositoryImpl(
    remoteDataSource: ref.watch(vendorOrdersRemoteDataSourceProvider),
    networkInfo: NetworkInfoConnectivityImpl(connectivity: Connectivity()),
  ),
);

final vendorOrdersNotifierProvider =
    StateNotifierProvider<VendorOrdersNotifier, OrdersState>(
      (ref) => VendorOrdersNotifier(ref.watch(vendorOrdersRepositoryProvider)),
    );

final vendorOrderDetailNotifierProvider =
    StateNotifierProvider<VendorOrderDetailNotifier, OrderDetailState>(
      (ref) =>
          VendorOrderDetailNotifier(ref.watch(vendorOrdersRepositoryProvider)),
    );

/// One sub-order's "find a delivery partner" sheet. autoDispose so closing
/// the sheet disposes the notifier, and its poll timer with it.
final deliveryPartnerNotifierProvider = StateNotifierProvider.autoDispose
    .family<DeliveryPartnerNotifier, DeliveryPartnerState, String>(
      (ref, subOrderId) => DeliveryPartnerNotifier(
        ref.watch(vendorOrdersRepositoryProvider),
        subOrderId,
      ),
    );

/// One rider's details on the partner sheet, as the repository answered —
/// the Either itself rather than a thrown failure, so Riverpod's automatic
/// retry never re-asks for a rider who has left the request. autoDispose:
/// read when the details sheet opens, dropped when it closes.
final vendorRiderProfileProvider = FutureProvider.autoDispose
    .family<
      Either<NetworkExceptions, RiderProfileForVendor?>,
      ({String subOrderId, String courierId})
    >(
      (ref, key) => ref
          .watch(vendorOrdersRepositoryProvider)
          .riderProfile(key.subOrderId, key.courierId),
    );

/// The "find a rider" sheet for collecting one return, keyed by the return
/// request id. Same notifier as a delivery; the return routes.
final returnPickupPartnerNotifierProvider = StateNotifierProvider.autoDispose
    .family<DeliveryPartnerNotifier, DeliveryPartnerState, String>(
      (ref, returnRequestId) => DeliveryPartnerNotifier(
        ref.watch(vendorOrdersRepositoryProvider),
        returnRequestId,
        forReturn: true,
      ),
    );

/// Where one return's rider pickup stands, for its card. Null when there is
/// none or it could not be read — the card then behaves as it always did.
final vendorReturnPickupProvider = FutureProvider.autoDispose
    .family<ReturnPickup?, String>(
      (ref, returnRequestId) async {
        final result = await ref
            .watch(vendorOrdersRepositoryProvider)
            .returnPickup(returnRequestId);
        return result.fold((_) => null, (pickup) => pickup);
      },
      retry: (_, _) => null,
    );

final vendorReturnsProvider =FutureProvider.autoDispose((ref) {
  return ref.watch(vendorOrdersRepositoryProvider).listReturns(pageSize: 100);
});
