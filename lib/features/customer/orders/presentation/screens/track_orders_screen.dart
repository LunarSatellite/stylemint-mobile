import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/widgets/order_track_tile.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

class TrackOrdersScreen extends ConsumerWidget {
  const TrackOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final isAuthed = session.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );

    if (!isAuthed) {
      return _UnauthenticatedView();
    }

    final state = ref.watch(trackOrdersNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s16,
                DesignTokens.s8,
              ),
              child: Text('Track Your Orders',
                  style: DesignTokens.sectionInnerTitle),
            ),
            Expanded(
              child: state.when(
                initial: _loader,
                loadInProgress: _loader,
                loadSuccess: (orders) {
                  if (orders.isEmpty) {
                    return const SmEmptyState(
                      message: "You haven't placed any orders yet.",
                      icon: Icons.inventory_2_outlined,
                    );
                  }
                  return RefreshIndicator(
                    color: DesignTokens.primaryGreen,
                    onRefresh:
                        () =>
                            ref
                                .read(trackOrdersNotifierProvider.notifier)
                                .fetchOrders(),
                    child: ListView.builder(
                      itemCount: orders.length,
                      itemBuilder:
                          (_, i) => OrderTrackTile(
                            order: orders[i],
                            onTap:
                                () => context.push(
                                  '${RouteNames.orders}/${orders[i].id}',
                                ),
                          ),
                    ),
                  );
                },
                loadFailure:
                    (failure) => SmErrorView(
                      message: 'Failed to load your orders.',
                      onRetry:
                          () =>
                              ref
                                  .read(trackOrdersNotifierProvider.notifier)
                                  .fetchOrders(),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loader() => const Center(
    child: CircularProgressIndicator(color: DesignTokens.primaryGreen),
  );
}

class _UnauthenticatedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.s32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: DesignTokens.primaryGreen,
                    size: 36,
                  ),
                ),
                const SizedBox(height: DesignTokens.s24),
                Text(
                  'Track Your Orders',
                  style: DesignTokens.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DesignTokens.s12),
                Text(
                  'Sign in to view your order history and track deliveries.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumRegular.copyWith(
                    color: DesignTokens.textMuted,
                  ),
                ),
                const SizedBox(height: DesignTokens.s24),
                SizedBox(
                  width: double.infinity,
                  height: DesignTokens.buttonHeight,
                  child: ElevatedButton(
                    style: DesignTokens.primaryButtonStyle(),
                    onPressed: () => context.push(RouteNames.signInMethod),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
