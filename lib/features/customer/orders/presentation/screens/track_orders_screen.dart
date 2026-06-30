import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:stylemint_mobile_frontend/core/utils/format_money.dart';
import 'package:stylemint_mobile_frontend/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/domain/entities/tracked_order.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/presentation/notifiers/track_orders_notifier.dart';
import 'package:stylemint_mobile_frontend/features/customer/orders/shared/providers.dart';
import 'package:stylemint_mobile_frontend/routes/route_names.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_empty_state.dart';
import 'package:stylemint_mobile_frontend/shared/presentation/widgets/sm_error_view.dart';
import 'package:stylemint_mobile_frontend/theme/design_tokens.dart';

// ─── FILTER ENUM ──────────────────────────────────────────────────────────────
enum _OrderFilter { all, ongoing, completed, cancelled }

extension _OrderFilterLabel on _OrderFilter {
  String get label {
    switch (this) {
      case _OrderFilter.all:       return 'All';
      case _OrderFilter.ongoing:   return 'Ongoing';
      case _OrderFilter.completed: return 'Completed';
      case _OrderFilter.cancelled: return 'Cancelled';
    }
  }
}


class TrackOrdersScreen extends ConsumerStatefulWidget {
  const TrackOrdersScreen({super.key});

  @override
  ConsumerState<TrackOrdersScreen> createState() => _TrackOrdersScreenState();
}

class _TrackOrdersScreenState extends ConsumerState<TrackOrdersScreen> {
  _OrderFilter _filter = _OrderFilter.all;
  bool _searchOpen = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<TrackedOrder> _applyFilter(List<TrackedOrder> orders) {
    var result = orders;
    if (_filter != _OrderFilter.all) {
      result = result.where((o) {
        switch (_filter) {
          case _OrderFilter.ongoing:
            return o.status == OrderTrackStatus.preparingForShipping ||
                o.status == OrderTrackStatus.inTransit ||
                o.status == OrderTrackStatus.outForDelivery;
          case _OrderFilter.completed:
            return o.status == OrderTrackStatus.delivered;
          case _OrderFilter.cancelled:
            return o.status == OrderTrackStatus.cancelled;
          case _OrderFilter.all:
            return true;
        }
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((o) =>
              o.orderNumber.toLowerCase().contains(q) ||
              o.status.label.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isAuthed = session.maybeWhen(
      authenticated: (_) => true,
      orElse: () => false,
    );

    if (!isAuthed) return const _UnauthenticatedView();

    final orderState = ref.watch(trackOrdersNotifierProvider);

    return Scaffold(
      backgroundColor: DesignTokens.bgAppFoundation,
      appBar: AppBar(
        backgroundColor: DesignTokens.bgAppFoundation,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: _searchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(
                    color: DesignTokens.textWhite, fontSize: 15),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search orders...',
                  hintStyle:
                      TextStyle(color: DesignTokens.textMuted, fontSize: 15),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Your Orders', style: DesignTokens.sectionInnerTitle),
        actions: [
          IconButton(
            icon: Icon(
              _searchOpen ? Icons.close : Icons.search,
              color: DesignTokens.textWhite,
            ),
            onPressed: () {
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchQuery = '';
                  _searchCtrl.clear();
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: orderState.when(
          initial: () => const _Loader(),
          loadInProgress: () => const _Loader(),
          loadFailure: (failure) => SmErrorView(
            message: 'Failed to load orders.',
            onRetry: () =>
                ref.read(trackOrdersNotifierProvider.notifier).fetchOrders(),
          ),
          loadSuccess: (orders) {
            final filtered = _applyFilter(orders);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Filter chips ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(DesignTokens.s16,
                      DesignTokens.s8, DesignTokens.s16, DesignTokens.s16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _OrderFilter.values.map((f) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: f.label,
                            isSelected: _filter == f,
                            onTap: () => setState(() => _filter = f),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // ── Order list ───────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? SmEmptyState(
                          message: _searchQuery.isNotEmpty
                              ? 'No orders match "$_searchQuery".'
                              : 'No ${_filter == _OrderFilter.all ? '' : '${_filter.label.toLowerCase()} '}orders yet.',
                          icon: Icons.inventory_2,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(DesignTokens.s16,
                              0, DesignTokens.s16, DesignTokens.s16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: DesignTokens.s8),
                          itemBuilder: (_, i) => _OrderCard(
                            order: filtered[i],
                            onTap: () => context.push(
                              '${RouteNames.orders}/${filtered[i].id}',
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: DesignTokens.primaryGreen));
}

// ─── FILTER CHIP ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? DesignTokens.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primaryGreen
                : DesignTokens.borderDefault,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.black : DesignTokens.textLight,
          ),
        ),
      ),
    );
  }
}

// ─── ORDER CARD ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final TrackedOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('HH:mm MMM d, yyyy').format(order.placedAt);
    final total = formatMoney(order.total);
    final meta = '$total  •  $date  •  ${order.itemCount} item${order.itemCount == 1 ? '' : 's'}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: DesignTokens.bgAppBody,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Cube icon on dark rounded-square bg
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF27272A),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.inventory_2,
                color: Color(0xFFF1C40F),
                size: 26,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.mediumSemibold.copyWith(
                      color: DesignTokens.textWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.smallRegular.copyWith(
                      color: DesignTokens.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _StatusBadge(status: order.status),
                ],
              ),
            ),

            const Icon(Icons.chevron_right_rounded,
                color: DesignTokens.iconLight, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── STATUS BADGE ─────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderTrackStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (status) {
      OrderTrackStatus.cancelled => (
          const Color(0xFF3D1111),
          const Color(0xFFFF6B6B),
        ),
      OrderTrackStatus.delivered => (
          const Color(0xFF0A2E16),
          const Color(0xFF4CAF50),
        ),
      _ => (
          const Color(0xFF0A1F38),
          const Color(0xFF4FC3F7),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontFamily: DesignTokens.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─── UNAUTHENTICATED VIEW ─────────────────────────────────────────────────────
class _UnauthenticatedView extends StatelessWidget {
  const _UnauthenticatedView();

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
                  child: const Icon(Icons.inventory_2,
                      color: DesignTokens.primaryGreen, size: 36),
                ),
                const SizedBox(height: DesignTokens.s24),
                Text('Track Your Orders',
                    style: DesignTokens.titleLarge,
                    textAlign: TextAlign.center),
                const SizedBox(height: DesignTokens.s12),
                Text(
                  'Sign in to view your order history and track deliveries.',
                  textAlign: TextAlign.center,
                  style: DesignTokens.mediumRegular
                      .copyWith(color: DesignTokens.textMuted),
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
