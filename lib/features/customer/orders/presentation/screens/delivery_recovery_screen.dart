import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
/// The three awkward cases:
///  * **Signed out** — this route is not in the router's public list, so the
///    session redirect sends the customer to sign-in first, exactly like any
///    other account surface. There is no return-to mechanism in this router
///    and this is not the place to invent one; after signing in they land on
///    home with the notification still in the tray.
///  * **Unknown tracking number, or someone else's** — the lookup is scoped
///    to the caller's own orders, so both resolve to "not found" and show
///    the same message. Deliberately indistinguishable: a per-case message
///    would tell a stranger their guess named a real parcel.
///  * **Already recovered** — the order still resolves, so the customer
///    lands on their order detail. The risk banner renders nothing when the
///    backend reports the delivery back on track, so the order detail screen
///    shows a short "back on track" note in its place when it was opened
///    from this notification — an answer to the alert, not a blank screen.
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
          error: (_, _) => _notFound(context),
          data: (orderNumber) {
            if (orderNumber == null) return _notFound(context);
            // Replace this screen so Back from the order goes where Back
            // from a notification should go, not into a resolver.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.pushReplacement(
                '/orders/$orderNumber'
                '?focus=${RouteNames.orderDetailFocusRecovery}',
              );
            });
            return const SmPageLoader();
          },
        ),
      ),
    );
  }

  Widget _notFound(BuildContext context) => SmEmptyState(
    icon: Icons.local_shipping_outlined,
    message:
        "We couldn't find delivery $trackingNumber on your account.\n"
        'Open the order from your orders list to see its latest status.',
    actionLabel: 'Track orders',
    onAction: () => context.go(RouteNames.orders),
  );
}
