import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/notifiers/vendor_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/presentation/widgets/vendor_order_tile.dart';
import 'package:stylemint_mobile_frontend/features/vendor/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class VendorOrdersScreen extends ConsumerWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorOrdersNotifierProvider);

    final activeFilter = state.maybeWhen(
      loadSuccess: (orders, nextCursor, hasMore, filter) => filter,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        title: Text('Orders',
            style: DesignTokens.mediumSemibold.copyWith(
                color: DesignTokens.textWhite)),
      ),
      body: Column(
        children: [
          _FilterTabs(
            selected: activeFilter,
            onSelected: (filter) {
              ref
                  .read(vendorOrdersNotifierProvider.notifier)
                  .loadOrders(status: filter);
            },
          ),
          Expanded(
            child: state.when(
              initial: _loader,
              loadInProgress: _loader,
              loadSuccess: (orders, nextCursor, hasMore, activeFilter) {
                if (orders.isEmpty) {
                  return const SmEmptyState(
                    message: 'No orders yet.',
                    icon: Icons.receipt_long_outlined,
                  );
                }
                return RefreshIndicator(
                  color: DesignTokens.primaryGreen,
                  onRefresh: () =>
                      ref.read(vendorOrdersNotifierProvider.notifier).loadOrders(),
                  child: ListView.builder(
                    itemCount: orders.length + (hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= orders.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(vendorOrdersNotifierProvider.notifier)
                              .loadMoreOrders();
                        });
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: DesignTokens.primaryGreen),
                          ),
                        );
                      }
                      return VendorOrderTile(
                        order: orders[i],
                        onTap: () => context.push(
                          '${RouteNames.vendorOrders}/${orders[i].id}',
                        ),
                      );
                    },
                  ),
                );
              },
              loadFailure: (failure) => SmErrorView(
                message: 'Failed to load orders.',
                onRetry: () =>
                    ref.read(vendorOrdersNotifierProvider.notifier).loadOrders(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loader() => const Center(
        child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
      );
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  static const _filters = [
    (null, 'All'),
    ('pending', 'Pending'),
    ('processing', 'Processing'),
    ('shipped', 'Shipped'),
    ('delivered', 'Delivered'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.s16,
        vertical: DesignTokens.s12,
      ),
      child: Row(
        children: _filters.map((f) {
          final isSelected = selected == f.$1 ||
              (f.$1 == null && selected == null);
          return Padding(
            padding: const EdgeInsets.only(right: DesignTokens.s8),
            child: GestureDetector(
              onTap: () => onSelected(f.$2 == 'All' ? null : f.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.s16,
                  vertical: DesignTokens.s8,
                ),
                decoration: isSelected
                    ? DesignTokens.chipDecorationSelected()
                    : DesignTokens.chipDecorationDefault(),
                child: Text(
                  f.$2,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: isSelected
                        ? DesignTokens.primaryGreen
                        : DesignTokens.chipsDefaultText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
