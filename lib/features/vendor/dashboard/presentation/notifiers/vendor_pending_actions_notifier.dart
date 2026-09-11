import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:stylemint_mobile_frontend/features/vendor/inquiries/domain/repositories/inquiries_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/repositories/vendor_orders_repository.dart';
import 'package:stylemint_mobile_frontend/features/vendor/partnerships/domain/repositories/vendor_partnerships_repository.dart';

/// SubOrderState enum values (Orders module) needed for the dashboard's
/// "Pending Actions" tile counts.
///
/// _readyToShipState intentionally queries AwaitingFulfillment (3), not the
/// enum's own ReadyToShip (4): a vendor takes the "ship" action FROM
/// AwaitingFulfillment (see the isToShip comment in vendor_order.dart — the
/// backend only allows the ReadyToShip transition starting from
/// AwaitingFulfillment). Querying state 4 here missed every order still
/// waiting on that action — confirmed live: a freshly-placed CoD order sat
/// in AwaitingFulfillment and this tile said "No orders ready to ship" while
/// the Your Orders "To Ship" tab correctly showed it.
const _readyToShipState = 3;
const _awaitingTrackingState = 5;

/// Live counts for the vendor dashboard's "Pending Actions" tiles. Each
/// field is null until its call resolves, and stays null if that one call
/// fails — the other tiles still render with whatever succeeded.
class VendorPendingActionCounts {
  const VendorPendingActionCounts({
    this.readyToShip,
    this.waitingTracking,
    this.pendingInquiries,
    this.pendingCreatorRequests,
  });

  final int? readyToShip;
  final int? waitingTracking;
  final int? pendingInquiries;
  final int? pendingCreatorRequests;
}

class VendorPendingActionsNotifier
    extends StateNotifier<VendorPendingActionCounts> {
  VendorPendingActionsNotifier(this._orders, this._inquiries, this._partnerships)
      : super(const VendorPendingActionCounts()) {
    unawaited(load());
  }

  final VendorOrdersRepository _orders;
  final InquiriesRepository _inquiries;
  final VendorPartnershipsRepository _partnerships;

  Future<void> load() async {
    final results = await Future.wait([
      _orders.getSubOrderCount(_readyToShipState),
      _orders.getSubOrderCount(_awaitingTrackingState),
      _inquiries.getVendorInquiryCount(),
      _partnerships.getPendingCreatorRequestCount(),
    ]);
    state = VendorPendingActionCounts(
      readyToShip: results[0].fold((_) => null, (c) => c),
      waitingTracking: results[1].fold((_) => null, (c) => c),
      pendingInquiries: results[2].fold((_) => null, (c) => c),
      pendingCreatorRequests: results[3].fold((_) => null, (c) => c),
    );
  }
}
