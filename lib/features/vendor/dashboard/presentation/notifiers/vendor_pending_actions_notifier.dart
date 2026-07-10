import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/repositories/inquiries_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';

/// SubOrderState enum values (Orders module) needed for the dashboard's
/// "Pending Actions" tile counts.
const _readyToShipState = 4;
const _awaitingTrackingState = 5;

/// Live counts for the vendor dashboard's "Pending Actions" tiles. Each
/// field is null until its call resolves, and stays null if that one call
/// fails — the other tiles still render with whatever succeeded.
class VendorPendingActionCounts {
  const VendorPendingActionCounts({
    this.readyToShip,
    this.waitingTracking,
    this.pendingInquiries,
  });

  final int? readyToShip;
  final int? waitingTracking;
  final int? pendingInquiries;
}

class VendorPendingActionsNotifier
    extends StateNotifier<VendorPendingActionCounts> {
  VendorPendingActionsNotifier(this._orders, this._inquiries)
      : super(const VendorPendingActionCounts()) {
    unawaited(load());
  }

  final VendorOrdersRepository _orders;
  final InquiriesRepository _inquiries;

  Future<void> load() async {
    final results = await Future.wait([
      _orders.getSubOrderCount(_readyToShipState),
      _orders.getSubOrderCount(_awaitingTrackingState),
      _inquiries.getVendorInquiryCount(),
    ]);
    state = VendorPendingActionCounts(
      readyToShip: results[0].fold((_) => null, (c) => c),
      waitingTracking: results[1].fold((_) => null, (c) => c),
      pendingInquiries: results[2].fold((_) => null, (c) => c),
    );
  }
}
