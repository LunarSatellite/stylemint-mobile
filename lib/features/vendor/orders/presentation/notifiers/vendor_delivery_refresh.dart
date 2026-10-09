import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/device/delivery_push.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';

/// `delivery.delivered`: the recipient confirmed, so the vendor's sub-order
/// is now Delivered. Re-reads whichever vendor order views are alive — the
/// list, and the detail when it is showing that sub-order — so the new status
/// shows without a pull-to-refresh.
///
/// Only views that already exist: reading a provider that does not would
/// create it, and the list notifier fetches on creation, which a rider or a
/// buyer receiving this push must never trigger.
void refreshVendorOrdersOnDelivered(WidgetRef ref, DeliveryPushEvent event) {
  if (event.type != DeliveryPushType.delivered) return;

  if (ref.exists(vendorOrdersNotifierProvider)) {
    final filter = ref
        .read(vendorOrdersNotifierProvider)
        .maybeWhen(
          loadSuccess: (_, _, _, activeFilter) => activeFilter,
          orElse: () => null,
        );
    unawaited(
      ref.read(vendorOrdersNotifierProvider.notifier).loadOrders(status: filter),
    );
  }

  final subOrderId = event.subOrderId;
  if (subOrderId != null && ref.exists(vendorOrderDetailNotifierProvider)) {
    final showing = ref
        .read(vendorOrderDetailNotifierProvider)
        .maybeWhen(
          loadSuccess: (order) => order.id,
          actionFailure: (order, _) => order.id,
          orElse: () => null,
        );
    if (showing == subOrderId) {
      unawaited(
        ref.read(vendorOrderDetailNotifierProvider.notifier).loadOrder(subOrderId),
      );
    }
  }
}
