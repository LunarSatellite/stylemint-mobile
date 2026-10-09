import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_brand_loader.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

/// A backend order id (GUID), as opposed to an order number.
final _orderId = RegExp(
  r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

/// Whether `/orders/{x}` was given an order id rather than an order number.
bool isOrderId(String value) => _orderId.hasMatch(value.trim());

/// How many of the newest orders are opened to look for a sub-order id. A
/// sub-order notification (packed, shipped, delivered) is about an order
/// still in flight, which is one of the newest.
const subOrderLookupDepth = 5;

/// The order number for one of the caller's order ids — or sub-order ids —
/// or null when it is not among their recent orders.
///
/// Notifications name the order by id (`orderId`, or only `subOrderId` on
/// older sub-order notifications), while every order endpoint is addressed
/// by number. The order a notification is about is one of the buyer's most
/// recent, so the first page of their orders is where to look: an order id
/// matches a row of the list; a sub-order id is not on the list, so the
/// newest [subOrderLookupDepth] orders are opened, one at a time, until one
/// holds it.
final orderNumberForOrderIdProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, orderId) async {
      final id = orderId.trim().toLowerCase();
      final repository = ref.watch(ordersRepositoryProvider);
      final result = await repository.getTrackedOrders(limit: 50);
      final orders = result.fold((failure) => throw failure, (o) => o);
      final byId = orders
          .where((o) => o.id.toLowerCase() == id)
          .map((o) => o.orderNumber)
          .firstOrNull;
      if (byId != null) return byId;
      for (final order in orders.take(subOrderLookupDepth)) {
        final detail = await repository.getOrderDetail(order.orderNumber);
        final holds = detail.fold(
          (_) => false,
          (d) => d.items.any((item) => item.subOrderId.toLowerCase() == id),
        );
        if (holds) return order.orderNumber;
      }
      return null;
    });

/// Where `/orders/{orderId}` lands when it carries an id: resolves it to the
/// order number and forwards to the order, replacing itself so Back does
/// not return to a resolver.
class OrderByIdScreen extends ConsumerWidget {
  const OrderByIdScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = ref.watch(orderNumberForOrderIdProvider(orderId));
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: const Text('Order Details'),
      ),
      body: SafeArea(
        child: resolved.when(
          loading: () => const SmPageLoader(),
          error: (_, _) => SmEmptyState(
            icon: Icons.wifi_off_rounded,
            message: "Couldn't open this order just now.",
            actionLabel: 'Try again',
            onAction: () =>
                ref.invalidate(orderNumberForOrderIdProvider(orderId)),
          ),
          data: (orderNumber) {
            if (orderNumber == null) {
              return SmEmptyState(
                icon: Icons.receipt_long_outlined,
                message:
                    "We couldn't find this order on your account.\n"
                    'Open it from your orders list instead.',
                actionLabel: 'Track orders',
                onAction: () => context.go(RouteNames.orders),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.pushReplacement(
                '/orders/${Uri.encodeComponent(orderNumber)}',
              );
            });
            return const SmPageLoader();
          },
        ),
      ),
    );
  }
}
