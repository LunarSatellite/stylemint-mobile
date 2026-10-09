import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/core/live/live_refresh_signal.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';

/// A change to a vendor's orders (an `order.*` or `delivery.*` push, a live
/// `order.updated` / `delivery.updated` event, or the live channel
/// reconnecting): silently re-reads whichever vendor order views are alive —
/// the list, and the detail when it shows that sub-order (or the signal
/// names none) — so "Shipped" becomes "Delivered" without a
/// pull-to-refresh.
///
/// Only views that already exist: reading a provider that does not would
/// create it, and the list notifier fetches on creation, which a rider or a
/// buyer receiving this signal must never trigger.
void refreshVendorOrdersLive(WidgetRef ref, LiveSignal signal) {
  if (!signal.concerns(const {LiveScope.vendorOrders})) return;

  if (ref.exists(vendorOrdersNotifierProvider)) {
    unawaited(
      ref.read(vendorOrdersNotifierProvider.notifier).refreshSilently(),
    );
  }

  if (ref.exists(vendorOrderDetailNotifierProvider)) {
    final showing = ref
        .read(vendorOrderDetailNotifierProvider)
        .maybeWhen(loadSuccess: (order) => order.id, orElse: () => null);
    final subOrderId = signal.subOrderId;
    if (showing != null && (subOrderId == null || subOrderId == showing)) {
      unawaited(
        ref
            .read(vendorOrderDetailNotifierProvider.notifier)
            .refreshSilently(showing),
      );
    }
  }
}
