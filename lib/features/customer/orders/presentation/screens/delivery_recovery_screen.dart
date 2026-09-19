import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracking_lookup.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// Where `stylemint://delivery/{trackingNumber}/recovery` — the push
/// notification the backend sends when a delivery starts slipping — lands.
///
/// It is a resolver, not a surface of its own: the recovery offers already
/// live on the order detail screen (the AI Delivery Guardian banner), and
/// that screen re-reads `/risk` on open, which re-mints a fresh 30-minute
/// offer set. So this screen turns the tracking number into the customer's
/// order number and forwards there with
/// `?focus=${RouteNames.orderDetailFocusRecovery}`, which scrolls the
/// banner into view.
///
/// The lookup itself is one call —
/// `GET /v1/orders/by-tracking/{trackingNumber}` — so any tracking number the
/// customer was ever notified about resolves, however long the notification
/// sat unopened.
///
/// The awkward cases:
///  * **Signed out** — this route is not in the router's public list, so the
///    session redirect sends the customer to sign-in first, exactly like any
///    other account surface. There is no return-to mechanism in this router
///    and this is not the place to invent one; after signing in they land on
///    home with the notification still in the tray.
///  * **Unknown tracking number, or someone else's** — the backend answers
///    both with the identical 404, so both show the same message.
///    Deliberately indistinguishable: a per-case message would tell a
///    stranger their guess named a real parcel.
///  * **Already recovered** — the order still resolves, so the customer
///    lands on their order detail. The risk banner renders nothing when the
///    backend reports the delivery back on track, so the order detail screen
///    shows a short "back on track" note in its place when it was opened
///    from this notification — an answer to the alert, not a blank screen.
///  * **Rate limited** — the lookup allows 20/min per caller. A 429 means the
///    answer exists and we asked too often, so it gets its own "try again in
///    a moment" surface with a retry; showing the not-found message would be
///    a lie.
class DeliveryRecoveryScreen extends ConsumerWidget {
  const DeliveryRecoveryScreen({required this.trackingNumber, super.key});

  final String trackingNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(orderNumberForTrackingProvider(trackingNumber));

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Delivery update'),
      ),
      body: SafeArea(
        child: resolved.when(
          loading: () => const SmPageLoader(),
          // An unexpected failure (offline, 5xx) is no more informative to
          // the customer than an unknown parcel, and must stay just as
          // uninformative about whether the parcel exists.
          error: (_, _) => _notFound(context),
          data: (lookup) => switch (lookup) {
            TrackingLookupResolved(:final orderNumber) => _forward(
              context,
              orderNumber,
            ),
            TrackingLookupRateLimited() => _rateLimited(context, ref),
            TrackingLookupNotFound() => _notFound(context),
          },
        ),
      ),
    );
  }

  /// Replaces this screen so Back from the order goes where Back from a
  /// notification should go, not into a resolver. Order detail re-reads
  /// `/risk` on open, which re-mints a fresh 30-minute offer set — which is
  /// why a late-opened notification still lands on live options.
  Widget _forward(BuildContext context, String orderNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      context.pushReplacement(
        '/orders/$orderNumber?focus=${RouteNames.orderDetailFocusRecovery}',
      );
    });
    return const SmPageLoader();
  }

  /// 20 lookups a minute is generous for a human opening notifications, so
  /// this is rare — but it is "ask again shortly", never "no such delivery".
  Widget _rateLimited(BuildContext context, WidgetRef ref) => SmEmptyState(
    icon: Icons.hourglass_empty,
    message:
        "We're checking too many deliveries right now.\n"
        'Give it a moment and try again.',
    actionLabel: 'Try again',
    onAction: () =>
        ref.invalidate(orderNumberForTrackingProvider(trackingNumber)),
  );

  Widget _notFound(BuildContext context) => SmEmptyState(
    icon: Icons.local_shipping_outlined,
    message:
        "We couldn't find delivery $trackingNumber on your account.\n"
        'Open the order from your orders list to see its latest status.',
    actionLabel: 'Track orders',
    onAction: () => context.go(RouteNames.orders),
  );
}
