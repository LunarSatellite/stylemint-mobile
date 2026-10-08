import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/domain/entities/vendor_order.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';

/// The backend states that make up the vendor's "to ship" bucket.
///
/// This is the server-side spelling of
/// [VendorOrderStatusBucketing.isPreShipment]: every state that maps to
/// pending / confirmed / processing / accepted / packed. The two must agree,
/// or the nav badge and the "To Ship" tab header show different numbers for
/// the same thing — which reads as a bug rather than as a distinction.
///
/// Derived from [SubOrderStateCode] rather than written as literals so that
/// a renumbered state breaks the build instead of quietly miscounting.
const toShipStates = <int>[
  SubOrderStateCode.pending, // 1  -> pending
  SubOrderStateCode.paid, // 2  -> confirmed
  SubOrderStateCode.awaitingFulfillment, // 3  -> processing
  SubOrderStateCode.readyToShip, // 4  -> processing
  SubOrderStateCode.awaitingTracking, // 5  -> processing
  SubOrderStateCode.accepted, // 12 -> accepted
  SubOrderStateCode.packed, // 13 -> packed
];

/// How many parcels are waiting to go out, for the Orders badge on the
/// vendor bottom nav.
///
/// One request, not seven: the `states` query param counts the whole bucket
/// server-side and only `totalCount` is read (`pageSize: 1`).
///
/// `autoDispose` on purpose — the provider is rebuilt as the vendor moves
/// between Home / Orders / Products / Profile, so the badge refreshes on
/// navigation without anything having to remember to refresh it. Code that
/// changes an order's state while staying on the same screen should still
/// `ref.invalidate(vendorToShipCountProvider)`, since no navigation happens
/// to trigger that.
///
/// A failure resolves to null rather than throwing: a badge is an aid, and
/// a count that could not be fetched should show nothing, not an error.
final vendorToShipCountProvider = FutureProvider.autoDispose<int?>((ref) async {
  final result = await ref
      .watch(vendorOrdersRepositoryProvider)
      .getSubOrderCountForStates(toShipStates);
  return result.fold((_) => null, (count) => count);
});
